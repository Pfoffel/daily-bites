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
  List<Recipe> recipes = [];
  bool isLoading = false;
  bool isSearching = false;
  bool aiLoading = false;
  final ImagePicker picker = ImagePicker();

  void fetchRecipes(List queries, List categories) async {
    final List<Recipe> results = [];
    setState(() {
      isLoading = true;
      isSearching = true;
    });

    final recipeService = Provider.of<RecipeService>(context, listen: false);
    for (var query in queries) {
      List<Recipe> result = await recipeService.getFood(query, categories);
      results.addAll(result);
    }

    setState(() {
      recipes = results;
      isLoading = false;
    });
  }

  void updateOrder(int oldIndex, int newIndex, int id) {
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
          fetchRecipes(ingredients, ['Simple Foods']);
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
                                  });
                                },
                                icon: Icon(Icons.close),
                              )
                            : null),
                    onSubmitted: (value) {
                      if (value.isNotEmpty) {
                        fetchRecipes(
                            [value], ['Simple Foods', 'Products', 'Recipes']);
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
                            itemCount: recipes.length,
                            itemBuilder: (context, index) {
                              return MyRecipeItem(
                                  title: recipes[index].title,
                                  imgUrl: recipes[index].imgUrl,
                                  onPressed: value.currentMealData['recipes']
                                          .contains(recipes[index].id)
                                      ? null
                                      : () {
                                          final Map<String, dynamic> times =
                                              context
                                                  .read<UserSettings>()
                                                  .schedule;
                                          Provider.of<RecipeList>(context,
                                                  listen: false)
                                              .addRecipe(
                                                  recipes[index],
                                                  value.currentMealData[
                                                      'mealTitle'],
                                                  times);
                                          _notifyAdded(context, recipes[index]);
                                        },
                                  onTap: () => Navigator.pushNamed(
                                      context, '/recipe_insights_page',
                                      arguments: recipes[index]),
                                  icon: value.currentMealData['recipes']
                                          .contains(recipes[index].id)
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
                                      value.currentMealData['recipes'][index]);
                              return MyRecipeItem(
                                key: ValueKey(recipe.id),
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
