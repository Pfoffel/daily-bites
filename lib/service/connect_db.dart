import 'dart:io'; // Added for File type

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart'; // Added for Firebase Storage
import 'package:flutter/material.dart';
import 'package:health_app_v1/models/recipe.dart';
import 'package:health_app_v1/models/user_recipe.dart';
import 'package:intl/intl.dart'; // Ensure UserRecipe is imported
import 'package:uuid/uuid.dart'; // Added for Uuid

class ConnectDb extends ChangeNotifier {
  String _uid = FirebaseAuth.instance.currentUser!.uid;

  final CollectionReference _mealsCollection =
      FirebaseFirestore.instance.collection('meals');
  final CollectionReference _moodCollection =
      FirebaseFirestore.instance.collection('mood');
  final CollectionReference _recipes =
      FirebaseFirestore.instance.collection('recipes');
  final CollectionReference _settings =
      FirebaseFirestore.instance.collection('settings');
  final CollectionReference _sharedRecipes =
      FirebaseFirestore.instance.collection('shared_recipes');

  // Stream<DocumentSnapshot<Map<String, dynamic>>> _streamMeals =
  //     FirebaseFirestore.instance
  //         .collection('meals')
  //         .doc(FirebaseAuth.instance.currentUser!.uid)
  //         .snapshots();
  // final Stream<DocumentSnapshot<Map<String, dynamic>>> _streamMoods =
  //     FirebaseFirestore.instance
  //         .collection('mood')
  //         .doc(FirebaseAuth.instance.currentUser!.uid)
  //         .snapshots();

  final List _initializeMeals = [
    {
      'mealTitle': 'Breakfast',
      'recipes': [] // Changed 0 to "0"
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
      // {
      //   'id': "0", // Changed 0 to "0"
      //   'title': 'Apple',
      //   'imgUrl': "https://img.spoonacular.com/ingredients_100x100/apple.jpg",
      //   'type': 'jpg',
      //   'nutrients': [],
      //   'category': 'Product'
      // }
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

  late Stream<DocumentSnapshot<Map<String, dynamic>>> _streamCurrentDayMeals;
  late Stream<DocumentSnapshot<Map<String, dynamic>>> _streamCurrentDayMoods;

  Map<String, dynamic> _timesMap = {};
  List<Recipe> _recipesList = [];
  List _moodList = [];
  Map<String, dynamic> _goalsMap = {};
  bool _surveyCompleted = false;

  String get uid => _uid;
  CollectionReference get mealsCollection => _mealsCollection;
  CollectionReference get recipes => _recipes;
  CollectionReference get moodCollection => _moodCollection;

  Stream<DocumentSnapshot<Map<String, dynamic>>> get streamCurrentDayMeals =>
      _streamCurrentDayMeals;
  Stream<DocumentSnapshot<Map<String, dynamic>>> get streamCurrentDayMoods =>
      _streamCurrentDayMoods;

  List get defaultMeals =>
      (_recipesList.indexWhere((recipe) => recipe.id == "0") >
              -1) // Changed recipe.id == 0 to recipe.id == "0"
          ? _defaultMeals
          : _initializeMeals;
  List get defaultMoods => _defaultMoods;
  Map<String, dynamic> get timeMap => _timesMap;
  Map<String, dynamic> get goalsMap => _goalsMap;
  bool get surveyCompleted => _surveyCompleted;
  List<Recipe> get recipesList => _recipesList;
  List get moodList => _moodList;

  void updateUID(String uid, String currentDate) {
    _uid = uid;
    _streamCurrentDayMeals = _mealsCollection
        .doc(uid)
        .collection('daily_entries')
        .doc(currentDate)
        .snapshots();
    _streamCurrentDayMoods = _moodCollection
        .doc(uid)
        .collection('daily_entries')
        .doc(currentDate)
        .snapshots();
    notifyListeners();
  }

  // -------------- Data Migration -----------------
  // should only be called for the first time then should be good to go

  Future<void> migrateUserDataToSubcollections(String uid) async {
    if (uid == 'RBTA9BpEFbUTKnvn2Al850w3KMT2') {
      print("Already migrated");
    } else {
      print('Starting data migration for user: $uid');

      // Meals Data
      DocumentSnapshot<Map<String, dynamic>> oldMealsDoc =
          await _mealsCollection.doc(uid).get()
              as DocumentSnapshot<Map<String, dynamic>>;
      if (oldMealsDoc.exists &&
          oldMealsDoc.data() != null &&
          oldMealsDoc.data()!.isNotEmpty) {
        bool looksLikeOldMeals =
            oldMealsDoc.data()!.keys.any((key) => key.contains('-'));
        if (looksLikeOldMeals) {
          final Map<String, dynamic> allOldMeals = oldMealsDoc.data()!;
          final WriteBatch batch = FirebaseFirestore.instance.batch();
          int migratedMealsCount = 0;

          for (var entry in allOldMeals.entries) {
            final String date = entry.key;
            final List mealsForDay = entry.value as List;

            for (var meal in mealsForDay) {
              final mealIds = meal["recipes"] as List;
              final updatedMealsForDay = [];
              for (var recipeId in mealIds) {
                updatedMealsForDay.add(recipeId.toString());
              }
              meal["recipes"] = updatedMealsForDay;
            }

            final DocumentReference newDailyMealsDocRef =
                _mealsCollection.doc(uid).collection('daily_entries').doc(date);
            batch
                .set(newDailyMealsDocRef, {'date': date, 'meals': mealsForDay});
            migratedMealsCount++;
          }
          await batch.commit();
          print('Migrated $migratedMealsCount meal entries for user $uid');
        } else {
          print(
              'Meals document for user $uid does not appear to be in old format or already migrated.');
        }
      } else {
        print('No old meals document found for user $uid or it is empty.');
      }

      DocumentSnapshot<Map<String, dynamic>> oldMoodDoc = await _moodCollection
          .doc(uid)
          .get() as DocumentSnapshot<Map<String, dynamic>>;
      if (oldMoodDoc.exists &&
          oldMoodDoc.data() != null &&
          oldMoodDoc.data()!.isNotEmpty) {
        bool looksLikeOldMoods =
            oldMoodDoc.data()!.keys.any((key) => key.contains('-'));
        if (looksLikeOldMoods) {
          final Map<String, dynamic> allOldMoods = oldMoodDoc.data()!;
          final WriteBatch batch = FirebaseFirestore.instance.batch();
          int migratedMoodCount = 0;

          for (var entry in allOldMoods.entries) {
            final String date = entry.key;
            final List moodsForDay = entry.value as List;

            final DocumentReference newDailyMoodsDocRef =
                _moodCollection.doc(uid).collection('daily_entries').doc(date);
            batch.set(newDailyMoodsDocRef, {
              'date': date,
              'moods': moodsForDay,
            });
            migratedMoodCount++;
          }
          await batch.commit();
          print('Migrated $migratedMoodCount mood entries for user $uid');
        } else {
          print(
              'Mood document for user $uid does not appear to be in old format or already migrated.');
        }
      } else {
        print(
            'No old mood document found for found for user $uid or it is empty.');
      }
      print('Data migration process completed for user: $uid');
    }
  }

  Future<void> initializeMeals(String currentDate, String newUid) async {
    final DocumentReference userDailyMealsDoc = _mealsCollection
        .doc(newUid)
        .collection('daily_entries')
        .doc(currentDate);
    await userDailyMealsDoc.set({
      'date': currentDate,
      'meals': _initializeMeals,
    });
  }

  Future<void> initializeMood(String currentDate, String newUid) async {
    final DocumentReference userDailyMoodDoc = _moodCollection
        .doc(newUid)
        .collection('daily_entries')
        .doc(currentDate);
    await userDailyMoodDoc.set({
      'date': currentDate,
      'moods': _defaultMoods,
    });
  }

  Future<void> initializeSettings(String newUid) async {
    final DocumentReference userSettings = _settings.doc(newUid);
    final Map<String, dynamic> settings = {
      'schedules': _defaultTimes,
      'goals': _defaultGoals,
      'surveyCompleted':
          false, // surveyCompleted is now part of the settings map
    };

    // The entire settings map is set as the value for the 'settings' field
    await userSettings.set({'settings': settings});
  }

  Future<void> saveSurveyData(
      String userId, Map<String, dynamic> surveyData) async {
    try {
      // Save survey data to a specific document in a subcollection
      await _settings
          .doc(userId)
          .collection('user_surveys')
          .doc('initial_survey')
          .set(surveyData, SetOptions(merge: true));

      // Update the main settings document with surveyCompleted: true
      await _settings.doc(userId).set({
        'settings': {'surveyCompleted': true}
      }, SetOptions(merge: true));

      print('Survey data saved successfully for user $userId');
      notifyListeners(); // Notify listeners on success
    } catch (e) {
      print('Error saving survey data for user $userId: $e');
      rethrow; // Rethrow the error to be handled by the caller
    }
  }

  Future<Map<String, dynamic>?> getSurveyData(String userId) async {
    try {
      final DocumentReference docRef = _settings
          .doc(userId)
          .collection('user_surveys')
          .doc('initial_survey');
      final DocumentSnapshot doc = await docRef.get();

      if (doc.exists && doc.data() != null) {
        return doc.data() as Map<String, dynamic>;
      } else {
        print('Survey document not found for user $userId');
        return null;
      }
    } catch (e) {
      print('Error fetching survey data for user $userId: $e');
      return null;
    }
  }

  Future<void> initializeRecipes(String newUid) async {
    final DocumentReference userRecipes = _recipes.doc(newUid);

    await userRecipes.set(_defaultRecipes);
  }

  Future<void> updateMeal(String date, List mealData) async {
    final DocumentReference dailyMealDoc =
        _mealsCollection.doc(_uid).collection('daily_entries').doc(date);
    await dailyMealDoc.update({'meals': mealData});
  }

  Future<void> updateMood(String date, List moodData) async {
    final DocumentReference dailyMoodDoc =
        _moodCollection.doc(_uid).collection('daily_entries').doc(date);
    await dailyMoodDoc.update({'moods': moodData});
  }

  Future<List<Map<String, dynamic>>> getMealsForDateRange(
      String uid, DateTime startDate, DateTime endDate) async {
    final String startDateStr = DateFormat('yyyy-MM-dd').format(startDate);
    final String endDateStr = DateFormat('yyyy-MM-dd').format(endDate);

    final QuerySnapshot querySnapshot = await _mealsCollection
        .doc(uid)
        .collection('daily_entries')
        .where('date', isGreaterThanOrEqualTo: startDateStr)
        .where('date', isLessThanOrEqualTo: endDateStr)
        .orderBy('date') // Ensure data is returned in chronological order
        .get();

    List<Map<String, dynamic>> dailyData = [];
    for (var doc in querySnapshot.docs) {
      dailyData.add(doc.data() as Map<String, dynamic>);
    }
    return dailyData;
  }

  Future<List<Map<String, dynamic>>> getMoodsForDateRange(
      String uid, DateTime startDate, DateTime endDate) async {
    final String startDateStr = DateFormat('yyyy-MM-dd').format(startDate);
    final String endDateStr = DateFormat('yyyy-MM-dd').format(endDate);

    final QuerySnapshot querySnapshot = await _moodCollection
        .doc(uid)
        .collection('daily_entries')
        .where('date', isGreaterThanOrEqualTo: startDateStr)
        .where('date', isLessThanOrEqualTo: endDateStr)
        .orderBy('date')
        .get();

    List<Map<String, dynamic>> dailyData = [];
    for (var doc in querySnapshot.docs) {
      dailyData.add(doc.data() as Map<String, dynamic>);
    }
    return dailyData;
  }

  Future<void> loadSettings() async {
    var userSettings = await _settings.doc(_uid).get();
    Map<String, dynamic> settings = {};
    Map<String, dynamic> newTimes = {};
    Map<String, dynamic> newGoals = {};
    bool surveyCompleted = false;
    final Map<String, dynamic> data =
        (userSettings.data()! as Map<String, dynamic>);
    settings = data['settings'];
    newTimes = settings['schedules'];
    newGoals = settings['goals'];
    surveyCompleted = settings["surveyCompleted"];
    _timesMap = newTimes;
    _goalsMap = newGoals;
    _surveyCompleted = surveyCompleted;
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

  Future<void> loadMoods(String currentDate) async {
    var userMoodDoc = await _moodCollection
        .doc(_uid)
        .collection('daily_entries')
        .doc(currentDate)
        .get();
    if (userMoodDoc.exists && userMoodDoc.data() != null) {
      _moodList = (userMoodDoc.data()!)['moods'] as List;
    } else {
      // If no entry for today, initialize it (important for new days)
      await initializeMood(currentDate, _uid);
      _moodList = _defaultMoods;
    }
    notifyListeners();
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

  Future<void> updateRecipes(List<Recipe> updatedList) async {
    final List<dynamic> uploadList = [];
    for (var recipe in updatedList) {
      uploadList.add(recipe.toMap());
    }
    DocumentReference docRefRecipes = _recipes.doc(_uid);
    await docRefRecipes.update({'recipes': uploadList});
  }

  void signOut() {
    _uid = '';
    _recipesList = [];
    _moodList = [];
    _timesMap = {};
    _goalsMap = {};
    notifyListeners();
  }

  Future<String?> uploadRecipeImage(File imageFile) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('User not logged in, cannot upload image.');
      return null;
    }
    final String uid = user.uid;
    final String fileName = const Uuid().v4();
    final Reference storageRef =
        FirebaseStorage.instance.ref('user_recipe_images/$uid/$fileName');

    try {
      print('Image file path to upload: ${imageFile.path}'); // Added
      print(
          'Checking if image file exists locally: ${await imageFile.exists()}'); // Added

      print(
          'Attempting to upload to Firebase Storage path: ${storageRef.fullPath}');
      await storageRef.putFile(imageFile);
      print('File uploaded successfully to Firebase.');
      final String downloadUrl = await storageRef.getDownloadURL();
      print('Successfully got download URL: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('Error during recipe image upload process: $e');
      if (e is FirebaseException) {
        print(
            'FirebaseException details - Code: ${e.code}, Message: ${e.message}');
      }
      return null;
    }
  }

  Future<void> addSharedRecipe(UserRecipe recipe, {File? imageFile}) async {
    try {
      Map<String, dynamic> recipeData = recipe.toMap();

      if (imageFile != null) {
        String? imageUrl = await uploadRecipeImage(imageFile);
        if (imageUrl != null) {
          recipeData['imageUrl'] = imageUrl;
        }
      }
      await _sharedRecipes.add(recipeData);
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
