```dart
// test/pages/customization/survey_page_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart'; // For mocking User
import 'package:health_app_v1/service/connect_db.dart';
import 'package:health_app_v1/pages/customization/survey_page.dart';
// Import other necessary models or providers if SurveyPage depends on them, e.g., UserSettings

// --- Mock Classes ---

// Mock FirebaseAuth
class MockFirebaseAuth extends Mock implements FirebaseAuth {
  @override
  User? get currentUser => MockUser(); // Provide a mock user
}

class MockUser extends Mock implements User {
  @override
  String get uid => 'test_user_id'; // Provide a dummy UID
  // Mock other User properties if needed by SurveyPage
}

// Mock ConnectDb
class MockConnectDb extends Mock implements ConnectDb {
  // You might need to override specific methods used by SurveyPage
  // For example, if SurveyPage calls loadRecipes or loadSettings on init,
  // you might need to provide default behavior for those too.
  // For now, focusing on getSurveyData and saveSurveyData.

  @override
  Future<Map<String, dynamic>?> getSurveyData(String userId) async {
    // This will be overridden by `when(...).thenAnswer(...)` in individual tests
    return super.noSuchMethod(
      Invocation.method(#getSurveyData, [userId]),
      returnValue: Future.value(null),
      returnValueForMissingStub: Future.value(null),
    );
  }

  @override
  Future<void> saveSurveyData(String userId, Map<String, dynamic> surveyData) async {
    // This will be overridden by `when(...).thenAnswer(...)` in individual tests
    // It can also be used with `verify(...).calledWith(...)`
    return super.noSuchMethod(
      Invocation.method(#saveSurveyData, [userId, surveyData]),
      returnValue: Future.value(null),
      returnValueForMissingStub: Future.value(null),
    );
  }

  // If SurveyPage calls other methods like loadSettings or initializeSettings,
  // provide basic stubs for them as well to avoid errors during widget pumping.
  @override
  Future<void> loadSettings() async {
     return super.noSuchMethod(
      Invocation.method(#loadSettings, []),
      returnValue: Future.value(null),
      returnValueForMissingStub: Future.value(null),
    );
  }
}

// Mock UserSettings or any other providers if SurveyPage uses them via context.watch/read
// class MockUserSettings extends Mock implements UserSettings {}

void main() {
  late MockFirebaseAuth mockFirebaseAuth;
  late MockConnectDb mockConnectDb;
  // late MockUserSettings mockUserSettings;

  setUp(() {
    mockFirebaseAuth = MockFirebaseAuth();
    mockConnectDb = MockConnectDb();
    // mockUserSettings = MockUserSettings();

    // Provide default stubs for methods called during initState or build
    // that are not the primary focus of every test but might cause null errors.
    when(mockConnectDb.getSurveyData(any)).thenAnswer((_) async => null); // Default: no survey data
    when(mockConnectDb.loadSettings()).thenAnswer((_) async {}); // Default: loadSettings does nothing
    // Add other default stubs as necessary based on SurveyPage's dependencies
  });

  // Helper function to pump the SurveyPage widget with necessary providers
  Future<void> pumpSurveyPage(WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<ConnectDb>.value(value: mockConnectDb),
          // Add other necessary mock providers here
          // ChangeNotifierProvider<UserSettings>.value(value: mockUserSettings),
        ],
        child: MaterialApp(
          home: SurveyPage(),
        ),
      ),
    );
    // SurveyPage uses a FutureBuilder for _loadSurveyData which might involve
    // multiple frames. Pumping and settling ensures the UI reflects the loaded state.
    await tester.pumpAndSettle();
  }

  group('SurveyPage Widget Tests - Birth Year/Month Integration', () {
    // --- Test Cases ---

    testWidgets('1. Initial UI State (No Pre-filled Data)', (WidgetTester tester) async {
      // Description: Verify that the birth year and month dropdowns are present,
      // and the age input field is absent.
      // Setup: Default mockConnectDb.getSurveyData returns null.

      // Actions:
      await pumpSurveyPage(tester);

      // Assertions:
      expect(find.text('Birth Year'), findsOneWidget, reason: "Birth Year dropdown label should be present");
      expect(find.text('Birth Month'), findsOneWidget, reason: "Birth Month dropdown label should be present");
      expect(find.byType(DropdownButtonFormField<int>), findsNWidgets(2), reason: "Should find two DropdownButtonFormFields for year and month");

      expect(find.text('Age'), findsNothing, reason: "Age TextFormField should be absent");

      // Verify dropdowns are initially empty (or show hint text if implemented)
      // This requires checking the 'value' property of the DropdownButtonFormField.
      // Example: (assuming 'value' is null when nothing is selected)
      final yearDropdown = tester.widget<DropdownButtonFormField<int>>(find.widgetWithText(DropdownButtonFormField<int>, 'Birth Year'));
      expect(yearDropdown.value, isNull, reason: "Birth Year dropdown should initially have no value");

      final monthDropdown = tester.widget<DropdownButtonFormField<int>>(find.widgetWithText(DropdownButtonFormField<int>, 'Birth Month'));
      expect(monthDropdown.value, isNull, reason: "Birth Month dropdown should initially have no value");
    });

    testWidgets('2. Data Loading (With BirthYear/Month)', (WidgetTester tester) async {
      // Description: Verify that if getSurveyData returns data with birthYear and birthMonth,
      // these values are pre-filled in the dropdowns.

      // Setup:
      when(mockConnectDb.getSurveyData(any)).thenAnswer((_) async => {
        'birthYear': 1990,
        'birthMonth': 5,
        // Add other fields that SurveyPage expects to avoid null errors during load
        'sex': 'Male',
        'height': '180',
        'weight': '75',
        'activityLevel': 'Moderately Active',
        'sleepHours': '8',
        'dietType': 'Omnivore',
        'allergies': [],
        'dislikedFoods': '',
        'healthConditions': '',
        'goal': 'Increase energy',
        'challenges': [],
        'morningMood': 3,
        'afternoonMood': 3,
        'eveningMood': 3,
        'foodMoodConnection': '',
        'consentGiven': false,
      });

      // Actions:
      await pumpSurveyPage(tester);

      // Assertions:
      // Find the DropdownButtonFormField by its label and check its value.
      // Note: The displayed text in the dropdown might be different from the value if `items` transform it.
      // Here, we assume the value itself is what we're checking.
      final yearDropdown = tester.widget<DropdownButtonFormField<int>>(find.widgetWithText(DropdownButtonFormField<int>, 'Birth Year'));
      expect(yearDropdown.value, 1990, reason: "Birth Year dropdown should be pre-filled with 1990");

      final monthDropdown = tester.widget<DropdownButtonFormField<int>>(find.widgetWithText(DropdownButtonFormField<int>, 'Birth Month'));
      expect(monthDropdown.value, 5, reason: "Birth Month dropdown should be pre-filled with 5");
    });

    testWidgets('3. Data Loading (With old "age" field, no birthdate)', (WidgetTester tester) async {
      // Description: Verify that if getSurveyData returns data with only the old age field,
      // the birth year/month dropdowns remain unselected.

      // Setup:
       when(mockConnectDb.getSurveyData(any)).thenAnswer((_) async => {
        'age': 30, // Old field
        // Add other fields that SurveyPage expects
        'sex': 'Female',
        'height': '160',
        'weight': '60',
        'activityLevel': 'Sedentary',
        'sleepHours': '7',
         'dietType': 'Omnivore',
        'allergies': [],
        'dislikedFoods': '',
        'healthConditions': '',
        'goal': 'Increase energy',
        'challenges': [],
        'morningMood': 3,
        'afternoonMood': 3,
        'eveningMood': 3,
        'foodMoodConnection': '',
        'consentGiven': false,
      });

      // Actions:
      await pumpSurveyPage(tester);

      // Assertions:
      final yearDropdown = tester.widget<DropdownButtonFormField<int>>(find.widgetWithText(DropdownButtonFormField<int>, 'Birth Year'));
      expect(yearDropdown.value, isNull, reason: "Birth Year dropdown should be null when loaded with old 'age' data");

      final monthDropdown = tester.widget<DropdownButtonFormField<int>>(find.widgetWithText(DropdownButtonFormField<int>, 'Birth Month'));
      expect(monthDropdown.value, isNull, reason: "Birth Month dropdown should be null when loaded with old 'age' data");
    });

    testWidgets('4. Validation - Year Missing', (WidgetTester tester) async {
      // Description: Test that validation fails if birth year is not selected but month is.

      // Actions:
      await pumpSurveyPage(tester);

      // Select a month. Need to find the specific DropdownButtonFormField.
      // Tapping the dropdown itself, then the item.
      await tester.tap(find.widgetWithText(DropdownButtonFormField<int>, 'Birth Month'));
      await tester.pumpAndSettle(); // Allow dropdown items to appear
      await tester.tap(find.text('5').last); // Assuming '5' is visible text for month 5
      await tester.pumpAndSettle();


      // Attempt to navigate to the next page (triggering validation)
      // This assumes there's a 'Next' button and we are on the first page (_currentPage = 0)
      // Ensure other mandatory fields on page 0 are filled if any, or that validation is isolated.
      // For simplicity, let's assume birth year/month are the only relevant fields for this test.
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle(); // Let validation messages appear

      // Assertions:
      expect(find.text('Please select your birth year.'), findsOneWidget, reason: "Validation error for missing birth year should be shown");
      expect(find.text('Please select your birth month.'), findsNothing, reason: "No validation error for birth month as it's selected");
    });

    testWidgets('5. Validation - Month Missing', (WidgetTester tester) async {
      // Description: Test that validation fails if birth month is not selected but year is.

      // Actions:
      await pumpSurveyPage(tester);

      await tester.tap(find.widgetWithText(DropdownButtonFormField<int>, 'Birth Year'));
      await tester.pumpAndSettle();
      final int currentYear = DateTime.now().year;
      await tester.tap(find.text(currentYear.toString()).last); // Select current year
      await tester.pumpAndSettle();

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Assertions:
      expect(find.text('Please select your birth month.'), findsOneWidget, reason: "Validation error for missing birth month should be shown");
      expect(find.text('Please select your birth year.'), findsNothing, reason: "No validation error for birth year as it's selected");
    });

    testWidgets('6. Validation - Both Selected', (WidgetTester tester) async {
      // Description: Test that validation passes if both birth year and month are selected.

      // Actions:
      await pumpSurveyPage(tester);

      // Select Year
      await tester.tap(find.widgetWithText(DropdownButtonFormField<int>, 'Birth Year'));
      await tester.pumpAndSettle();
      final int currentYear = DateTime.now().year;
      await tester.tap(find.text(currentYear.toString()).last);
      await tester.pumpAndSettle();

      // Select Month
      await tester.tap(find.widgetWithText(DropdownButtonFormField<int>, 'Birth Month'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('5').last);
      await tester.pumpAndSettle();

      // Fill other mandatory fields on the first page for validation to pass for the whole form step
      // Example: Height, Weight, Activity Level, Sleep Hours
      await tester.enterText(find.widgetWithText(TextFormField, 'Height (in cm)'), '170');
      await tester.enterText(find.widgetWithText(TextFormField, 'Weight (in kg)'), '70');

      await tester.tap(find.widgetWithText(DropdownButtonFormField<String>, 'Activity Level'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sedentary').last); // Choose one option
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextFormField, 'Average hours of sleep'), '8');

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle(); // Allow navigation or UI change

      // Assertions:
      expect(find.text('Please select your birth year.'), findsNothing);
      expect(find.text('Please select your birth month.'), findsNothing);

      // Further assertion: Check if it navigated.
      // This depends on the structure. If it navigates, the title of the next step might appear.
      // For example, if next step is 'Tell us about your diet':
      // expect(find.text('Tell us about your diet'), findsOneWidget, reason: "Should navigate to the next step if validation passes");
      // Or, if it's the last page, it might attempt to submit.
      // For this test, simply checking no error messages is sufficient for the birth date fields.
    });

    testWidgets('7. Data Submission (Simplified for birth date fields)', (WidgetTester tester) async {
      // Description: Verify that _submitSurvey calls saveSurveyData with the correct
      // birthYear and birthMonth, and without age. This test will focus on the data
      // part and manually advance pages.

      // Setup:
      // Mock getSurveyData to return minimal data or null for a fresh survey.
      when(mockConnectDb.getSurveyData(any)).thenAnswer((_) async => {
        // Pre-fill mandatory fields for other pages to simplify navigation
        'sex': 'Male', 'height': '180', 'weight': '75', 'activityLevel': 'Moderately Active', 'sleepHours': '8',
        'dietType': 'Omnivore', 'allergies': <String>[], 'dislikedFoods': '', 'healthConditions': '',
        'goal': 'Other', 'otherGoalText': 'Test Goal', // Assuming 'Other' is selected for goal
        'challenges': <String>[],
        'morningMood': 3, 'afternoonMood': 3, 'eveningMood': 3, 'foodMoodConnection': 'Test connection',
        'consentGiven': true, // Crucial for submission
      });

      ArgumentCaptor<Map<String, dynamic>> surveyDataCaptor = ArgumentCaptor<Map<String, dynamic>>();
      when(mockConnectDb.saveSurveyData(any, captureAny)).thenAnswer((realInvocation) async {
        surveyDataCaptor.capture(realInvocation.positionalArguments[1] as Map<String,dynamic>);
      });


      await pumpSurveyPage(tester);

      // --- Page 1: Personal Data ---
      // Select Year
      await tester.tap(find.widgetWithText(DropdownButtonFormField<int>, 'Birth Year'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('1990').last); // Select 1990
      await tester.pumpAndSettle();

      // Select Month
      await tester.tap(find.widgetWithText(DropdownButtonFormField<int>, 'Birth Month'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('5').last); // Select May (5)
      await tester.pumpAndSettle();

      // Fill other mandatory fields on page 1
      await tester.enterText(find.widgetWithText(TextFormField, 'Height (in cm)'), '180');
      await tester.enterText(find.widgetWithText(TextFormField, 'Weight (in kg)'), '75');
      await tester.tap(find.widgetWithText(DropdownButtonFormField<String>, 'Activity Level'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Moderately Active').last);
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextFormField, 'Average hours of sleep'), '8');
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();


      // --- Page 2: Dietary Preferences ---
      // Fill mandatory fields
      await tester.tap(find.widgetWithText(DropdownButtonFormField<String>, 'Diet Type'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Omnivore').last);
      await tester.pumpAndSettle();
      // Assuming no allergies are selected, or handle 'Other' if it's mandatory
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // --- Page 3: Health Goals ---
      // Select a goal (e.g. 'Other' and fill text)
      await tester.tap(find.text('Other').first); // Ensure it's the RadioListTile
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextFormField, 'Please specify your goal'), 'Test Specific Goal');
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // --- Page 4: Current Challenges ---
      // Assuming no challenges are selected, or handle 'Other' if it's mandatory
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // --- Page 5: Emotional Baseline & Consent ---
      // Fill mandatory fields
      await tester.enterText(find.widgetWithText(TextFormField, 'Do you suspect any connection between your food and your mood?'), 'Some connection');

      // Give consent
      final consentCheckbox = find.byType(CheckboxListTile);
      expect(consentCheckbox, findsOneWidget);
      await tester.tap(consentCheckbox);
      await tester.pumpAndSettle();

      // Tap Submit
      await tester.tap(find.text('Submit'));
      await tester.pumpAndSettle(); // Allow submission process

      // Assertions:
      verify(mockConnectDb.saveSurveyData(any, any)).called(1);

      final capturedData = surveyDataCaptor.value;
      expect(capturedData['birthYear'], 1990, reason: "Submitted data should contain birthYear: 1990");
      expect(capturedData['birthMonth'], 5, reason: "Submitted data should contain birthMonth: 5");
      expect(capturedData.containsKey('age'), isFalse, reason: "Submitted data should not contain an 'age' key");

      // Optionally, verify other fields to ensure they are also present
      expect(capturedData['height'], '180');
      expect(capturedData['consentGiven'], isTrue);
    });

  });
}

```
