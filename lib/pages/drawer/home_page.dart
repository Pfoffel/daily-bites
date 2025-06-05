import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:health_app_v1/components/general/my_day_heading.dart';
import 'package:health_app_v1/components/general/my_drawer.dart';
import 'package:health_app_v1/components/meal/my_macro_tile.dart';
import 'package:health_app_v1/components/meal/my_meal_tile.dart';
import 'package:health_app_v1/components/general/my_streak.dart';
import 'package:health_app_v1/components/mood/my_mood_tile.dart';
import 'package:health_app_v1/models/current_date.dart';
import 'package:health_app_v1/models/mood.dart';
import 'package:health_app_v1/models/user_settings.dart';
import 'package:health_app_v1/models/recipe_list.dart';
import 'package:health_app_v1/service/connect_db.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List _defaultMeals = [
    {'mealTitle': 'Breakfast', 'recipes': []},
    {'mealTitle': 'Lunch', 'recipes': []},
    {'mealTitle': 'Dinner', 'recipes': []}
  ];

  void updateOrder(int oldIndex, int newIndex, Map<String, dynamic> mealData) {
    setState(() {
      if (oldIndex < newIndex) {
        newIndex--;
      }
      final String currentDate = context.read<RecipeList>().currentDate;
      final List<dynamic> mealList = context.read<RecipeList>().mealList;
      mealList.removeAt(oldIndex);
      mealList.insert(newIndex, mealData);
      ConnectDb().updateMeal(currentDate, mealList);
    });
  }

  Map<String, dynamic> convertRecipeIntsToStrings(
      Map<String, dynamic> mealsByDate) {
    // Create a new map to store the transformed data to avoid modifying the original directly
    // unless that's your explicit intent (which is generally discouraged for complex objects).
    Map<String, dynamic> newMealsByDate = {};

    mealsByDate.forEach((date, mealsForDate) {
      if (mealsForDate is List) {
        List<Map<String, dynamic>> newMealsForDate = [];

        for (var mealEntry in mealsForDate) {
          if (mealEntry is Map<String, dynamic>) {
            // Create a new map for the meal entry to modify it
            Map<String, dynamic> newMealEntry = Map.from(mealEntry);

            if (newMealEntry.containsKey('recipes')) {
              var recipes = newMealEntry['recipes'];

              if (recipes is List) {
                // Map each item in the recipes list.
                // We'll convert each item to a String, ensuring it's not null.
                newMealEntry['recipes'] = recipes
                    .map((recipeId) {
                      if (recipeId is int) {
                        return recipeId.toString();
                      } else if (recipeId != null) {
                        // Handle cases where it might already be a string or other type
                        return recipeId.toString();
                      }
                      return null; // Handle null entries if they exist
                    })
                    .where((e) =>
                        e !=
                        null) // Remove any null entries if they occurred from null recipeIds
                    .toList()
                    .cast<
                        String>(); // Ensure the list contains only Strings after conversion
              } else if (recipes == null) {
                // If 'recipes' is null, keep it null or set to empty list as per your requirement
                newMealEntry['recipes'] =
                    []; // Or [] if you prefer empty list over null
              }
              // If 'recipes' is not a List or null, it's left as is.
            }
            newMealsForDate.add(newMealEntry);
          }
        }
        newMealsByDate[date] = newMealsForDate;
      } else {
        // If the value for a date is not a List (unexpected format), copy it as is.
        newMealsByDate[date] = mealsForDate;
      }
    });

    return newMealsByDate;
  }

  @override
  Widget build(BuildContext context) {
    final EdgeInsets marginContainer =
        EdgeInsets.symmetric(horizontal: 30, vertical: 15);
    List mealList = [];
    List moodCategoriesList = [];
    final CurrentDate dateProvider = context.watch<CurrentDate>();
    final ConnectDb db = context.watch<ConnectDb>();
    final List<String> symbols = ["😢", "🥺", "😐", "😊", "😆"];

    return Scaffold(
        appBar: AppBar(
          elevation: 1,
          actions: const [
            Padding(
              padding: EdgeInsets.only(right: 30),
              child: MyStreak(
                streakCount: 3,
              ),
            ),
          ],
        ),
        drawer: const MyDrawer(),
        body: StreamBuilder<DocumentSnapshot>(
          stream: db.streamCurrentDayMeals,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                  child: CircularProgressIndicator(
                color: Color.fromARGB(255, 45, 190, 120),
              ));
            }

            if (!snapshot.hasData ||
                !snapshot.data!.exists ||
                snapshot.data!.data() == null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                db.initializeMeals(dateProvider.sanitizedDate, db.uid);
              });
              mealList = _defaultMeals; // Use default until data arrives
            } else {
              final Map<String, dynamic> data =
                  snapshot.data!.data()! as Map<String, dynamic>;
              mealList = (data['meals'] as List);
            }

            final Map<String, double> totalNutrients =
                context.read<RecipeList>().sumNutrients(mealList);

            return Column(
              children: [
                const SizedBox(
                  height: 30,
                ),
                Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 60),
                    child: MyDayHeading(
                      previousDay: () {
                        final String newDate = context
                            .read<CurrentDate>()
                            .previousDay()
                            .replaceAll("/", "-");
                        context.read<RecipeList>().setCurrentDate(newDate);
                        context.read<Mood>().setCurrentDate(newDate);
                        db.updateUID(db.uid);
                      },
                      nextDay: () {
                        final newDate = context
                            .read<CurrentDate>()
                            .nextDay()
                            .replaceAll("/", "-");
                        context.read<RecipeList>().setCurrentDate(newDate);
                        context.read<Mood>().setCurrentDate(newDate);
                        db.updateUID(db.uid);
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 100),
                  child: Consumer<CurrentDate>(
                    builder: (context, date, child) {
                      return Text(
                        date.currentDate,
                        textAlign: TextAlign.right,
                        style: Theme.of(context).textTheme.labelMedium,
                      );
                    },
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 20, right: 20, top: 20),
                  child: Row(children: [
                    Expanded(
                        child: MyMacroTile(
                            type: 'Carbs', amount: totalNutrients['Carbs']!)),
                    Expanded(
                        child: MyMacroTile(
                            type: 'Proteins',
                            amount: totalNutrients['Proteins']!)),
                    Expanded(
                        child: MyMacroTile(
                            type: 'Fats', amount: totalNutrients['Fats']!)),
                  ]),
                ),
                Expanded(
                  child: ReorderableListView.builder(
                    padding: EdgeInsets.only(bottom: 50),
                    itemCount: mealList.length + 1, // +1 for the mood tile
                    itemBuilder: (context, index) {
                      if (index < mealList.length) {
                        return MyMealTile(
                          key: ValueKey(mealList[index]['mealTitle']),
                          height: 180,
                          margin: marginContainer,
                          mealTitle: mealList[index]['mealTitle'],
                          recipeList: mealList[index]['recipes'],
                          currentMeal: index,
                          onTab: () {
                            context
                                .read<RecipeList>()
                                .setCurrentDayMeal(mealList);
                            context.read<RecipeList>().setCurrentMeal(index);
                            Navigator.pushNamed(context, '/list_recipe_page');
                          },
                          onPressed: () {
                            context
                                .read<RecipeList>()
                                .setCurrentDayMeal(mealList);
                            context.read<RecipeList>().removeMeal(
                                index,
                                mealList[index]['mealTitle'],
                                context.read<UserSettings>().schedule);
                          },
                        );
                      } else {
                        return StreamBuilder<DocumentSnapshot>(
                          key: ValueKey('Mood-${dateProvider.sanitizedDate}'),
                          stream: db.streamCurrentDayMoods,
                          builder: (context, moodSnapshot) {
                            if (moodSnapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Center(
                                  child: CircularProgressIndicator(
                                color: Color.fromARGB(255, 45, 190, 120),
                              ));
                            }

                            // Check if document exists and has data for today's mood
                            if (!moodSnapshot.hasData ||
                                !moodSnapshot.data!.exists ||
                                moodSnapshot.data!.data() == null) {
                              // If no data for today, initialize it
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                db.initializeMood(
                                    dateProvider.sanitizedDate, db.uid);
                              });
                              moodCategoriesList = db
                                  .defaultMoods; // Use defaults until data arrives
                            } else {
                              final Map<String, dynamic> data =
                                  moodSnapshot.data!.data()!
                                      as Map<String, dynamic>;
                              moodCategoriesList = (data['moods']
                                  as List); // Access 'moods' field
                            }
                            final int totalScore = context
                                .read<Mood>()
                                .updateTotalScore(moodCategoriesList);

                            return GestureDetector(
                              onTap: () {
                                context
                                    .read<Mood>()
                                    .updateCategories(moodCategoriesList);
                                Navigator.pushNamed(context, '/mood_page');
                              },
                              child: MyMoodTile(
                                height: 180,
                                title: 'Mood',
                                margin: EdgeInsets.symmetric(
                                    horizontal: 30, vertical: 30),
                                symbols: symbols,
                                selectedIndex: totalScore,
                                tapable: false,
                              ),
                            );
                          },
                        );
                      }
                    },
                    proxyDecorator:
                        (Widget child, int index, Animation<double> animation) {
                      return Material(
                        elevation: 8, // Adds shadow while dragging
                        color: Color.fromARGB(255, 6, 23, 18),
                        borderRadius: BorderRadius.circular(20),
                        child: child,
                      );
                    },
                    onReorder: (oldIndex, newIndex) =>
                        updateOrder(oldIndex, newIndex, mealList[oldIndex]),
                  ),
                ),
              ],
            );
          },
        ),
        floatingActionButton: SpeedDial(
          icon: Icons.add,
          activeIcon: Icons.close,
          backgroundColor: Color.fromARGB(255, 45, 190, 120),
          foregroundColor: Colors.white,
          overlayColor: Colors.black,
          overlayOpacity: 0.5,
          children: [
            SpeedDialChild(
                label: 'Snack',
                labelStyle: Theme.of(context).textTheme.labelMedium,
                labelBackgroundColor: Color.fromARGB(255, 45, 190, 120),
                onTap: () => context.read<RecipeList>().addMeal('Snack')),
            if (context.watch<RecipeList>().mealList.firstWhere(
                    (map) => map['mealTitle'] == 'Breakfast',
                    orElse: () => -1) ==
                -1)
              SpeedDialChild(
                  label: 'Breakfast',
                  labelStyle: Theme.of(context).textTheme.labelMedium,
                  labelBackgroundColor: Color.fromARGB(255, 45, 190, 120),
                  onTap: () => context.read<RecipeList>().addMeal('Breakfast')),
            if (context.watch<RecipeList>().mealList.firstWhere(
                    (map) => map['mealTitle'] == 'Lunch',
                    orElse: () => -1) ==
                -1)
              SpeedDialChild(
                  label: 'Lunch',
                  labelStyle: Theme.of(context).textTheme.labelMedium,
                  labelBackgroundColor: Color.fromARGB(255, 45, 190, 120),
                  onTap: () => context.read<RecipeList>().addMeal('Lunch')),
            if (context.watch<RecipeList>().mealList.firstWhere(
                    (map) => map['mealTitle'] == 'Dinner',
                    orElse: () => -1) ==
                -1)
              SpeedDialChild(
                  label: 'Dinner',
                  labelStyle: Theme.of(context).textTheme.labelMedium,
                  labelBackgroundColor: Color.fromARGB(255, 45, 190, 120),
                  onTap: () => context.read<RecipeList>().addMeal('Dinner')),
            SpeedDialChild(
              label: 'Custom Meal/Ingredient',
              labelStyle: Theme.of(context).textTheme.labelMedium,
              labelBackgroundColor: Color.fromARGB(255, 45, 190, 120),
              onTap: () {
                Navigator.pushNamed(context, '/add_custom_recipe_page');
              },
            ),
          ],
        ));
  }
}
