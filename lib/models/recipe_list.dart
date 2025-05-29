import 'package:flutter/material.dart';
import 'package:health_app_v1/models/recipe.dart';
import 'package:health_app_v1/service/connect_db.dart';
import 'package:health_app_v1/service/notifications_service.dart';
import 'package:health_app_v1/service/recipe_service.dart';
import 'package:intl/intl.dart';

class RecipeList extends ChangeNotifier {
  bool _initialized = false;

  List _convertMealListRecipeIdsToString(List rawMealList) {
    return rawMealList.map((meal) {
      if (meal is Map<String, dynamic> && meal.containsKey('recipes') && meal['recipes'] is List) {
        final List<dynamic> originalRecipeIds = meal['recipes'];
        final List<String> newRecipeIds = originalRecipeIds.map((id) {
          if (id is int) {
            return id.toString();
          } else if (id is String) {
            return id;
          }
          // Handle other unexpected types or null if necessary, though Firestore should give int/string
          return ''; // Or throw, or filter out invalid IDs
        }).where((id) => id.isNotEmpty).toList(); // Filter out empty strings if used as placeholder for invalid
        
        // Create a new map to avoid modifying the original input map directly if it's from a stream
        final newMeal = Map<String, dynamic>.from(meal);
        newMeal['recipes'] = newRecipeIds;
        return newMeal;
      }
      return meal; // Return as is if not a processable meal map
    }).toList();
  }

  final List<Recipe> _recipesList = [];
  final List _mealList = [];
  final Map<String, dynamic> _currentMealdata = {};
  double _totalCarbs = 0.0;
  double _totalProteins = 0.0;
  double _totalFats = 0.0;

  int _currentMeal = 0;
  String _currentDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

  // List<List<Recipe>> get meals => _meals[_currentDate]!;
  int get currentMeal => _currentMeal;
  Map<String, dynamic> get currentMealData => _currentMealdata;
  String get currentDate => _currentDate;
  List get mealList => _mealList;
  List<Recipe> get recipesList => _recipesList;
  bool get initialized => _initialized;
  Map<String, double> get totalNutrients => {
        'Carbs': _totalCarbs,
        'Proteins': _totalProteins,
        'Fats': _totalFats,
      };

  void initializeRecipes(List<Recipe> recipes, List mealsDay) {
    if (_initialized) return;
    _recipesList.addAll(recipes);
    final processedMealsDay = _convertMealListRecipeIdsToString(mealsDay);
    _mealList.addAll(processedMealsDay);
    _initialized = true;
  }

  Future<Recipe> _updateRecipesList(Recipe recipe) async {
    final int recipeFound =
        _recipesList.indexWhere((element) => element.id == recipe.id);
    if (recipeFound == -1) {
      Recipe recipeToAdd = recipe;
      // If the recipe is from Spoonacular (or any external source needing nutrient fetch)
      // and nutrients are empty, fetch them.
      // User-added recipes will come with nutrients pre-filled by Recipe.fromUserRecipe.
      if (recipe.nutrients.isEmpty && recipe.category != 'User Added') { 
          recipeToAdd = await RecipeService().addNutrients(recipe);
      }
      
      // Ensure the ID is unique if it's a new recipe from a user source
      // For now, RecipeList expects recipe.id to be correctly set before this point.
      // The ListRecipesPage will handle creating a Recipe object from UserRecipe with a new ID.

      _recipesList.add(recipeToAdd);
      ConnectDb().updateRecipes(_recipesList); // Save to user's private recipe cache
      return recipeToAdd;
    }
    // If recipe exists, and it's an API recipe, and nutrients were missing, update them.
    else if (_recipesList[recipeFound].nutrients.isEmpty && _recipesList[recipeFound].category != 'User Added') {
      _recipesList[recipeFound] = await RecipeService().addNutrients(_recipesList[recipeFound]);
      ConnectDb().updateRecipes(_recipesList);
      return _recipesList[recipeFound];
    }
    return _recipesList[recipeFound]; // Return existing recipe
  }

  void setCurrentDate(String date) {
    _currentDate = date;
    notifyListeners();
  }

  void setCurrentMeal(int mealIndex) {
    _currentMeal = mealIndex;
    _currentMealdata.clear();
    _currentMealdata.addAll(_mealList[mealIndex]);
    notifyListeners();
  }

  void setCurrentDayMeal(List mealList) {
    _mealList.clear();
    final processedMealList = _convertMealListRecipeIdsToString(mealList);
    _mealList.addAll(processedMealList);
    notifyListeners();
  }

  void updateMealName(String newName) {
    _currentMealdata['mealTitle'] = newName;
    _mealList.removeAt(_currentMeal);
    _mealList.insert(_currentMeal, _currentMealdata);
    ConnectDb().updateMeal({_currentDate: _mealList});
    notifyListeners();
  }

  void addRecipe(Recipe recipe, String key, Map<String, dynamic> times) async {
    _currentMealdata['recipes'].add(recipe.id);
    _mealList.removeAt(_currentMeal);
    _mealList.insert(_currentMeal, currentMealData);
    final Recipe updatedRecipe = await _updateRecipesList(recipe);
    _totalCarbs += updatedRecipe.getNutrients('Carbohydrates');
    _totalProteins += updatedRecipe.getNutrients('Protein');
    _totalFats += updatedRecipe.getNutrients('Fat');
    final ConnectDb db = ConnectDb();
    db.updateMeal({_currentDate: _mealList});
    final isComplete = await NotificationsService.isMealDataComplete(db.uid);

    if (isComplete) {
      await NotificationsService.scheduleNotification(
          'Streak', times['Streak'], 1);
    }

    final Map<String, dynamic> meal =
        _mealList.firstWhere((value) => value['mealTitle'] == key);

    if (meal['recipes'].length == 1 && key != 'Snack') {
      await NotificationsService.scheduleNotification(key, times[key], 1);
    }
    notifyListeners();
  }

  void removeRecipe(Recipe recipe) {
    final String recipeId = recipe.id; // Changed from int title to String recipeId
    _currentMealdata['recipes'].removeWhere(
      (element) => element == recipeId, // Compare with recipeId
    );
    _mealList.removeAt(_currentMeal);
    _mealList.insert(_currentMeal, currentMealData);
    ConnectDb().updateMeal({_currentDate: _mealList});
    _totalCarbs -= recipe.getNutrients('Carbohydrates');
    _totalProteins -= recipe.getNutrients('Protein');
    _totalFats -= recipe.getNutrients('Fat');
    notifyListeners();
  }

  void addMeal(String newName) {
    _mealList.add({'mealTitle': newName, 'recipes': []});
    ConnectDb().updateMeal({_currentDate: _mealList});
    notifyListeners();
  }

  void removeMeal(int index, String key, Map<String, dynamic> times) async {
    _mealList.removeAt(index);
    final ConnectDb db = ConnectDb();
    db.updateMeal({_currentDate: _mealList});
    final isComplete = await NotificationsService.isMealDataComplete(db.uid);

    if (isComplete) {
      await NotificationsService.scheduleNotification(
          'Streak', times['Streak'], 1);
    }
    if (key != 'Snack') {
      await NotificationsService.scheduleNotification(key, times[key], 1);
    }
    notifyListeners();
  }

  Recipe getRecipe(String id) { // Changed signature from int id to String id
    return _recipesList.firstWhere((recipe) => recipe.id == id);
  }

  Map<String, double> sumNutrients(List mealsDay) {
    // Process mealsDay here as well to ensure IDs are strings before getRecipe is called
    // if mealsDay can come from an unprocessed source directly.
    // However, if sumNutrients is always called with _mealList (which is processed),
    // or if mealsDay is guaranteed to be processed by the caller, this might be redundant.
    // For safety, let's process it, assuming mealsDay might not always be _mealList.
    final processedMealsDay = _convertMealListRecipeIdsToString(mealsDay);
    _totalCarbs = 0.0;
    _totalProteins = 0.0;
    _totalFats = 0.0;
    for (var meal in processedMealsDay) { // Iterate over processedMealsDay
      if (meal != null) {
        // meal['recipes'] should now be List<String>
        for (var id_str in meal['recipes']) { // id is now string, renamed to id_str for clarity
          if (id_str != null && id_str.isNotEmpty) { // Ensure id_str is not null or empty
            final Recipe recipe = getRecipe(id_str); // Pass String id_str
            _totalCarbs += recipe.getNutrients('Carbohydrates');
            _totalProteins += recipe.getNutrients('Protein');
            _totalFats += recipe.getNutrients('Fat');
          }
        }
      }
    }
    return {
      'Carbs': _totalCarbs,
      'Proteins': _totalProteins,
      'Fats': _totalFats,
    };
  }

  void signOut() {
    _totalCarbs = 0.0;
    _totalProteins = 0.0;
    _totalFats = 0.0;
    _recipesList.clear();
    _mealList.clear();
    _currentMealdata.clear();
    _currentMeal = 0;
    _currentDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _initialized = false;
    notifyListeners();
  }
}
