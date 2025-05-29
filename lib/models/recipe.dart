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
      // Consider if a default ID or different handling is better than throwing,
      // depending on how critical a missing ID from source is.
      // For now, throwing an error highlights data issues.
      print("Recipe.fromMap: Encountered null ID for recipe titled: ${map['title']}");
      throw ArgumentError('Recipe ID from map cannot be null. Recipe title: ${map['title']}');
    } else if (idValue is int) {
      finalId = idValue.toString();
    } else if (idValue is String) {
      finalId = idValue;
    } else {
      print("Recipe.fromMap: Encountered ID of unexpected type ${idValue.runtimeType} for recipe titled: ${map['title']}");
      throw ArgumentError('Recipe ID from map must be a String or an int, got ${idValue.runtimeType}. Recipe title: ${map['title']}');
    }

    return Recipe(
      id: finalId,
      title: map['title'] as String? ?? 'Untitled Recipe', // Added null safety for title
      imageUrl: map['imgUrl'] as String? ?? '',
      type: map['type'] as String? ?? '',
      // Ensure nutrients and category also have null safety or default values if they can be null from map
      nutrients: map['nutrients'] as List? ?? [], 
      category: map['category'] as String? ?? 'Uncategorized',
    );
  }

  factory Recipe.fromUserRecipe(UserRecipe userRecipe) { 
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
