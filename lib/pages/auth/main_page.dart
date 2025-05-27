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

  Future<void> _initializeData(
      ConnectDb db, RecipeList rl, Mood m, UserSettings settings) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception("User is not logged in.");
    }

    final String uid = user.uid;
    final String currentDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    db.updateUID(uid);

    DocumentSnapshot<Map<String, dynamic>> snapshotRecipe =
        await FirebaseFirestore.instance.collection('recipes').doc(uid).get();

    if (!snapshotRecipe.exists || snapshotRecipe.data()?.isEmpty == true) {
      await db.initializeRecipes(uid);
      snapshotRecipe =
          await FirebaseFirestore.instance.collection('recipes').doc(uid).get();
    }

    await db.loadRecipes();

    DocumentSnapshot<Map<String, dynamic>> snapshotMeals =
        await FirebaseFirestore.instance.collection('meals').doc(uid).get();

    if (!snapshotMeals.exists || snapshotMeals.data()?.isEmpty == true) {
      await db.initializeMeals(currentDate, uid);
      snapshotMeals =
          await FirebaseFirestore.instance.collection('meals').doc(uid).get();
    }

    if (!snapshotMeals.data()!.containsKey(currentDate)) {
      await db.updateMeal({currentDate: db.defaultMeals});
      snapshotMeals =
          await FirebaseFirestore.instance.collection('meals').doc(uid).get();
    }

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

    DocumentSnapshot<Map<String, dynamic>> snapshotMood =
        await FirebaseFirestore.instance.collection('mood').doc(uid).get();

    if (!snapshotMood.exists || snapshotMood.data()?.isEmpty == true) {
      await db.initializeMood(currentDate, uid);
      snapshotMood =
          await FirebaseFirestore.instance.collection('mood').doc(uid).get();
    }

    if (!snapshotMood.data()!.containsKey(currentDate)) {
      await db.updateMood({currentDate: db.defaultMoods});
      snapshotMood =
          await FirebaseFirestore.instance.collection('mood').doc(uid).get();
    }

    await db.loadMoods();

    final List mealsDay = snapshotMeals[currentDate];
    rl.initializeRecipes(db.recipesList, mealsDay);
    m.initializeMood(db.moodList, currentDate);
    settings.initializeSettings(db.timeMap, db.goalsMap);
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

            return FutureBuilder(
              future: _initializeData(db, recipeList, mood, settings),
              builder: (context, futureSnapshot) {
                if (futureSnapshot.connectionState == ConnectionState.waiting) {
                  return Center(
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

                return HomePage();
              },
            );
          } else {
            return AuthPage();
          }
        },
      ),
    );
  }
}
