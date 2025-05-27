import 'package:flutter/material.dart';
import 'package:health_app_v1/models/recipe.dart';
import 'package:health_app_v1/models/recipe_list.dart';
import 'package:health_app_v1/models/user_settings.dart';
import 'package:provider/provider.dart';

// ignore: must_be_immutable
class MyDialog extends StatelessWidget {
  final String cancelButtonText;
  final List titles;
  final List recipes;

  const MyDialog({
    super.key,
    required this.cancelButtonText,
    required this.titles,
    required this.recipes,
  });

  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          // title: Text('Select from yesterday'),
          content: SizedBox(
            height: 75 * titles.length.toDouble(),
            width: double.maxFinite,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 50),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: titles.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: ElevatedButton(
                        onPressed: () {
                          final List<Recipe> recipeList =
                              context.read<RecipeList>().recipesList;
                          for (var id in recipes[index]) {
                            final recipe = recipeList
                                .firstWhere((recipe) => recipe.id == id);
                            final Map<String, dynamic> times =
                                context.read<UserSettings>().schedule;
                            Provider.of<RecipeList>(context, listen: false)
                                .addRecipe(recipe, titles[index], times);
                          }
                          Navigator.pop(context);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          child: Text(
                            titles[index],
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        )),
                  );
                },
              ),
            ),
          ),
          // actions: [
          //   MaterialButton(
          //     onPressed: () {
          //       Navigator.pop(context);
          //     },
          //     child: Text(
          //       cancelButtonText,
          //       style: Theme.of(context).textTheme.labelSmall,
          //     ),
          //   ),
          // ],
        );
      },
    );
  }
}
