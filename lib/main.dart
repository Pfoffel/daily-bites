import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:health_app_v1/models/current_date.dart';
import 'package:health_app_v1/models/mood.dart';
import 'package:health_app_v1/models/user_settings.dart';
import 'package:health_app_v1/models/recipe_list.dart';
import 'package:health_app_v1/pages/customization/survey_page.dart';
import 'package:health_app_v1/pages/meal/list_recipes_page.dart';
import 'package:health_app_v1/pages/auth/main_page.dart';
import 'package:health_app_v1/pages/drawer/notification_page.dart';
import 'package:health_app_v1/pages/drawer/calendar_page.dart';
import 'package:health_app_v1/pages/drawer/home_page.dart';
import 'package:health_app_v1/pages/meal/macro_info_page.dart';
import 'package:health_app_v1/pages/meal/recipe_insights_page.dart';
import 'package:health_app_v1/pages/drawer/settings_page.dart';
import 'package:health_app_v1/pages/drawer/streak_page.dart';
import 'package:health_app_v1/pages/drawer/trends_page.dart';
import 'package:health_app_v1/pages/mood/mood_page.dart';
import 'package:health_app_v1/service/connect_db.dart';
import 'package:health_app_v1/service/notifications_service.dart';
import 'package:health_app_v1/service/recipe_service.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  tz.initializeTimeZones();
  await NotificationsService.init();
  await Firebase.initializeApp();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => CurrentDate()),
        ChangeNotifierProvider(create: (context) => RecipeList()),
        ChangeNotifierProvider(create: (context) => ConnectDb()),
        ChangeNotifierProvider(create: (context) => Mood()),
        ChangeNotifierProvider(create: (context) => UserSettings()),
        Provider(create: (context) => RecipeService()),
      ],
      child: const MainApp(),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MainPage(),
      routes: {
        '/home_page': (context) => const HomePage(),
        '/notification_page': (context) => const NotificationPage(),
        '/calendar_page': (context) => const CalendarPage(),
        '/trends_page': (context) => const TrendsPage(),
        '/settings_page': (context) => const SettingsPage(),
        '/streak_page': (context) => const StreakPage(),
        '/macro_info_page': (context) => const MacroInfoPage(),
        '/list_recipe_page': (context) => const ListRecipesPage(),
        '/recipe_insights_page': (context) => const RecipeInsightsPage(),
        '/main_page': (context) => const MainPage(),
        '/mood_page': (context) => const MoodPage(),
        '/survey_page': (context) => const SurveyPage(),
      },
      theme: ThemeData(
        useMaterial3: true,
        colorScheme:
            ColorScheme.fromSeed(seedColor: Color.fromARGB(255, 45, 190, 120)),
        textTheme: Theme.of(context).textTheme.copyWith(
              displayLarge:
                  GoogleFonts.koulen(fontSize: 65, color: Colors.white),
              displayMedium:
                  GoogleFonts.koulen(fontSize: 55, color: Colors.white),
              displaySmall:
                  GoogleFonts.koulen(fontSize: 44, color: Colors.white),
              labelLarge: GoogleFonts.koulen(fontSize: 40, color: Colors.white),
              labelMedium:
                  GoogleFonts.koulen(fontSize: 24, color: Colors.white),
              labelSmall: GoogleFonts.koulen(fontSize: 18, color: Colors.white),
              bodyLarge: GoogleFonts.roboto(fontSize: 16, color: Colors.white),
              bodyMedium: GoogleFonts.roboto(fontSize: 14, color: Colors.white),
              bodySmall: GoogleFonts.roboto(fontSize: 12, color: Colors.white),
              headlineSmall:
                  GoogleFonts.roboto(fontSize: 18, color: Colors.white),
              headlineMedium:
                  GoogleFonts.roboto(fontSize: 22, color: Colors.white),
              headlineLarge:
                  GoogleFonts.roboto(fontSize: 26, color: Colors.white),
            ),
        iconTheme: const IconThemeData(color: Colors.white),
        appBarTheme: const AppBarTheme(
          iconTheme: IconThemeData(color: Color.fromARGB(255, 45, 190, 120)),
          toolbarHeight: 70,
          backgroundColor: Color.fromARGB(255, 9, 37, 29),
        ),
        drawerTheme: DrawerThemeData(
            backgroundColor: const Color.fromARGB(255, 6, 23, 18)),
        scaffoldBackgroundColor: const Color.fromARGB(255, 6, 23, 18),
        listTileTheme:
            ListTileThemeData(iconColor: Color.fromARGB(255, 45, 190, 120)),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ButtonStyle(
              backgroundColor:
                  WidgetStatePropertyAll(Color.fromARGB(255, 45, 190, 120)),
              padding:
                  WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 15))),
        ),
        dialogTheme: DialogTheme(
          backgroundColor: Color.fromARGB(255, 9, 37, 29),
          titleTextStyle: GoogleFonts.koulen(fontSize: 24, color: Colors.white),
        ),
        switchTheme: SwitchThemeData(
          trackColor:
              WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
            if (states.contains(WidgetState.disabled)) {
              return Colors.grey;
            }
            if (states.contains(WidgetState.selected)) {
              return Color.fromARGB(255, 45, 190, 120);
            }
            return Color.fromARGB(255, 9, 37, 29);
          }),
        ),
      ),
    );
  }
}
