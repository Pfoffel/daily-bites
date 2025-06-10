import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:health_app_v1/models/recipe.dart';
import 'package:health_app_v1/models/user_recipe.dart'; // Ensure UserRecipe is imported
import 'package:fl_chart/fl_chart.dart';

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
      'recipes': ["0"] // Changed 0 to "0"
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
        'id': "0", // Changed 0 to "0"
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
      (_recipesList.indexWhere((recipe) => recipe.id == "0") >
              -1) // Changed recipe.id == 0 to recipe.id == "0"
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

  // Helper method to get the start date based on the timeframe
  DateTime _getStartDate(String timeframe) {
    final now = DateTime.now();
    switch (timeframe) {
      case 'weekly':
        return now.subtract(Duration(days: now.weekday - 1));
      case 'monthly':
        return DateTime(now.year, now.month, 1);
      case 'quarterly':
        // Assuming a quarter starts on Jan 1, Apr 1, Jul 1, Oct 1
        int currentQuarter = ((now.month - 1) / 3).floor() + 1;
        return DateTime(now.year, (currentQuarter - 1) * 3 + 1, 1);
      case 'yearly':
        return DateTime(now.year, 1, 1);
      default:
        return now; // Should not happen
    }
  }

  // Helper method to format date as YYYY-MM-DD
  String _formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  Future<List<FlSpot>> getMoodData(String timeframe) async {
    final List<FlSpot> moodSpots = [];
    final DateTime startDate = _getStartDate(timeframe);
    final DateTime endDate = DateTime.now();

    try {
      final moodsSnapshot = await _mood
          .doc(_uid)
          .collection('daily_entries')
          .where('date',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
              isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('date')
          .get();

      if (moodsSnapshot.docs.isEmpty) {
        return []; // No data for the timeframe
      }

      for (var doc in moodsSnapshot.docs) {
        final data = doc.data();
        final date = (data['date'] as Timestamp).toDate();
        final moods = data['moods'] as List<dynamic>;

        // Assuming 'Overall Well-being' is the target mood for the chart
        // And that mood scores are out of 10
        var overallMood = moods.firstWhere(
            (mood) => mood['title'] == 'Overall Well-being',
            orElse: () => null);

        if (overallMood != null && overallMood['score'] != -1) {
          // For simplicity, using day of the year as X-axis for yearly/quarterly
          // and day of month for monthly, day of week for weekly.
          // This might need adjustment based on chart requirements.
          double xValue;
          switch (timeframe) {
            case 'weekly':
              xValue = date.weekday.toDouble();
              break;
            case 'monthly':
              xValue = date.day.toDouble();
              break;
            case 'quarterly':
            case 'yearly':
              xValue = date.difference(startDate).inDays.toDouble();
              break;
            default:
              xValue = date.difference(startDate).inDays.toDouble();
          }
          moodSpots.add(FlSpot(xValue, overallMood['score'].toDouble()));
        }
      }
      return moodSpots;
    } catch (e) {
      print('Error fetching mood data: $e');
      return []; // Return empty list on error
    }
  }

  Future<List<Map<String, String>>> getIngredientImpactData(
      String timeframe) async {
    final DateTime startDate = _getStartDate(timeframe);
    final DateTime endDate = DateTime.now();
    Map<String, List<double>> ingredientMoodScores = {};

    try {
      // 1. Fetch meals within timeframe
      final mealsSnapshot = await _meals
          .doc(_uid)
          .collection('daily_entries')
          .where('date',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
              isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      if (mealsSnapshot.docs.isEmpty) {
        return []; // No meal data
      }

      // Load all recipes for the user once
      await loadRecipes();
      if (_recipesList.isEmpty) {
        return []; // No recipes available for the user
      }

      Map<String, Recipe> recipeMap = {for (var r in _recipesList) r.id: r};

      for (var mealDoc in mealsSnapshot.docs) {
        final mealData = mealDoc.data();
        final mealDate = (mealData['date'] as Timestamp).toDate();
        final dailyMeals = mealData['meals'] as List<dynamic>;

        // 2. Fetch mood for the corresponding meal date
        final moodDocSnapshot = await _mood
            .doc(_uid)
            .collection('daily_entries')
            .doc(_formatDate(mealDate))
            .get();

        if (!moodDocSnapshot.exists) {
          continue; // No mood data for this specific day
        }

        final moodData = moodDocSnapshot.data();
        final moods = moodData!['moods'] as List<dynamic>;
        var overallMood = moods.firstWhere(
            (m) => m['title'] == 'Overall Well-being',
            orElse: () => null);

        if (overallMood == null || overallMood['score'] == -1) {
          continue; // No overall mood score for this day
        }
        double moodScore = overallMood['score'].toDouble();

        // 3. Correlate ingredients with mood
        for (var meal in dailyMeals) {
          final recipeIds = (meal['recipes'] as List<dynamic>).cast<String>();
          for (String recipeId in recipeIds) {
            Recipe? recipe = recipeMap[recipeId];
            if (recipe != null && recipe.title != 'Apple') {
              // Assuming 'Apple' is a default/placeholder
              // For simplicity, let's assume recipe titles are unique enough to act as ingredient names
              // Or, if ingredients are stored within the recipe object, iterate through them.
              // This part depends heavily on the 'Recipe' model structure.
              // Let's assume recipe.title is the "ingredient" for now.
              String ingredientName = recipe.title;
              ingredientMoodScores
                  .putIfAbsent(ingredientName, () => [])
                  .add(moodScore);
            }
          }
        }
      }

      if (ingredientMoodScores.isEmpty) {
        return [];
      }

      // 4. Format results
      List<Map<String, String>> impactData = [];
      ingredientMoodScores.forEach((ingredient, scores) {
        double averageScore = scores.reduce((a, b) => a + b) / scores.length;
        String impactEmoji =
            averageScore >= 6 ? '👍' : (averageScore < 4 ? '👎' : '😐');
        // Representing impact as percentage of "good days" (mood >= 6)
        double goodDaysPercent =
            (scores.where((s) => s >= 6).length / scores.length) * 100;
        impactData.add({
          'ingredient': ingredient,
          'impact': '$impactEmoji ${goodDaysPercent.toStringAsFixed(0)}% Good',
          'averageScore': averageScore
              .toStringAsFixed(1), // For potential sorting or more detail
        });
      });

      // Sort by good days percentage (descending)
      impactData.sort((a, b) => double.parse(b['averageScore']!)
          .compareTo(double.parse(a['averageScore']!)));

      return impactData;
    } catch (e) {
      print('Error fetching ingredient impact data: $e');
      return [];
    }
  }

  Future<Map<String, String>> getStatisticsData(String timeframe) async {
    final DateTime startDate = _getStartDate(timeframe);
    final DateTime endDate = DateTime.now();
    List<double> moodScores = [];
    Map<String, int> ingredientCounts = {};

    try {
      // 1. Fetch mood data for average mood
      final moodsSnapshot = await _mood
          .doc(_uid)
          .collection('daily_entries')
          .where('date',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
              isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      if (moodsSnapshot.docs.isNotEmpty) {
        for (var doc in moodsSnapshot.docs) {
          final data = doc.data();
          final moods = data['moods'] as List<dynamic>;
          var overallMood = moods.firstWhere(
              (m) => m['title'] == 'Overall Well-being',
              orElse: () => null);
          if (overallMood != null && overallMood['score'] != -1) {
            moodScores.add(overallMood['score'].toDouble());
          }
        }
      }

      // 2. Fetch meal data for most logged ingredient
      final mealsSnapshot = await _meals
          .doc(_uid)
          .collection('daily_entries')
          .where('date',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
              isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      if (mealsSnapshot.docs.isNotEmpty) {
        // Ensure recipes are loaded if not already
        if (_recipesList.isEmpty) await loadRecipes();
        Map<String, Recipe> recipeMap = {for (var r in _recipesList) r.id: r};

        for (var mealDoc in mealsSnapshot.docs) {
          final mealData = mealDoc.data();
          final dailyMeals = mealData['meals'] as List<dynamic>;
          for (var meal in dailyMeals) {
            final recipeIds = (meal['recipes'] as List<dynamic>).cast<String>();
            for (String recipeId in recipeIds) {
              Recipe? recipe = recipeMap[recipeId];
              // Assuming recipe.title is the ingredient name
              if (recipe != null && recipe.title != 'Apple') {
                String ingredientName = recipe.title;
                ingredientCounts[ingredientName] =
                    (ingredientCounts[ingredientName] ?? 0) + 1;
              }
            }
          }
        }
      }

      // 3. Calculate statistics
      String avgMoodString = "N/A";
      if (moodScores.isNotEmpty) {
        double avgMood = moodScores.reduce((a, b) => a + b) / moodScores.length;
        avgMoodString = "${avgMood.toStringAsFixed(1)}/10";
      }

      String mostLoggedIngredientString = "N/A";
      if (ingredientCounts.isNotEmpty) {
        var sortedIngredients = ingredientCounts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        mostLoggedIngredientString =
            "${sortedIngredients.first.key} (${sortedIngredients.first.value} times)";
      }

      if (moodScores.isEmpty && ingredientCounts.isEmpty) {
        return {'Average Mood': 'No data', 'Most Logged Ingredient': 'No data'};
      }

      return {
        'Average Mood': avgMoodString,
        'Most Logged Ingredient': mostLoggedIngredientString,
      };
    } catch (e) {
      print('Error fetching statistics data: $e');
      return {'Average Mood': 'Error', 'Most Logged Ingredient': 'Error'};
    }
  }

  Future<List<FlSpot>> getIngredientDiversityData(String timeframe) async {
    final DateTime startDate = _getStartDate(timeframe);
    final DateTime endDate = DateTime.now();
    Map<double, Set<String>> diversityData =
        {}; // Key: time unit (day, week), Value: Set of unique ingredients

    try {
      final mealsSnapshot = await _meals
          .doc(_uid)
          .collection('daily_entries')
          .where('date',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
              isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('date')
          .get();

      if (mealsSnapshot.docs.isEmpty) {
        return [];
      }

      if (_recipesList.isEmpty) await loadRecipes();
      Map<String, Recipe> recipeMap = {for (var r in _recipesList) r.id: r};

      for (var mealDoc in mealsSnapshot.docs) {
        final mealData = mealDoc.data();
        final date = (mealData['date'] as Timestamp).toDate();
        final dailyMeals = mealData['meals'] as List<dynamic>;

        double timeKey;
        switch (timeframe) {
          case 'weekly': // Group by day of the week
            timeKey = date.weekday.toDouble();
            break;
          case 'monthly': // Group by week of the month
            timeKey = (date.day / 7).ceil().toDouble();
            break;
          case 'quarterly': // Group by month of the quarter
            timeKey = date.month.toDouble(); // Simplified: month number
            break;
          case 'yearly': // Group by month of the year
            timeKey = date.month.toDouble();
            break;
          default:
            timeKey = date.difference(startDate).inDays.toDouble();
        }

        diversityData.putIfAbsent(timeKey, () => <String>{});

        for (var meal in dailyMeals) {
          final recipeIds = (meal['recipes'] as List<dynamic>).cast<String>();
          for (String recipeId in recipeIds) {
            Recipe? recipe = recipeMap[recipeId];
            if (recipe != null && recipe.title != 'Apple') {
              // Assuming recipe.title is the ingredient
              diversityData[timeKey]!.add(recipe.title);
            }
          }
        }
      }

      if (diversityData.isEmpty) {
        return [];
      }

      List<FlSpot> spots = diversityData.entries
          .map((entry) => FlSpot(entry.key, entry.value.length.toDouble()))
          .toList();

      // Sort spots by timeKey for chronological order in the chart
      spots.sort((a, b) => a.x.compareTo(b.x));

      return spots;
    } catch (e) {
      print('Error fetching ingredient diversity data: $e');
      return [];
    }
  }

  Future<int> getUserLoggingStreak() async {
    try {
      // Fetch mood entries, ordered by date descending to easily check recent days
      final moodEntriesSnapshot = await _mood
          .doc(_uid)
          .collection('daily_entries')
          .orderBy('date', descending: true)
          .get();

      if (moodEntriesSnapshot.docs.isEmpty) {
        return 0; // No entries, no streak
      }

      List<DateTime> entryDates = [];
      for (var doc in moodEntriesSnapshot.docs) {
        final data = doc.data();
        // Ensure 'date' field exists and is a Timestamp
        if (data.containsKey('date') && data['date'] is Timestamp) {
          final date = (data['date'] as Timestamp).toDate();
          // Check if any mood was actually logged (score != -1)
          final moods = data['moods'] as List<dynamic>;
          bool hasActualEntry = moods.any((mood) => mood['score'] != -1);
          if (hasActualEntry) {
            entryDates.add(DateTime(
                date.year, date.month, date.day)); // Normalize to ignore time
          }
        }
      }

      if (entryDates.isEmpty) return 0; // No actual mood entries logged

      // Remove duplicate dates, in case multiple entries on the same day
      entryDates = entryDates.toSet().toList();
      // Sort again just in case normalization or set conversion changed order (though unlikely for descending query)
      entryDates.sort((a, b) => b.compareTo(a));

      int streak = 0;
      DateTime today = DateTime.now();
      DateTime todayNormalized = DateTime(today.year, today.month, today.day);
      DateTime yesterdayNormalized =
          DateTime(today.year, today.month, today.day - 1);

      // Check if the most recent entry is today or yesterday
      if (entryDates.first == todayNormalized ||
          entryDates.first == yesterdayNormalized) {
        streak = 1;
        DateTime expectedDate = DateTime(entryDates.first.year,
            entryDates.first.month, entryDates.first.day - 1);
        for (int i = 1; i < entryDates.length; i++) {
          if (entryDates[i] == expectedDate) {
            streak++;
            expectedDate = DateTime(
                expectedDate.year, expectedDate.month, expectedDate.day - 1);
          } else {
            break; // Streak broken
          }
        }
      } else {
        // Last entry was not today or yesterday, streak is 0
        return 0;
      }

      return streak;
    } catch (e) {
      print('Error calculating user logging streak: $e');
      return 0; // Return 0 on error
    }
  }

  Future<List<String>> getPopularIngredients({int limit = 8}) async {
    try {
      // Ensure recipes are loaded into _recipesList
      if (_recipesList.isEmpty) {
        await loadRecipes();
      }

      if (_recipesList.isEmpty) {
        return []; // No recipes for the user
      }

      // Using recipe titles as ingredients, excluding "Apple"
      List<String> ingredientNames = _recipesList
          .where((recipe) =>
              recipe.title.toLowerCase() != 'apple') // Filter out 'Apple'
          .map((recipe) => recipe.title)
          .toSet() // Get unique names
          .toList();

      // For this version, we don't have frequency, so "popular" is just a subset of unique ingredients.
      // If actual frequency is needed later, meal logs would need to be processed.

      if (ingredientNames.length > limit) {
        return ingredientNames.sublist(0, limit);
      }
      return ingredientNames;
    } catch (e) {
      print('Error fetching popular ingredients: $e');
      return [];
    }
  }
}
