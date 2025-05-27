import 'package:flutter/material.dart';
import 'package:health_app_v1/components/meal/my_meal_circle.dart';
import 'package:health_app_v1/models/recipe_list.dart';
import 'package:provider/provider.dart';

// ignore: must_be_immutable
class MyMealTile extends StatelessWidget {
  final double height;
  final EdgeInsets margin;
  final String mealTitle;
  final int currentMeal;
  final List recipeList;
  void Function()? onTab;
  void Function()? onPressed;

  MyMealTile({
    super.key,
    required this.height,
    required this.margin,
    required this.mealTitle,
    required this.recipeList,
    required this.currentMeal,
    required this.onTab,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<RecipeList>(
      builder: (context, value, child) {
        return GestureDetector(
          onTap: onTab,
          child: Container(
            // height: height,
            margin: margin,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: const Color.fromARGB(255, 9, 37, 29),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 20, top: 10),
                      child: Text(
                        mealTitle,
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(right: 5),
                      child: IconButton(
                        onPressed: onPressed,
                        icon: Icon(
                          Icons.delete,
                          color: Color.fromARGB(255, 45, 190, 120),
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: 10,
                ),
                Container(
                  height: 80,
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  clipBehavior: Clip.antiAlias,
                  // padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: ListView.builder(
                    itemCount: recipeList.length,
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (context, index) {
                      if (!value.initialized) {
                        return CircularProgressIndicator();
                      }

                      final recipe = value.recipesList.firstWhere(
                          (recipe) => recipe.id == recipeList[index]);
                      return MyMealCircle(imgUrl: recipe.imgUrl);
                    },
                  ),
                ),
                ReorderableDragStartListener(
                    index: currentMeal,
                    child: Icon(
                      Icons.drag_handle_rounded,
                      color: Color.fromARGB(255, 45, 190, 120),
                    )),
              ],
            ),
          ),
        );
      },
    );
  }
}
