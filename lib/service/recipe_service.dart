import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:health_app_v1/models/recipe.dart';
import 'package:http/http.dart' as http;

class RecipeService {
  final String apiKey = '0eb442d0f65b47ca8d4c68e0252378d2';
  final String baseUrl = 'https://api.spoonacular.com';

  Future<List<Recipe>> getRecipes(
      String query, String included, String excluded) async {
    final String url =
        '$baseUrl/recipes/complexSearch?query=$query&includeIngredients=$included&excludeIngredients=$excluded&addRecipeNutrition=true&apiKey=$apiKey';
    // final String url = '$baseUrl/food/ingredients/search?query=$query&number=3&metaInformation=true&apiKey=$apiKey';
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<Recipe> recipes = [];
        for (var recipeData in data['results']) {
          final Map<String, dynamic> recipeMapForFromMap = {
            'id': recipeData['id'],
            'title': recipeData['title'],
            'imgUrl': recipeData['image'], // map 'image' to 'imgUrl'
            'type': recipeData['imageType'], // Spoonacular often provides imageType
            'nutrients': recipeData['nutrition']?['nutrients'] ?? [], // Ensure nutrients list exists
            'category': 'Recipes', // Set category
          };
          final recipe = Recipe.fromMap(recipeMapForFromMap);
          recipes.add(recipe);
        }
        return recipes;
      } else {
        throw Exception('Failed to load recipes');
      }
    } catch (e) {
      debugPrint(e.toString());
      return [];
    }
  }

  Future<Map<String, String>> parseIngredients(String query) async {
    final String url =
        '$baseUrl/recipes/queries/analyze?q=$query&apiKey=$apiKey';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final dishesRaw = data['dishes'];
      final ingredientsRaw = data['ingredients'];
      List<String> dishesList = [];
      for (var item in dishesRaw) {
        dishesList.add(item['name']);
      }
      String dishes = dishesList.isEmpty ? query : dishesList.join(",");
      List<String> includedList = [];
      List<String> excludedList = [];
      for (var item in ingredientsRaw) {
        switch (item['include']) {
          case true:
            includedList.add(item['name']);
            break;
          case false:
            excludedList.add(item['name']);
            break;
        }
      }

      String includedIngredients = includedList.join(",");
      String excludedIngredients = excludedList.join(",");

      return {
        'dishes': dishes,
        'includedIngredients': includedIngredients,
        'excludedIngredients': excludedIngredients,
      };
    } else {
      throw Exception('Error parsing ingredients: ${response.statusCode}');
    }
  }

  Future<List<Recipe>> getProduct(String query) async {
    final String url =
        '$baseUrl/food/products/search?query=$query&number=1&addProductInformation=true&apiKey=$apiKey';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<Recipe> products = [];
        for (var item in data['products']) {
          final Map<String, dynamic> productMapForFromMap = {
            'id': item['id'],
            'title': item['title'],
            'imgUrl': item['image'], // product 'image' is usually a full URL
            'type': item['imageType'], 
            'nutrients': item['nutrition']?['nutrients'] ?? [],
            'category': 'Products',
          };
          final Recipe product = Recipe.fromMap(productMapForFromMap);
          products.add(product);
        }

        return products;
      } else {
        throw Exception('Failed to load Products');
      }
    } catch (e) {
      debugPrint(e.toString());
      return [];
    }
  }

  Future<List<Recipe>> getFood(String query, List categories) async {
    final String url =
        '$baseUrl/food/search?query=$query&sort=popularity&number=3&apiKey=$apiKey';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<Recipe> products = [];
        final List searchResults = data['searchResults'];
        for (var category in categories) {
          final Map<String, dynamic> results =
              searchResults.firstWhere((item) => item['name'] == category);
          if (results.isNotEmpty) {
            for (var result in results['results']) {
              if (await isValidUrl(result['image'])) {
                final Map<String, dynamic> foodMapForFromMap = {
                  'id': result['id'],
                  'title': result['name'],
                  'imgUrl': result['image'],
                  'type': null, // General food search might not provide 'imageType'
                  'nutrients': [], // Correctly empty, to be filled by addNutrients
                  'category': category,
                };
                final Recipe food = Recipe.fromMap(foodMapForFromMap);
                products.add(food);
              }
            }
          }
        }
        return products;
      } else {
        throw Exception('Failed to load Products');
      }
    } catch (e) {
      debugPrint(e.toString());
      return [];
    }
  }

  Future<bool> isValidUrl(String url) async {
    try {
      final response = await http.head(Uri.parse(url));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<Recipe> addNutrients(Recipe recipe) async {
    final String id = recipe.id; // Changed from int to String
    final String category = recipe.category;
    List updatedNutrients = [];
    final String urlRecipes =
        '$baseUrl/recipes/$id/information?includeNutrition=true&apiKey=$apiKey';
    final String urlSimpleFoods =
        '$baseUrl/food/ingredients/$id/information?amount=1&apiKey=$apiKey';
    final String urlProducts = '$baseUrl/food/products/$id?apiKey=$apiKey';

    switch (category) {
      case 'Recipes':
        updatedNutrients = await _fetchNutrients(urlRecipes);
        break;
      case 'Products':
        updatedNutrients = await _fetchNutrients(urlProducts);
        break;
      case 'Simple Foods':
        updatedNutrients = await _fetchNutrients(urlSimpleFoods);
        break;
      default:
        updatedNutrients = await _fetchNutrients(urlSimpleFoods);
        break;
    }
    recipe.updateNutrients(updatedNutrients);
    return recipe;
  }

  Future<List<dynamic>> _fetchNutrients(String url) async {
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['nutrition']['nutrients'];
      } else {
        throw Exception('Failed to load Products');
      }
    } catch (e) {
      debugPrint(e.toString());
      return [];
    }
  }
}
