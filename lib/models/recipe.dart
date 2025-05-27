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
      id: map['id'],
      title: map['title'],
      imageUrl: map['imgUrl'],
      type: map['type'],
      nutrients: map['nutrients'],
      category: map['category'],
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
