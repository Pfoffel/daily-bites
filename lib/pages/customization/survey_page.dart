import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:health_app_v1/service/connect_db.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart'; // For context.read

class SurveyPage extends StatefulWidget {
  const SurveyPage({super.key});

  @override
  SurveyPageState createState() => SurveyPageState();
}

class SurveyPageState extends State<SurveyPage> {
  // Create a list of GlobalKeys, one for each page's Form
  final List<GlobalKey<FormState>> _formKeys = List.generate(
    5, // Assuming 5 pages (0 to 4) based on your PageView children
    (_) => GlobalKey<FormState>(),
  );

  final PageController _pageController = PageController();
  double _progress = 0.0;
  int _currentPage = 0;

  // Store survey answers
  final Map<String, dynamic> _surveyAnswers = {};

  // Controllers for text fields
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _sleepHoursController = TextEditingController();
  final TextEditingController _otherGoalController = TextEditingController();
  final TextEditingController _otherChallengeController =
      TextEditingController();
  final TextEditingController _foodMoodConnectionController =
      TextEditingController();
  final TextEditingController _dislikedFoodsController =
      TextEditingController();
  final TextEditingController _healthConditionsController =
      TextEditingController();
  final TextEditingController _otherAllergyController = TextEditingController();

  // Loading state
  bool _isLoadingData = true;
  // Map<String, dynamic>? _loadedSurveyData; // Optional: Can set controllers directly

  // Selected values for dropdowns/radio buttons/checkboxes
  int? _selectedBirthYear;
  int? _selectedBirthMonth;
  String? _selectedSex;
  String? _selectedActivityLevel;
  String? _selectedDietType;
  final List<String> _selectedAllergies = [];
  String? _selectedGoal;
  final List<String> _selectedChallenges = [];
  int _morningMood = 3; // Default to middle value
  int _afternoonMood = 3;
  int _eveningMood = 3;
  bool _consentGiven = false;

  // Define the total number of pages
  final int _totalPages = 5;

  // Define the consistent dropdown background color
  final Color _dropdownBackgroundColor = const Color.fromARGB(255, 9, 37, 29);
  // Define a text style for dropdown items on a dark background
  final TextStyle _dropdownItemTextStyle = const TextStyle(color: Colors.white);

  @override
  void initState() {
    super.initState();
    // Initialize progress on load
    _updateProgress(_currentPage);
    _loadSurveyData(); // Load existing survey data
  }

  Future<void> _loadSurveyData() async {
    final String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      if (mounted) {
        setState(() {
          _isLoadingData = false;
        });
      }
      return;
    }

    final connectDb = context.read<ConnectDb>();
    final Map<String, dynamic>? data = await connectDb.getSurveyData(userId);

    if (data != null && mounted) {
      setState(() {
        // _ageController.text = data['age']?.toString() ?? ''; // Age will be handled by birth year/month
        _selectedBirthYear = data['birthYear'] as int?;
        _selectedBirthMonth = data['birthMonth'] as int?;
        _selectedSex = data['sex'] as String?;
        _heightController.text = data['height']?.toString() ?? '';
        _weightController.text = data['weight']?.toString() ?? '';
        _selectedActivityLevel = data['activityLevel'] as String?;
        _sleepHoursController.text = data['sleepHours']?.toString() ?? '';
        _selectedDietType = data['dietType'] as String?;

        // Load Allergies
        final List<String> tempAllergies = List<String>.from(data['allergies'] as List? ?? []);
        _selectedAllergies.clear();
        final List<String> predefinedAllergies = ['Gluten', 'Dairy', 'Nuts', 'Soy'];
        for (String allergy in tempAllergies) {
          if (predefinedAllergies.contains(allergy)) {
            _selectedAllergies.add(allergy);
          } else {
            _selectedAllergies.add('Other'); // Add 'Other' to the selection
            _otherAllergyController.text = allergy; // Set the text for the 'Other' field
          }
        }

        _dislikedFoodsController.text = data['dislikedFoods']?.toString() ?? '';
        _healthConditionsController.text = data['healthConditions']?.toString() ?? '';

        // Load Goal
        final String? goalData = data['goal'] as String?;
        final List<String> predefinedGoals = [
          'Improve digestion',
          'Increase energy',
          'Sleep better',
          'Lose/gain/maintain weight',
          'Understand food-mood link'
        ];
        if (goalData != null) {
          if (predefinedGoals.contains(goalData)) {
            _selectedGoal = goalData;
          } else {
            _selectedGoal = 'Other';
            _otherGoalController.text = goalData;
          }
        }

        // Load Challenges
        final List<dynamic> challengesData = data['challenges'] as List<dynamic>? ?? [];
        _selectedChallenges.clear();
        final List<String> predefinedChallenges = [
          'Bloating',
          'Headaches',
          'Fatigue',
          'Skin issues',
          'Mood swings',
          'Cravings',
          'Poor sleep'
        ];
        for (var challengeItem in challengesData) {
          final String challenge = challengeItem.toString();
          if (predefinedChallenges.contains(challenge)) {
            _selectedChallenges.add(challenge);
          } else {
             // If it's not a predefined one, it's the 'Other' text
            _selectedChallenges.add('Other');
            _otherChallengeController.text = challenge;
          }
        }

        _morningMood = (data['morningMood'] as num?)?.toInt() ?? 3;
        _afternoonMood = (data['afternoonMood'] as num?)?.toInt() ?? 3;
        _eveningMood = (data['eveningMood'] as num?)?.toInt() ?? 3;
        _foodMoodConnectionController.text = data['foodMoodConnection']?.toString() ?? '';
        _consentGiven = data['consentGiven'] as bool? ?? false;

        // Potentially update progress if on the last page and consent is given
        // or if navigation depends on loaded data, but _updateProgress is tied to page index.
      });
    }

    if (mounted) {
      setState(() {
        _isLoadingData = false;
      });
    }
  }

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    _sleepHoursController.dispose();
    _otherGoalController.dispose();
    _otherChallengeController.dispose();
    _foodMoodConnectionController.dispose();
    _dislikedFoodsController.dispose();
    _healthConditionsController.dispose();
    _otherAllergyController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    }
  }

  void _nextPage() {
    // *** Validation is triggered here before moving to the next page ***
    if (_formKeys[_currentPage].currentState!.validate()) {
      // If the current page is valid, proceed
      if (_currentPage < _totalPages - 1) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeIn,
        );
      } else {
        // On the last page, submit the survey
        _submitSurvey();
      }
    }
  }

  void _updateProgress(int page) {
    setState(() {
      _currentPage = page;
      _progress =
          (page + 1) / _totalPages; // Update progress based on current page
    });
  }

  Future<void> _submitSurvey() async {
    // *** Final validation for the last page is triggered here ***
    if (_formKeys[_currentPage].currentState!.validate()) {
      // Additional validation for non-TextFormField widgets if needed
      if (!_consentGiven) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please give consent to submit.')),
        );
        return;
      }

      // Collect all answers
      // _surveyAnswers['age'] = _ageController.text; // Age replaced by birth year/month
      _surveyAnswers['birthYear'] = _selectedBirthYear;
      _surveyAnswers['birthMonth'] = _selectedBirthMonth;
      _surveyAnswers['sex'] = _selectedSex;
      _surveyAnswers['height'] = _heightController.text;
      _surveyAnswers['weight'] = _weightController.text;
      _surveyAnswers['activityLevel'] = _selectedActivityLevel;
      _surveyAnswers['sleepHours'] = _sleepHoursController.text;
      _surveyAnswers['dietType'] = _selectedDietType;

      // Allergies processing
      List<String> allergiesToSave = List.from(_selectedAllergies);
      if (_selectedAllergies.contains('Other')) {
        if (_otherAllergyController.text.isNotEmpty) {
          allergiesToSave.remove('Other'); // Remove placeholder
          allergiesToSave.add(_otherAllergyController.text); // Add actual text
        }
        // If _otherAllergyController.text is empty but 'Other' is checked, 'Other' remains in allergiesToSave
      }
      _surveyAnswers['allergies'] = allergiesToSave;

      _surveyAnswers['dislikedFoods'] = _dislikedFoodsController.text;
      _surveyAnswers['healthConditions'] = _healthConditionsController.text;
      _surveyAnswers['goal'] =
          _selectedGoal == 'Other' ? _otherGoalController.text : _selectedGoal;
      _surveyAnswers['challenges'] = _selectedChallenges.contains('Other')
          ? [
              ..._selectedChallenges.where((element) => element != 'Other'),
              _otherChallengeController.text,
            ]
          : _selectedChallenges;
      _surveyAnswers['morningMood'] = _morningMood;
      _surveyAnswers['afternoonMood'] = _afternoonMood;
      _surveyAnswers['eveningMood'] = _eveningMood;
      _surveyAnswers['foodMoodConnection'] = _foodMoodConnectionController.text;
      _surveyAnswers['consentGiven'] = _consentGiven;

      // Process or save the answers
      print(_surveyAnswers);

      final String userId = FirebaseAuth.instance.currentUser!.uid;
      final connectDb = context.read<ConnectDb>();

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(child: CircularProgressIndicator());
        },
      );

      try {
        await connectDb.saveSurveyData(userId, _surveyAnswers);

        if (!mounted) return; // Check mounted before dismissing dialog or showing snackbar
        Navigator.of(context).pop(); // Dismiss loading indicator

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Survey submitted successfully!')),
        );

        final Object? args = ModalRoute.of(context)?.settings.arguments;
        bool fromSettings = false;
        if (args != null && args is Map && args['source'] == 'settings') {
          fromSettings = true;
        }

        if (fromSettings) {
          if (mounted) Navigator.of(context).pop(); // Pop survey page to return to settings
        } else {
          // Existing navigation for new users
          if (mounted) Navigator.pushNamedAndRemoveUntil(context, '/home_page', (route) => false);
        }

      } catch (e) {
        if (!mounted) return; // Check mounted before dismissing dialog or showing snackbar
        Navigator.of(context).pop(); // Dismiss loading indicator

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting survey: $e')),
        );
        print('Error submitting survey: $e');
      }
    }
  }

  // Helper widget for the "Back" button
  Widget _buildPreviousButton() {
    // Only show the back button if not on the first page
    if (_currentPage > 0) {
      return Padding(
        padding: const EdgeInsets.only(right: 8.0),
        child: ElevatedButton(
          onPressed: _previousPage,
          child: Text('Back', style: Theme.of(context).textTheme.headlineSmall),
        ),
      );
    } else {
      return const SizedBox.shrink(); // Hide the button on the first page
    }
  }

  // Helper widget for the "Next" or "Submit" button
  Widget _buildNextButton() {
    // Change button text based on the current page
    final String buttonText =
        (_currentPage == _totalPages - 1) ? 'Submit' : 'Next';
    // Change button style for the final submit button if needed
    final TextStyle buttonTextStyle = (_currentPage == _totalPages - 1)
        ? Theme.of(context)
            .textTheme
            .headlineLarge! // Assuming a larger style for submit
        : Theme.of(context).textTheme.headlineSmall!;

    return ElevatedButton(
      onPressed: (_currentPage == _totalPages - 1) ? _submitSurvey : _nextPage,
      child: Text(buttonText, style: buttonTextStyle),
    );
  }

  // --- Page Building Methods ---

  Widget _buildPersonalDataStep() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      // Use the specific form key for this page
      child: Form(
        key: _formKeys[0],
        child: ListView(
          children: [
            Text(
              'Tell us a bit about yourself',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 20),
            // Birth Year Dropdown
            DropdownButtonFormField<int>(
              dropdownColor: _dropdownBackgroundColor,
              decoration: InputDecoration(
                labelText: 'Birth Year',
                labelStyle: Theme.of(context).textTheme.headlineSmall,
                border: const OutlineInputBorder(),
              ),
              value: _selectedBirthYear,
              items: List.generate(101, (index) {
                final year = DateTime.now().year - index;
                return DropdownMenuItem<int>(
                  value: year,
                  child: Text(
                    year.toString(),
                    style: Theme.of(context).textTheme.bodyLarge?.merge(_dropdownItemTextStyle),
                  ),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  _selectedBirthYear = newValue;
                });
              },
              validator: (value) {
                if (value == null) {
                  return 'Please select your birth year.';
                }
                return null;
              },
            ),
            const SizedBox(height: 10),
            // Birth Month Dropdown
            DropdownButtonFormField<int>(
              dropdownColor: _dropdownBackgroundColor,
              decoration: InputDecoration(
                labelText: 'Birth Month',
                labelStyle: Theme.of(context).textTheme.headlineSmall,
                border: const OutlineInputBorder(),
              ),
              value: _selectedBirthMonth,
              items: List.generate(12, (index) {
                final month = index + 1;
                return DropdownMenuItem<int>(
                  value: month,
                  child: Text(
                    month.toString(),
                    style: Theme.of(context).textTheme.bodyLarge?.merge(_dropdownItemTextStyle),
                  ),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  _selectedBirthMonth = newValue;
                });
              },
              validator: (value) {
                if (value == null) {
                  return 'Please select your birth month.';
                }
                return null;
              },
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              // Apply the consistent dropdown background color
              dropdownColor: _dropdownBackgroundColor,
              decoration: InputDecoration(
                labelText: 'Gender (Optional)',
                labelStyle: Theme.of(context).textTheme.headlineSmall,
                border: const OutlineInputBorder(), // Consistent border
              ),
              value: _selectedSex,
              items: ['Male', 'Female', 'Other', 'Prefer not to say'].map((
                String value,
              ) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(
                    value,
                    // Use the consistent dropdown item text style
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.merge(_dropdownItemTextStyle),
                  ),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  _selectedSex = newValue;
                });
              },
              // No validator needed as it's optional
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _heightController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              decoration: InputDecoration(
                labelText: 'Height (in cm)',
                labelStyle: Theme.of(context).textTheme.headlineSmall,
                border: const OutlineInputBorder(), // Consistent border
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your height.';
                }
                if (double.tryParse(value) == null ||
                    double.parse(value) <= 0) {
                  return 'Please enter a valid height.';
                }
                return null;
              },
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _weightController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              decoration: InputDecoration(
                labelText: 'Weight (in kg)',
                labelStyle: Theme.of(context).textTheme.headlineSmall,
                border: const OutlineInputBorder(), // Consistent border
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your weight.';
                }
                if (double.tryParse(value) == null ||
                    double.parse(value) <= 0) {
                  return 'Please enter a valid weight.';
                }
                return null;
              },
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              // Apply the consistent dropdown background color
              dropdownColor: _dropdownBackgroundColor,
              decoration: InputDecoration(
                labelText: 'Activity Level',
                labelStyle: Theme.of(context).textTheme.headlineSmall,
                border: const OutlineInputBorder(), // Consistent border
              ),
              value: _selectedActivityLevel,
              items: ['Sedentary', 'Moderately Active', 'Very Active'].map((
                String value,
              ) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(
                    value,
                    // Use the consistent dropdown item text style
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.merge(_dropdownItemTextStyle),
                  ),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  _selectedActivityLevel = newValue;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select your activity level.';
                }
                return null;
              },
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _sleepHoursController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              decoration: InputDecoration(
                labelText: 'Average hours of sleep',
                labelStyle: Theme.of(context).textTheme.headlineSmall,
                border: const OutlineInputBorder(), // Consistent border
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your average sleep hours.';
                }
                if (double.tryParse(value) == null || double.parse(value) < 0) {
                  return 'Please enter a valid number of hours.';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildPreviousButton(),
                _buildNextButton(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDietaryPreferencesStep() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      // Use the specific form key for this page
      child: Form(
        key: _formKeys[1],
        child: ListView(
          children: [
            Text(
              'Tell us about your diet',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              // Apply the consistent dropdown background color
              dropdownColor: _dropdownBackgroundColor,
              decoration: InputDecoration(
                labelText: 'Diet Type',
                labelStyle: Theme.of(context).textTheme.headlineSmall,
                border: const OutlineInputBorder(), // Consistent border
              ),
              value: _selectedDietType,
              items: [
                'Omnivore',
                'Vegetarian',
                'Vegan',
                'Pescatarian',
                'Keto',
                'Other',
              ].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(
                    value,
                    // Use the consistent dropdown item text style
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.merge(_dropdownItemTextStyle),
                  ),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  _selectedDietType = newValue;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select your diet type.';
                }
                return null;
              },
            ),
            const SizedBox(height: 10),
            Text(
              'Any allergies or intolerances?',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start, // Align checkboxes to the start
              children:
                  ['Gluten', 'Dairy', 'Nuts', 'Soy', 'Other'].map((allergy) {
                return CheckboxListTile(
                  title: Text(
                    allergy,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  value: _selectedAllergies.contains(allergy),
                  onChanged: (bool? value) {
                    setState(() {
                      if (value == true) {
                        _selectedAllergies.add(allergy);
                      } else {
                        _selectedAllergies.remove(allergy);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            if (_selectedAllergies.contains('Other'))
              Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: TextFormField(
                  controller: _otherAllergyController,
                  decoration: InputDecoration(
                    labelText: 'Please specify other allergies',
                    labelStyle: Theme.of(context).textTheme.headlineSmall,
                    border: const OutlineInputBorder(), // Consistent border
                  ),
                  validator: (value) {
                    if (_selectedAllergies.contains('Other') &&
                        (value == null || value.isEmpty)) {
                      return 'Please specify your other allergies.';
                    }
                    return null;
                  },
                ),
              ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _dislikedFoodsController,
              decoration: InputDecoration(
                labelText: 'Foods you dislike (Optional)',
                labelStyle: Theme.of(context).textTheme.headlineSmall,
                border: const OutlineInputBorder(), // Consistent border
              ),
              maxLines: null,
              keyboardType: TextInputType.multiline,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _healthConditionsController,
              decoration: InputDecoration(
                labelText: 'Known health conditions (Optional)',
                labelStyle: Theme.of(context).textTheme.headlineSmall,
                border: const OutlineInputBorder(), // Consistent border
              ),
              maxLines: null,
              keyboardType: TextInputType.multiline,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildPreviousButton(),
                _buildNextButton(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthGoalsStep() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      // Use the specific form key for this page
      child: Form(
        key: _formKeys[2],
        child: ListView(
          children: [
            Text(
              'What are your health goals?',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 20),
            // RadioListTiles validation needs to be handled in _nextPage
            Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start, // Align radio buttons to the start
              children: [
                'Improve digestion',
                'Increase energy',
                'Sleep better',
                'Lose/gain/maintain weight',
                'Understand food-mood link',
                'Other',
              ].map((goal) {
                return RadioListTile<String>(
                  title: Text(
                    goal,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  value: goal,
                  groupValue: _selectedGoal,
                  onChanged: (newValue) {
                    setState(() {
                      _selectedGoal = newValue;
                    });
                  },
                );
              }).toList(),
            ),
            if (_selectedGoal == 'Other')
              Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: TextFormField(
                  controller: _otherGoalController,
                  decoration: InputDecoration(
                    labelText: 'Please specify your goal',
                    labelStyle: Theme.of(context).textTheme.headlineSmall,
                    border: const OutlineInputBorder(), // Consistent border
                  ),
                  validator: (value) {
                    if (_selectedGoal == 'Other' &&
                        (value == null || value.isEmpty)) {
                      return 'Please specify your goal.';
                    }
                    return null;
                  },
                ),
              ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildPreviousButton(),
                _buildNextButton(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentChallengesStep() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      // Use the specific form key for this page
      child: Form(
        key: _formKeys[3],
        child: ListView(
          children: [
            Text(
              'Any recurring issues?',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 20),
            // CheckboxListTiles validation needs to be handled in _nextPage
            Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start, // Align checkboxes to the start
              children: [
                'Bloating',
                'Headaches',
                'Fatigue',
                'Skin issues',
                'Mood swings',
                'Cravings',
                'Poor sleep',
                'Other',
              ].map((challenge) {
                return CheckboxListTile(
                  title: Text(
                    challenge,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  value: _selectedChallenges.contains(challenge),
                  onChanged: (bool? value) {
                    setState(() {
                      if (value == true) {
                        _selectedChallenges.add(challenge);
                      } else {
                        _selectedChallenges.remove(challenge);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            if (_selectedChallenges.contains('Other'))
              Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: TextFormField(
                  controller: _otherChallengeController,
                  decoration: InputDecoration(
                    labelText: 'Please specify other challenges',
                    labelStyle: Theme.of(context).textTheme.headlineSmall,
                    border: const OutlineInputBorder(), // Consistent border
                  ),
                  validator: (value) {
                    if (_selectedChallenges.contains('Other') &&
                        (value == null || value.isEmpty)) {
                      return 'Please specify your other challenges.';
                    }
                    return null;
                  },
                ),
              ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildPreviousButton(),
                _buildNextButton(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmotionalBaselineStep() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      // Use the specific form key for this page
      child: Form(
        key: _formKeys[4],
        child: ListView(
          children: [
            Text(
              'Emotional Baseline & Patterns',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 20),
            Text(
              'How would you rate your typical mood during the day? (1-5 scale)',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            // Sliders don't have built-in validators. Their state is managed by onChanged.
            ListTile(
              title: Text('Morning Mood',
                  style: Theme.of(context).textTheme.bodyLarge),
              subtitle: Slider(
                value: _morningMood.toDouble(),
                min: 1,
                max: 5,
                divisions: 4,
                label: _morningMood.toString(),
                onChanged: (double value) {
                  setState(() {
                    _morningMood = value.round();
                  });
                },
              ),
              trailing: Text(_morningMood.toString()),
            ),
            ListTile(
              title: Text(
                'Afternoon Mood',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              subtitle: Slider(
                value: _afternoonMood.toDouble(),
                min: 1,
                max: 5,
                divisions: 4,
                label: _afternoonMood.toString(),
                onChanged: (double value) {
                  setState(() {
                    _afternoonMood = value.round();
                  });
                },
              ),
              trailing: Text(_afternoonMood.toString()),
            ),
            ListTile(
              title: Text('Evening Mood',
                  style: Theme.of(context).textTheme.bodyLarge),
              subtitle: Slider(
                value: _eveningMood.toDouble(),
                min: 1,
                max: 5,
                divisions: 4,
                label: _eveningMood.toString(),
                onChanged: (double value) {
                  setState(() {
                    _eveningMood = value.round();
                  });
                },
              ),
              trailing: Text(_eveningMood.toString()),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _foodMoodConnectionController,
              decoration: InputDecoration(
                // Using 'label' for multiline label text
                label: Text(
                  'Do you suspect any connection between your food and your mood?',
                  style: Theme.of(context).textTheme.headlineSmall,
                  softWrap: true,
                ),
                border: const OutlineInputBorder(), // Consistent border
                alignLabelWithHint: true,
              ),
              maxLines: null,
              keyboardType: TextInputType.multiline,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please describe any connection you suspect.';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            // CheckboxListTile for consent. Validation in _submitSurvey.
            CheckboxListTile(
              title: Text(
                'I consent to my data being analyzed to provide personalized insights and suggestions.',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              value: _consentGiven,
              onChanged: (bool? value) {
                setState(() {
                  _consentGiven = value ?? false;
                });
              },
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildPreviousButton(),
                _buildNextButton(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingData) {
      return Scaffold(
        appBar: AppBar(
            title: Text('Personalize Your Experience',
                style: Theme.of(context).textTheme.labelMedium)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
          title: Text(
        'Personalize Your Experience',
        style: Theme.of(context).textTheme.labelMedium,
      )),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: _progress,
            backgroundColor: const Color.fromARGB(255, 6, 23, 18),
            color: const Color.fromARGB(255, 45, 190, 120),
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              // Keep swipe physics disabled for step-by-step forms.
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: _updateProgress,
              children: [
                _buildPersonalDataStep(),
                _buildDietaryPreferencesStep(),
                _buildHealthGoalsStep(),
                _buildCurrentChallengesStep(),
                _buildEmotionalBaselineStep(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
