import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:health_app_v1/models/recipe.dart';
import 'package:health_app_v1/models/user_recipe.dart'; // Ensure UserRecipe is imported

class ConnectDb extends ChangeNotifier {
  String _uid = FirebaseAuth.instance.currentUser!.uid;

  final CollectionReference _meals =
      FirebaseFirestore.instance.collection('meals');
  final CollectionReference _recipes =
      FirebaseFirestore.instance.collection('recipes');
  final CollectionReference _mood =
      FirebaseFirestore.instance.collection('mood');
  final CollectionReference _settings =
      FirebaseFirestore.instance.collection('settings');
  final CollectionReference _sharedRecipes =
      FirebaseFirestore.instance.collection('shared_recipes');

  Stream<DocumentSnapshot<Map<String, dynamic>>> _streamMeals =
      FirebaseFirestore.instance
          .collection('meals')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .snapshots();
  final Stream<DocumentSnapshot<Map<String, dynamic>>> _streamMoods =
      FirebaseFirestore.instance
          .collection('mood')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .snapshots();

  final List _initializeMeals = [
    {
      'mealTitle': 'Breakfast',
      'recipes': [0]
    },
    {'mealTitle': 'Lunch', 'recipes': []},
    {'mealTitle': 'Dinner', 'recipes': []}
  ];

  final List _defaultMeals = [
    {'mealTitle': 'Breakfast', 'recipes': []},
    {'mealTitle': 'Lunch', 'recipes': []},
    {'mealTitle': 'Dinner', 'recipes': []}
  ];

  final Map<String, dynamic> _defaultTimes = {
    'Breakfast': '08:00',
    'Lunch': '13:00',
    'Dinner': '20:00',
    'Streak': '22:00'
  };

  final Map<String, dynamic> _defaultGoals = {
    'enabled': false,
    'Carbs': 1.0,
    'Proteins': 1.0,
    'Fats': 1.0,
  };

  final Map<String, List<Map<String, dynamic>>> _defaultRecipes = {
    'recipes': [
      {
        'id': 0,
        'title': 'Apple',
        'imgUrl': "https://img.spoonacular.com/ingredients_100x100/apple.jpg",
        'type': 'jpg',
        'nutrients': [],
        'category': 'Product'
      }
    ],
  };

  final List _defaultMoods = [
    {
      'title': 'Emotional Mood',
      'score': -1,
      'description': 'description of what this means.'
    },
    {
      'title': 'Stress Level',
      'score': -1,
      'description': 'description of what this means.'
    },
    {
      'title': 'Energy Level',
      'score': -1,
      'description': 'description of what this means.'
    },
    {
      'title': 'Motivational Level',
      'score': -1,
      'description': 'description of what this means.'
    },
    {
      'title': 'Productivity Level',
      'score': -1,
      'description': 'description of what this means.'
    },
    {
      'title': 'Sleep Quality',
      'score': -1,
      'description': 'description of what this means.'
    },
    {
      'title': 'Physical Well-being',
      'score': -1,
      'description': 'description of what this means.'
    },
    {
      'title': 'Overall Well-being',
      'score': -1,
      'description': 'description of what this means.'
    },
  ];

  Map<String, dynamic> _timesMap = {};
  List<Recipe> _recipesList = [];
  Map<String, dynamic> _moodList = {};
  Map<String, dynamic> _goalsMap = {};

  String get uid => _uid;
  CollectionReference get meals => _meals;
  CollectionReference get recipes => _recipes;
  CollectionReference get mood => _mood;
  List get defaultMeals =>
      (_recipesList.indexWhere((recipe) => recipe.id == 0) > -1)
          ? _defaultMeals
          : _initializeMeals;
  List get defaultMoods => _defaultMoods;
  Map<String, dynamic> get timeMap => _timesMap;
  Map<String, dynamic> get goalsMap => _goalsMap;
  List<Recipe> get recipesList => _recipesList;
  Map<String, dynamic> get moodList => _moodList;
  Stream<DocumentSnapshot<Map<String, dynamic>>> get streamMeals =>
      _streamMeals;
  Stream<DocumentSnapshot<Map<String, dynamic>>> get streamMoods =>
      _streamMoods;

  void updateUID(String uid) {
    _uid = uid;
    _streamMeals =
        FirebaseFirestore.instance.collection('meals').doc(uid).snapshots();
  }

  Future<void> initializeMeals(String currentDate, String newUid) async {
    final DocumentReference userMeals = _meals.doc(newUid);

    await userMeals.set({currentDate: _initializeMeals});
  }

  Future<void> initializeSettings(String newUid) async {
    final DocumentReference userSettings = _settings.doc(newUid);
    final Map<String, dynamic> settings = {
      'schedules': _defaultTimes,
      'goals': _defaultGoals,
    };

    await userSettings.set({'settings': settings});
  }

  Future<void> initializeRecipes(String newUid) async {
    final DocumentReference userRecipes = _recipes.doc(newUid);

    await userRecipes.set(_defaultRecipes);
  }

  Future<void> initializeMood(String currentDate, String newUid) async {
    final DocumentReference userMood = _mood.doc(newUid);

    await userMood.set({currentDate: _defaultMoods});
  }

  Future<void> loadSettings() async {
    var userSettings = await _settings.doc(_uid).get();
    Map<String, dynamic> settings = {};
    Map<String, dynamic> newTimes = {};
    Map<String, dynamic> newGoals = {};
    final Map<String, dynamic> data =
        (userSettings.data()! as Map<String, dynamic>);
    settings = data['settings'];
    newTimes = settings['schedules'];
    newGoals = settings['goals'];
    _timesMap = newTimes;
    _goalsMap = newGoals;
    notifyListeners();
  }

  Future<void> loadRecipes() async {
    var userRecipes = await _recipes.doc(_uid).get();
    final List<Recipe> newRecipes = [];
    Map<String, dynamic> recipes = {};
    if (userRecipes.exists) {
      _recipesList.clear();
      recipes = (userRecipes.data()! as Map<String, dynamic>);
      for (var recipe in recipes['recipes']!) {
        newRecipes.add(Recipe.fromMap(recipe));
      }
      _recipesList = newRecipes;
      notifyListeners();
    }
  }

  Future<void> loadMoods() async {
    var userMoods = await _mood.doc(_uid).get();
    Map<String, dynamic> moodCategories = {};
    if (userMoods.exists) {
      moodCategories = (userMoods.data()! as Map<String, dynamic>);
      _moodList = moodCategories;
    }
  }

  Future<void> updateSettings(Map<String, dynamic> updatedTimes,
      Map<String, dynamic> updatedGoals) async {
    final DocumentReference userSettings = _settings.doc(_uid);
    final Map<String, dynamic> settings = {
      'schedules': updatedTimes,
      'goals': updatedGoals,
    };
    await userSettings.update({'settings': settings});
  }

  Future<void> updateMeal(Map<String, List> updatedList) async {
    DocumentReference docRefMeals = _meals.doc(_uid);
    await docRefMeals.update(updatedList);
  }

  Future<void> updateRecipes(List<Recipe> updatedList) async {
    final List<dynamic> uploadList = [];
    for (var recipe in updatedList) {
      uploadList.add(recipe.toMap());
    }
    DocumentReference docRefRecipes = _recipes.doc(_uid);
    await docRefRecipes.update({'recipes': uploadList});
  }

  Future<void> updateMood(Map<String, List> updatedList) async {
    DocumentReference docRefMood = _mood.doc(_uid);
    await docRefMood.update(updatedList);
  }

  void signOut() {
    _uid = '';
    _recipesList = [];
    _moodList = {};
    _timesMap = {};
    _goalsMap = {};
    notifyListeners();
  }

  Future<void> addSharedRecipe(UserRecipe recipe) async {
    try {
      await _sharedRecipes.add(recipe.toMap());
    } catch (e) {
      // Log the error or handle it as needed
      print('Error adding shared recipe: $e');
      rethrow; // Optionally rethrow the error if the caller needs to handle it
    }
  }

  Future<List<UserRecipe>> getSharedRecipes() async {
    try {
      final QuerySnapshot<Map<String, dynamic>> querySnapshot =
          await _sharedRecipes.orderBy('createdAt', descending: true).get() 
          as QuerySnapshot<Map<String, dynamic>>; // Cast here
      
      return querySnapshot.docs
          .map((doc) => UserRecipe.fromSnapshot(doc))
          .toList();
    } catch (e) {
      print('Error fetching shared recipes: $e');
      return []; // Return an empty list on error
    }
  }
}
