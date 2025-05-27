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
      ConnectDb().updateMeal({currentDate: mealList});
    });
  }

  @override
  Widget build(BuildContext context) {
    final EdgeInsets marginContainer =
        EdgeInsets.symmetric(horizontal: 30, vertical: 15);
    List mealList = [];
    List moodList = [];
    final CurrentDate date = context.watch<CurrentDate>();
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
          stream: db.streamMeals,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                  child: CircularProgressIndicator(
                color: Color.fromARGB(255, 45, 190, 120),
              ));
            }

            final userMeals = snapshot.data!.data() as Map<String, dynamic>;

            if (!userMeals.containsKey(date.sanitizedDate)) {
              db.updateMeal({date.sanitizedDate: _defaultMeals});
              userMeals.addEntries({date.sanitizedDate: _defaultMeals}.entries);
            }

            mealList = userMeals[date.sanitizedDate];
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
                      },
                      nextDay: () {
                        final newDate = context
                            .read<CurrentDate>()
                            .nextDay()
                            .replaceAll("/", "-");
                        context.read<RecipeList>().setCurrentDate(newDate);
                        context.read<Mood>().setCurrentDate(newDate);
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
                    itemCount: mealList.length + 1,
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
                        return StreamBuilder(
                          key: ValueKey('Mood'),
                          stream: db.streamMoods,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Center(
                                  child: CircularProgressIndicator(
                                color: Color.fromARGB(255, 45, 190, 120),
                              ));
                            }

                            final userMood =
                                snapshot.data!.data() as Map<String, dynamic>;

                            if (!userMood.containsKey(date.sanitizedDate)) {
                              db.updateMood(
                                  {date.sanitizedDate: db.defaultMoods});
                              userMood.addEntries({
                                date.sanitizedDate: db.defaultMoods
                              }.entries); // think this is unnecessary
                            }

                            moodList = userMood[date.sanitizedDate];
                            final int totalScore =
                                context.read<Mood>().updateTotalScore(moodList);

                            return GestureDetector(
                              onTap: () {
                                context.read<Mood>().updateCategories(moodList);
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
          ],
        ));
  }
}
