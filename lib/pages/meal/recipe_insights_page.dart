import 'package:flutter/material.dart';
import 'package:health_app_v1/components/meal/my_macro_tile.dart';
import 'package:health_app_v1/models/recipe.dart';

class RecipeInsightsPage extends StatelessWidget {
  const RecipeInsightsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final recipe = ModalRoute.of(context)?.settings.arguments as Recipe;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          recipe.title,
          style: Theme.of(context).textTheme.labelLarge,
        ),
      ),
      body: Column(
        children: [
          Container(
            height: 270, 
            decoration: BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(recipe.imgUrl),
                fit: BoxFit.cover,
              )
            ),
          ),
          SizedBox(height: 30,),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                Expanded(
                  child: MyMacroTile(type: 'Carbs', amount: recipe.getNutrients('Carbohydrates'))
                ),
                Expanded(
                  child: MyMacroTile(type: 'Proteins', amount: recipe.getNutrients('Protein'))
                ),
                Expanded(
                  child: MyMacroTile(type: 'Fats', amount: recipe.getNutrients('Fat'))
                ),
              ]
            ),
          )
        ],
      ),
    );
  }
}