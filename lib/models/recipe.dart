import 'package:health_app_v1/models/user_recipe.dart';

class Recipe {
  final int id;
  final String title;
  final String imageUrl;
  final String type;
  List nutrients;
  final String category;

  Recipe({
    required this.id,
    required this.title,
    this.imageUrl = '',
    this.type = '',
    required this.nutrients,
    required this.category,
  });

  String get imgUrl => (imageUrl == '' && type != '') ? getImgUrl() : imageUrl;

  String getImgUrl() {
    String url = 'https://img.spoonacular.com/products/$id-312x231.$type';
    return url;
  }

  double getNutrients(String name) {
    for (var item in nutrients) {
      if (item['name'] == name) {
        return item['amount'].toDouble();
      }
    }
    return 0.0;
  }

  Map<String, dynamic> getMetaData() {
    return {
      "id": id.toString(),
      "title": title,
      "imageUrl": imgUrl,
      "type": type,
      "nutrients": {
        "Carbs": getNutrients("Carbohydrates"),
        "Fats": getNutrients("Fat"),
        "Proteins": getNutrients("Protein")
      }
    };
  }

  factory Recipe.fromMap(Map<String, dynamic> map) {
    return Recipe(
      id: map['id'] as int,
      title: map['title'] as String,
      imageUrl: map['imgUrl'] as String? ?? '', // Provide default if null
      type: map['type'] as String? ?? '',       // Provide default if null
      nutrients: map['nutrients'] as List,
      category: map['category'] as String,
    );
  }

  factory Recipe.fromUserRecipe(UserRecipe userRecipe, int newId) {
    return Recipe(
      id: newId, // This ID needs to be managed carefully by RecipeList
      title: userRecipe.name,
      imageUrl: userRecipe.imageUrl ?? '',
      type: userRecipe.imageUrl != null && userRecipe.imageUrl!.toLowerCase().endsWith('.png') ? 'png' : (userRecipe.imageUrl != null && (userRecipe.imageUrl!.toLowerCase().endsWith('.jpg') || userRecipe.imageUrl!.toLowerCase().endsWith('.jpeg')) ? 'jpg' : ''),
      nutrients: [
        {'name': 'Calories', 'amount': userRecipe.calories, 'unit': 'kcal'}, // Assuming Spoonacular format
        {'name': 'Protein', 'amount': userRecipe.protein, 'unit': 'g'},
        {'name': 'Carbohydrates', 'amount': userRecipe.carbs, 'unit': 'g'},
        {'name': 'Fat', 'amount': userRecipe.fat, 'unit': 'g'},
      ],
      category: 'User Added', // Or some other suitable category
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'imgUrl': imgUrl,
      'type': type,
      'nutrients': nutrients,
      'category': category,
    };
  }

  void updateNutrients(List updatedNutrients) {
    nutrients = updatedNutrients;
  }
}
