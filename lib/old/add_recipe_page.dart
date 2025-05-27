// import 'package:flutter/material.dart';
// import 'package:health_app_v1/old/my_recipe_tile.dart';
// import 'package:health_app_v1/models/recipe.dart';
// import 'package:health_app_v1/models/recipe_list.dart';
// import 'package:health_app_v1/service/recipe_service.dart';
// import 'package:provider/provider.dart';

// class AddRecipePage extends StatefulWidget {
//   const AddRecipePage({super.key});

//   @override
//   State<AddRecipePage> createState() => _AddRecipePageState();
// }

// class _AddRecipePageState extends State<AddRecipePage> {
//   final TextEditingController _searchController = TextEditingController();
//   List<Recipe> recipes = [];
//   bool isLoading = false;

//   void fetchRecipes(query) async {
//     setState(() {
//       isLoading = true;
//     });

//     final recipeService = Provider.of<RecipeService>(context, listen: false);

//     List<Recipe> result = await recipeService.getProduct(query);

//     setState(() {
//       recipes = result;
//       isLoading = false;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     final String name = Provider.of<RecipeList>(context, listen: false)
//         .currentMealData['mealTitle'];

//     return Scaffold(
//         appBar: AppBar(
//           title: Text(name, style: Theme.of(context).textTheme.labelLarge),
//         ),
//         body: Column(
//           children: [
//             Padding(
//               padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 30),
//               child: TextField(
//                 controller: _searchController,
//                 cursorColor: Color.fromARGB(255, 45, 190, 120),
//                 style: Theme.of(context).textTheme.labelSmall,
//                 decoration: InputDecoration(
//                   filled: true,
//                   fillColor: Color.fromARGB(255, 9, 37, 29),
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(10),
//                     borderSide: BorderSide.none,
//                   ),
//                   hintText: "eg: Chicken Curry",
//                   prefixIcon: Icon(Icons.search_rounded,
//                       color: Color.fromARGB(255, 45, 190, 120)),
//                 ),
//                 onSubmitted: (value) {
//                   if (value.isNotEmpty) {
//                     fetchRecipes(value);
//                   }
//                 },
//               ),
//             ),
//             isLoading
//                 ? CircularProgressIndicator(
//                     color: Color.fromARGB(255, 45, 190, 120),
//                   )
//                 : Expanded(
//                     child: ListView.builder(
//                     itemCount: recipes.length,
//                     itemBuilder: (context, index) {
//                       return MyRecipeTile(recipe: recipes[index]);
//                     },
//                   )),
//           ],
//         ));
//   }
// }
