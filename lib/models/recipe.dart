import 'package:health_app_v1/models/user_recipe.dart';

class Recipe {
  final String id; // Changed from int to String
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
      "id": id, // id is already a String
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
    dynamic idValue = map['id'];
    String finalId;
    if (idValue == null) {
      // Consider how to handle this case. For now, let's assume Spoonacular IDs are usually ints.
      // If this map can come from other sources where ID might be missing, this needs robust handling.
      // For Spoonacular IDs, they are typically integers.
      // If 'id' can be legitimately null or missing for other recipe types, adjust logic.
      // For this specific conversion, if it's from Spoonacular, an ID should exist.
      // If converting from a user's own recipe map where ID might be a string already:
      throw ArgumentError('Recipe ID from map cannot be null'); 
    } else if (idValue is int) {
      finalId = idValue.toString();
    } else if (idValue is String) {
      finalId = idValue;
    } else {
      throw ArgumentError('Recipe ID from map must be a String or an int, got ${idValue.runtimeType}');
    }

    return Recipe(
      id: finalId,
      title: map['title'] as String,
      imageUrl: map['imgUrl'] as String? ?? '',
      type: map['type'] as String? ?? '',
      nutrients: map['nutrients'] as List,
      category: map['category'] as String,
    );
  }

  factory Recipe.fromUserRecipe(UserRecipe userRecipe) { // Removed newId parameter
    if (userRecipe.id == null) {
      throw ArgumentError('UserRecipe ID cannot be null when converting to Recipe');
    }
    return Recipe(
      id: userRecipe.id!, // Use UserRecipe's Firestore document ID (now a String)
      title: userRecipe.name,
      imageUrl: userRecipe.imageUrl ?? '',
      type: userRecipe.imageUrl != null && userRecipe.imageUrl!.toLowerCase().endsWith('.png') ? 'png' : (userRecipe.imageUrl != null && (userRecipe.imageUrl!.toLowerCase().endsWith('.jpg') || userRecipe.imageUrl!.toLowerCase().endsWith('.jpeg')) ? 'jpg' : ''),
      nutrients: [
        {'name': 'Calories', 'amount': userRecipe.calories, 'unit': 'kcal'},
        {'name': 'Protein', 'amount': userRecipe.protein, 'unit': 'g'},
        {'name': 'Carbohydrates', 'amount': userRecipe.carbs, 'unit': 'g'},
        {'name': 'Fat', 'amount': userRecipe.fat, 'unit': 'g'},
      ],
      category: 'User Added',
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
