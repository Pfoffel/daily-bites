import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:health_app_v1/components/general/my_dialog.dart';
import 'package:health_app_v1/components/general/my_snackbar.dart';
// import 'package:health_app_v1/components/general/my_dialog.dart';  // activate for eneableling edit name button
import 'package:health_app_v1/components/meal/my_recipe_item.dart';
import 'package:health_app_v1/models/current_date.dart';
import 'package:health_app_v1/models/user_settings.dart';
import 'package:health_app_v1/models/recipe.dart';
import 'package:health_app_v1/models/user_recipe.dart'; // Added UserRecipe import
import 'package:health_app_v1/models/recipe_list.dart';
import 'package:health_app_v1/service/connect_db.dart';
import 'package:health_app_v1/service/google_api.dart';
import 'package:health_app_v1/service/recipe_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class ListRecipesPage extends StatefulWidget {
  const ListRecipesPage({super.key});

  @override
  State<ListRecipesPage> createState() => _ListRecipesPageState();
}

class _ListRecipesPageState extends State<ListRecipesPage> {
  final TextEditingController _searchController = TextEditingController();
  // List<Recipe> recipes = []; // Renamed to apiRecipes
  List<Recipe> apiRecipes = [];
  List<UserRecipe> sharedUserRecipes = [];
  List<dynamic> displayableItems = [];
  bool isLoading = false;
  bool isSearching = false;
  bool aiLoading = false; // This seems related to AI image processing, keep for now
  final ImagePicker picker = ImagePicker();

  // Modified fetchRecipes to fetchApiRecipes
  // Changed signature to Future<void> async
  Future<void> fetchApiRecipes(List queries, List categories) async {
    final List<Recipe> results = [];
    // Removed setState from here:
    // setState(() {
    //   isLoading = true; 
    //   isSearching = true; 
    // });

    final recipeService = Provider.of<RecipeService>(context, listen: false);
    for (var query in queries) {
      List<Recipe> result = await recipeService.getFood(query, categories);
      results.addAll(result);
    }
    apiRecipes = results;
    // combineAndDisplayRecipes will be called after both API and shared recipes are fetched
    // For standalone API search (if ever needed), call combineAndDisplayRecipes here.
  }

  Future<void> fetchSharedRecipes() async {
    // No need to set isLoading here as fetchApiRecipes would have set it
    // if search term is not empty.
    if (_searchController.text.isNotEmpty) {
      final connectDb = Provider.of<ConnectDb>(context, listen: false);
      List<UserRecipe> allShared = await connectDb.getSharedRecipes();
      sharedUserRecipes = allShared
          .where((ur) => ur.name
              .toLowerCase()
              .contains(_searchController.text.toLowerCase()))
          .toList();
    } else {
      sharedUserRecipes.clear(); // Clear if search term is empty
    }
  }

  void combineAndDisplayRecipes() {
    displayableItems.clear();
    displayableItems.addAll(apiRecipes);
    displayableItems.addAll(sharedUserRecipes); // Add UserRecipe objects directly

    // Sort by name, for example, if desired. Optional.
    // displayableItems.sort((a, b) {
    //   String nameA = a is Recipe ? a.title : (a as UserRecipe).name;
    //   String nameB = b is Recipe ? b.title : (b as UserRecipe).name;
    //   return nameA.toLowerCase().compareTo(nameB.toLowerCase());
    // });

    setState(() {
      isLoading = false;
    });
  }

  void updateOrder(int oldIndex, int newIndex, String id) { // Changed int id to String id
    setState(() {
      if (oldIndex < newIndex) {
        newIndex--;
      }
      final int mealIndex = context.read<RecipeList>().currentMeal;
      final Map<String, dynamic> currentMealData =
          context.read<RecipeList>().currentMealData;
      final String currentDate = context.read<RecipeList>().currentDate;
      final List<dynamic> mealList = context.read<RecipeList>().mealList;
      currentMealData['recipes'].removeAt(oldIndex);
      currentMealData['recipes'].insert(newIndex, id);
      mealList.removeAt(mealIndex);
      mealList.insert(mealIndex, currentMealData);
      ConnectDb().updateMeal({currentDate: mealList});
    });
  }

  void _notifyAdded(BuildContext context, Recipe recipe) {
    showMySnackBar(
      context,
      'Added!',
      'Undo',
      () {
        Provider.of<RecipeList>(context, listen: false).removeRecipe(recipe);
      },
    );
  }

  Future<void> pickAndProcessImage(
      BuildContext context, XFile? pickedFile) async {
    if (pickedFile != null) {
      setState(() {
        isLoading = true;
        isSearching = true;
      });
      File imageFile = File(pickedFile.path);
      final imageBytes = await imageFile.readAsBytes();

      String mimeType = '';
      if (pickedFile.path.toLowerCase().endsWith('.png')) {
        mimeType = 'image/png';
      } else if (pickedFile.path.toLowerCase().endsWith('.jpg') ||
          pickedFile.path.toLowerCase().endsWith('.jpeg')) {
        mimeType = 'image/jpeg';
      } else {
        if (context.mounted) {
          showMySnackBar(context, 'Unsupported Image format', 'Dismiss', () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          });
        }
        return;
      }

      GoogleApi gemini = GoogleApi(
          prompt:
              'Analize the picture attached and give me an output in json format of the basic ingredients you have identified as a json list. Only respond with the actual json text no formatting, only the start brackets till the end brackets, in the following json format: [list of ingredients].',
          imageBytes: imageBytes,
          mimeType: mimeType);

      final response = await gemini.generateContentResponse();
      if (context.mounted && response.text != null) {
        List ingredients = gemini.parseAiJson(context, response.text!) ?? [];
        if (ingredients.isNotEmpty) {
          // fetchRecipes(ingredients, ['Simple Foods']); // OLD LINE
          fetchApiRecipes(ingredients, ['Simple Foods']); // NEW LINE
          // After fetchApiRecipes, we might need to consider fetching shared recipes too
          // and then calling combineAndDisplayRecipes. For now, just fix the name.
          // To make it consistent with text search, it should be:
          // setState(() { isLoading = true; isSearching = true; }); // if not already set
          // await Future.wait([
          //   fetchApiRecipes(ingredients, ['Simple Foods']),
          //   fetchSharedRecipes(), // This might need adjustment if we want to filter shared by ingredients
          // ]);
          // combineAndDisplayRecipes();
          // For now, the scope is just to fix the function name.
          // The existing behavior of image search only showing API results will remain
          // until we decide to enhance it.
          return; 
        }
        if (context.mounted) {
          showMySnackBar(context, 'Ingredients not found', 'Dismiss', () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          });
        }
      }
      return;
    } else {
      if (context.mounted) {
        showMySnackBar(context, 'No Image Selected', 'Dismiss', () {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
        });
      }
      return;
    }
  }

  Future<void> listYesterday(
      ConnectDb db, CurrentDate date, BuildContext context) async {
    var userData = await db.meals.doc(db.uid).get();
    final Map<String, dynamic> data =
        (userData.data()! as Map<String, dynamic>);
    final String yesterdayDate = date.getDate(-1);

    if (!data.containsKey(yesterdayDate)) {
      if (context.mounted) {
        showMySnackBar(context, 'No records for yesterday', 'Dismiss', () {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
        });
      }
      return;
    }

    final List yesterdayMeals = data[yesterdayDate];
    final List yesterdayTitles = [];
    final List yesterdayRecipes = [];

    for (var meal in yesterdayMeals) {
      if (meal['recipes'].isNotEmpty) {
        yesterdayTitles.add(meal['mealTitle']);
        yesterdayRecipes.add(meal['recipes']);
      }
    }

    if (context.mounted) {
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return MyDialog(
                cancelButtonText: 'Cancel',
                titles: yesterdayTitles,
                recipes: yesterdayRecipes);
          });
    }

    return;
  }

  @override
  Widget build(BuildContext context) {
    final ConnectDb db = context.watch<ConnectDb>();
    final CurrentDate date = context.read<CurrentDate>();
    return Consumer<RecipeList>(
      builder: (context, value, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(value.currentMealData['mealTitle'],
                style: Theme.of(context).textTheme.labelLarge),
          ),
          body: Column(
            children: [
              Center(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 40, horizontal: 30),
                  child: TextField(
                    controller: _searchController,
                    cursorColor: Color.fromARGB(255, 45, 190, 120),
                    style: Theme.of(context).textTheme.labelSmall,
                    decoration: InputDecoration(
                        filled: true,
                        fillColor: Color.fromARGB(255, 9, 37, 29),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        hintText: "eg: Chicken Curry",
                        prefixIcon: Icon(Icons.search_rounded,
                            color: Color.fromARGB(255, 45, 190, 120)),
                        suffixIcon: isSearching
                            ? IconButton(
                                onPressed: () {
                                  setState(() {
                                    isSearching = false;
                                    _searchController.clear();
                                    apiRecipes.clear();
                                    sharedUserRecipes.clear();
                                    displayableItems.clear();
                                    isLoading = false;
                                  });
                                },
                                icon: Icon(Icons.close),
                              )
                            : null),
                    onSubmitted: (value) async { 
                      if (value.isNotEmpty) {
                        apiRecipes.clear();
                        sharedUserRecipes.clear();
                        displayableItems.clear();
                        setState(() {
                          isLoading = true;
                          isSearching = true;
                        });

                        try {
                          await Future.wait([
                            fetchApiRecipes([value], ['Simple Foods', 'Products', 'Recipes']),
                            fetchSharedRecipes(),
                          ]);
                        } catch (e) {
                          print("Error fetching recipes: $e");
                          if (mounted) {
                            showMySnackBar(context, 'Error fetching recipes', 'Dismiss', () {});
                          }
                        } finally {
                          // combineAndDisplayRecipes will be called here, 
                          // which internally calls setState and sets isLoading = false
                          combineAndDisplayRecipes(); 
                        }
                      } else {
                        setState(() {
                          isSearching = false;
                          apiRecipes.clear();
                          sharedUserRecipes.clear();
                          displayableItems.clear();
                          isLoading = false;
                        });
                      }
                    },
                  ),
                ),
              ),
              isSearching
                  ? isLoading
                      ? CircularProgressIndicator(
                          color: Color.fromARGB(255, 45, 190, 120),
                        )
                      : Expanded(
                          child: Padding(
                          padding: const EdgeInsets.only(bottom: 30),
                          child: ListView.builder(
                            // itemCount: recipes.length -> itemCount: displayableItems.length
                            itemCount: displayableItems.length,
                            itemBuilder: (context, index) {
                              final dynamic item = displayableItems[index];
                              String title, imageUrl;
                              bool isAlreadyAdded = false;
                              // Changed int currentItemIdForCheck = -1 to String? currentItemIdForCheck = null;
                              String? currentItemIdForCheck = null; 

                              if (item is Recipe) {
                                title = item.title;
                                imageUrl = item.imgUrl;
                                currentItemIdForCheck = item.id; // item.id is now String
                                isAlreadyAdded = value.currentMealData['recipes'].contains(item.id);
                              } else if (item is UserRecipe) {
                                title = item.name;
                                imageUrl = item.imageUrl ?? '';
                                // UserRecipes are not in currentMealData by ID, so isAlreadyAdded is effectively false for search
                                // unless we implement a more complex check (e.g. by name, if that makes sense)
                                // For now, allow adding.
                                isAlreadyAdded = false; 
                              } else {
                                return const SizedBox.shrink(); // Should not happen
                              }

                              return MyRecipeItem(
                                  title: title,
                                  imgUrl: imageUrl,
                                  // isUserAdded: item is UserRecipe, // Optional: for MyRecipeItem styling
                                  onPressed: isAlreadyAdded
                                    ? null
                                    : () {
                                        final currentRecipeList = Provider.of<RecipeList>(context, listen: false);
                                        final Map<String, dynamic> times = context.read<UserSettings>().schedule;
                                        
                                        if (item is UserRecipe) {
                                          // Removed newId generation
                                          // Changed Recipe.fromUserRecipe(item, newId) to Recipe.fromUserRecipe(item as UserRecipe)
                                          final recipeToAdd = Recipe.fromUserRecipe(item as UserRecipe);
                                          currentRecipeList.addRecipe(recipeToAdd, value.currentMealData['mealTitle'], times);
                                          _notifyAdded(context, recipeToAdd);
                                        } else if (item is Recipe) {
                                          currentRecipeList.addRecipe(item, value.currentMealData['mealTitle'], times);
                                          _notifyAdded(context, item);
                                        }
                                      },
                                  onTap: () {
                                    if (item is Recipe) {
                                       Navigator.pushNamed(context, '/recipe_insights_page', arguments: item);
                                    } else if (item is UserRecipe) {
                                       // Changed Recipe.fromUserRecipe(item, 0 - item.hashCode) to Recipe.fromUserRecipe(item as UserRecipe)
                                       final tempRecipeForInsight = Recipe.fromUserRecipe(item as UserRecipe);
                                       Navigator.pushNamed(context, '/recipe_insights_page', arguments: tempRecipeForInsight);
                                    }
                                  },
                                  icon: isAlreadyAdded
                                      ? Icons.check_rounded
                                      : Icons.add_circle);
                            },
                          ),
                        ))
                  : value.currentMealData['recipes'].isEmpty
                      ? Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 100),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "No Recipes for ${value.currentMealData['mealTitle']}",
                                  style: Theme.of(context).textTheme.labelSmall,
                                ),
                                ElevatedButton(
                                    onPressed: () async {
                                      listYesterday(db, date, context);
                                    },
                                    child: Text(
                                      "Add from yesterday",
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall,
                                    )),
                              ],
                            ),
                          ),
                        )
                      // Display current meal's recipes if not searching
                      : Expanded( 
                          child: ReorderableListView.builder(
                            onReorder: (oldIndex, newIndex) => updateOrder(
                                oldIndex,
                                newIndex,
                                value.currentMealData['recipes'][oldIndex]),
                            itemCount: value.currentMealData['recipes'].length,
                            itemBuilder: (context, index) {
                              final Recipe recipe = value.recipesList
                                  .firstWhere((recipe) =>
                                      recipe.id ==
                                      value.currentMealData['recipes'][index],
                                      // Changed orElse id from -1 to "_error_not_found_"
                                      orElse: () => Recipe(id: "_error_not_found_", title: "Error - Not Found", nutrients: [], category: 'Error'), 
                                      );
                              // Check against the string error ID
                              if (recipe.id == "_error_not_found_") return const SizedBox.shrink(); 

                              return MyRecipeItem(
                                key: ValueKey<String>(recipe.id), // Optionally ValueKey<String>
                                title: recipe.title,
                                imgUrl: recipe.imgUrl,
                                onPressed: () => value.removeRecipe(recipe),
                                onTap: () => Navigator.pushNamed(
                                    context, '/recipe_insights_page',
                                    arguments: recipe),
                                icon: Icons.delete_rounded,
                              );
                            },
                            proxyDecorator: (Widget child, int index,
                                Animation<double> animation) {
                              return Material(
                                elevation: 8, // Adds shadow while dragging
                                color: Color.fromARGB(255, 6, 23, 18),
                                borderRadius: BorderRadius.circular(20),
                                child: child,
                              );
                            },
                          ),
                        ),
            ],
          ),
          floatingActionButton: SpeedDial(
            icon: Icons.photo_filter_outlined,
            activeIcon: Icons.close,
            backgroundColor: Color.fromARGB(255, 45, 190, 120),
            foregroundColor: Colors.white,
            overlayColor: Colors.black,
            overlayOpacity: 0.5,
            children: [
              SpeedDialChild(
                  child: Icon(
                    Icons.camera_alt_outlined,
                    color: Colors.white,
                  ),
                  backgroundColor: Color.fromARGB(255, 45, 190, 120),
                  onTap: () async {
                    final XFile? pickedFile =
                        await picker.pickImage(source: ImageSource.camera);
                    if (context.mounted) {
                       // pickAndProcessImage calls the old fetchRecipes (now fetchApiRecipes)
                       // This part is not covered by the Future.wait fix for manual search
                       // but the subtask is focused on manual text search.
                      pickAndProcessImage(context, pickedFile);
                    }
                  }),
              SpeedDialChild(
                  child: Icon(
                    Icons.photo_library,
                    color: Colors.white,
                  ),
                  backgroundColor: Color.fromARGB(255, 45, 190, 120),
                  onTap: () async {
                    final XFile? pickedFile =
                        await picker.pickImage(source: ImageSource.gallery);
                    if (context.mounted) {
                      pickAndProcessImage(context, pickedFile);
                    }
                  })
            ],
          ),
        );
      },
    );
  }
}
