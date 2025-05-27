// import 'package:flutter/material.dart';
// import 'package:health_app_v1/models/recipe.dart';
// import 'package:health_app_v1/models/recipe_list.dart';
// import 'package:provider/provider.dart';

// class MyRecipeTile extends StatefulWidget {
//   final Recipe recipe;

//   const MyRecipeTile({
//     super.key,
//     required this.recipe,
//   });

//   @override
//   State<MyRecipeTile> createState() => _MyRecipeTileState();
// }

// class _MyRecipeTileState extends State<MyRecipeTile> {
//   void _notifyAdded(BuildContext context) {
//     final snackBar = SnackBar(
//       content: const Text('Added!'),
//       action: SnackBarAction(
//         label: 'Undo',
//         onPressed: () {
//           // Perform an action here, such as undoing a change.
//         },
//       ),
//       duration: const Duration(seconds: 3),
//     );

//     ScaffoldMessenger.of(context).showSnackBar(snackBar);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Stack(
//       alignment: AlignmentDirectional.bottomEnd,
//       children: [
//         Container(
//           margin: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
//           height: 150,
//           decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(20),
//             color: Color.fromARGB(255, 9, 37, 29),
//             image: DecorationImage(
//               colorFilter: ColorFilter.mode(
//                   Colors.black.withValues(alpha: 0.4), BlendMode.multiply),
//               image: NetworkImage(widget.recipe.imgUrl),
//               fit: BoxFit.cover,
//             ),
//           ),
//           child: Center(
//             child: Text(
//               widget.recipe.title,
//               textAlign: TextAlign.center,
//               style: Theme.of(context).textTheme.labelMedium,
//             ),
//           ),
//         ),
//         Padding(
//           padding: const EdgeInsets.only(bottom: 20, right: 35),
//           child: IconButton(
//             onPressed: () {
//               Provider.of<RecipeList>(context, listen: false)
//                   .addRecipe(widget.recipe);
//               _notifyAdded(context);
//             },
//             icon: Icon(Icons.add),
//             style: ButtonStyle(
//                 backgroundColor:
//                     WidgetStatePropertyAll(Color.fromARGB(160, 45, 190, 120))),
//           ),
//         ),
//       ],
//     );
//   }
// }
