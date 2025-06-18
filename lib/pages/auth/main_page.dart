import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:health_app_v1/models/mood.dart';
import 'package:health_app_v1/models/user_settings.dart';
import 'package:health_app_v1/models/recipe_list.dart';
import 'package:health_app_v1/pages/auth/auth_page.dart';
import 'package:health_app_v1/pages/drawer/home_page.dart';
import 'package:health_app_v1/service/connect_db.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  Future<bool> _initializeData(BuildContext context, ConnectDb db,
      RecipeList rl, Mood m, UserSettings settings) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception("User is not logged in.");
    }

    final String uid = user.uid;
    final String currentDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

    await db.migrateUserDataToSubcollections(uid);
    db.updateUID(uid, currentDate);

    DocumentSnapshot<Map<String, dynamic>> snapshotRecipe =
        await FirebaseFirestore.instance.collection('recipes').doc(uid).get();

    if (!snapshotRecipe.exists || snapshotRecipe.data()?.isEmpty == true) {
      await db.initializeRecipes(uid);
      snapshotRecipe =
          await FirebaseFirestore.instance.collection('recipes').doc(uid).get();
    }

    await db.loadRecipes();

    DocumentSnapshot<Map<String, dynamic>> snapshotCurrentDayMeals = await db
        .mealsCollection
        .doc(uid)
        .collection('daily_entries')
        .doc(currentDate)
        .get();

    if (!snapshotCurrentDayMeals.exists ||
        snapshotCurrentDayMeals.data()?.isEmpty == true) {
      await db.initializeMeals(currentDate, uid); // Create today's entry
      snapshotCurrentDayMeals = await db.mealsCollection
          .doc(uid)
          .collection('daily_entries')
          .doc(currentDate)
          .get();
    }
    final List mealsDay = (snapshotCurrentDayMeals.data()!['meals']
        as List); // Access 'meals' field

    DocumentSnapshot<Map<String, dynamic>> snapshotSettings =
        await FirebaseFirestore.instance.collection('settings').doc(uid).get();

    if (!snapshotSettings.exists || snapshotSettings.data()?.isEmpty == true) {
      await db.initializeSettings(uid);
      snapshotSettings = await FirebaseFirestore.instance
          .collection('settings')
          .doc(uid)
          .get();
    }

    if (!snapshotSettings.data()!.containsKey('settings')) {
      await db.initializeSettings(uid);
      snapshotSettings = await FirebaseFirestore.instance
          .collection('settings')
          .doc(uid)
          .get();
    }

    await db.loadSettings();

    DocumentSnapshot<Map<String, dynamic>> snapshotCurrentDayMood = await db
        .moodCollection
        .doc(uid)
        .collection('daily_entries')
        .doc(currentDate)
        .get();

    if (!snapshotCurrentDayMood.exists ||
        snapshotCurrentDayMood.data()?.isEmpty == true) {
      await db.initializeMood(currentDate, uid); // Create today's entry
      snapshotCurrentDayMood = await db.moodCollection
          .doc(uid)
          .collection('daily_entries')
          .doc(currentDate)
          .get();
    }
    final List moodsDay = (snapshotCurrentDayMood.data()!['moods']
        as List); // Access 'moods' field
    await db.loadMoods(currentDate); // Load into ConnectDb's _moodList

    rl.initializeRecipes(db.recipesList, mealsDay);
    m.initializeMood(moodsDay, currentDate);
    settings.initializeSettings(db.timeMap, db.goalsMap);

    // Check survey completion status after settings are loaded and initialized
    // db.goalsMap is populated by db.loadSettings() which is called above.
    final surveyCompleted = db.surveyCompleted;
    if (surveyCompleted == false) {
      if (context.mounted) {
        Navigator.of(context).pushReplacementNamed('/survey_page');
        return true; // Indicated navigation to survey page occurred
      }
    }
    return false; // Survey already completed, no navigation to survey page
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
                child: CircularProgressIndicator(
              color: Color.fromARGB(255, 45, 190, 120),
            ));
          }

          if (snapshot.hasData) {
            final ConnectDb db = context.read<ConnectDb>();
            final RecipeList recipeList = context.read<RecipeList>();
            final Mood mood = context.read<Mood>();
            final UserSettings settings = context.read<UserSettings>();

            return FutureBuilder<bool>(
              future: _initializeData(context, db, recipeList, mood, settings),
              builder: (context, futureSnapshot) {
                if (futureSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color.fromARGB(255, 45, 190, 120),
                    ),
                  );
                }

                if (futureSnapshot.hasError) {
                  return Center(
                      child: Text(
                          "Error loading data: ${futureSnapshot.error.toString()}"));
                }

                final bool didNavigateToSurvey = futureSnapshot.data ?? false;

                if (didNavigateToSurvey) {
                  // Navigation to survey page was handled, show an empty container or placeholder
                  // until the survey page takes over.
                  return Container(); // Or SizedBox.shrink();
                } else {
                  // Survey was completed or not needed, proceed to HomePage
                  return HomePage();
                }
              },
            );
          } else {
            return const AuthPage();
          }
        },
      ),
    );
  }
}
