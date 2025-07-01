import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart'; // Import for charts
import 'package:health_app_v1/models/recipe.dart';
import 'package:health_app_v1/service/connect_db.dart';
import 'package:health_app_v1/service/google_api.dart';
import 'package:health_app_v1/utils/trend_chart_utils.dart';
import 'dart:math'; // For max function

class TrendsPage extends StatefulWidget {
  const TrendsPage({super.key});

  @override
  State<TrendsPage> createState() => _TrendsPageState();
}

class _TrendsPageState extends State<TrendsPage> {
  String _selectedTimeframe = 'weekly';
  final ConnectDb _dbService = ConnectDb();
  List<Map<String, dynamic>> _mealsData = [];
  List<Map<String, dynamic>> _moodsData = [];
  List<Recipe> _recipes = [];
  bool _isLoading = true;
  String _errorMessage = '';
  String _uid = '';

  // Store the actual start and end dates used for fetching
  DateTime _currentViewStartDate =
      DateTime.now().subtract(const Duration(days: 6)); // Default to weekly
  DateTime _currentViewEndDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _uid = FirebaseAuth.instance.currentUser!.uid;

    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      // Determine date range based on _selectedTimeframe
      _currentViewEndDate =
          DateTime.now(); // End date is always today (or time of fetch)

      switch (_selectedTimeframe) {
        case 'weekly':
          // Data for the last 7 days including today.
          _currentViewStartDate =
              _currentViewEndDate.subtract(const Duration(days: 6));
          break;
        case 'monthly':
          // Data for the last 30 days including today.
          _currentViewStartDate =
              _currentViewEndDate.subtract(const Duration(days: 29));
          break;
        case 'quarterly':
          // Data for the current quarter.
          int currentQuarter = ((_currentViewEndDate.month - 1) / 3)
              .floor(); // 0 for Q1, 1 for Q2, etc.
          _currentViewStartDate =
              DateTime(_currentViewEndDate.year, currentQuarter * 3 + 1, 1);
          break;
        case 'yearly':
          // Data for the current year.
          _currentViewStartDate = DateTime(_currentViewEndDate.year, 1, 1);
          break;
        default:
          _currentViewStartDate =
              _currentViewEndDate.subtract(const Duration(days: 6));
      }
      // Ensure startDate is not after endDate (edge case, e.g. if app starts on 1st day of month and 'monthly' is selected)
      // Normalizing to midnight for date part only comparison if needed, but _fetchData uses these as is.
      if (_currentViewStartDate.isAfter(_currentViewEndDate)) {
        _currentViewStartDate = DateTime(_currentViewEndDate.year,
            _currentViewEndDate.month, _currentViewEndDate.day);
      }

      print("Here: $_uid");

      _mealsData = await _dbService.getMealsForDateRange(
          _uid, _currentViewStartDate, _currentViewEndDate);
      _moodsData = await _dbService.getMoodsForDateRange(
          _uid, _currentViewStartDate, _currentViewEndDate);

      // _dbService.updateUID(_uid, ''); // Pass empty or relevant date
      await _dbService.loadRecipes();
      _recipes = _dbService.recipesList;
    } catch (e) {
      _errorMessage = "Error fetching data: ${e.toString()}";
      print(_errorMessage);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  DateTime _getViewStartDate() {
    // Helper to access the current start date for chart utils
    return _currentViewStartDate;
  }

  DateTime _getViewEndDate() {
    // Helper to access the current end date for chart utils
    return _currentViewEndDate;
  }

  // Define the consistent dropdown background color, similar to survey_page.dart
  final Color _dropdownBackgroundColor = const Color.fromARGB(255, 9, 37, 29);
  // Define a text style for dropdown items on a dark background
  final TextStyle _dropdownItemTextStyle = const TextStyle(color: Colors.white);

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
          child:
              Text(_errorMessage, style: const TextStyle(color: Colors.red)));
    }
    return Scaffold(
      appBar: AppBar(
        title: Text('Trends', style: Theme.of(context).textTheme.labelLarge),
        elevation: 1, // Added elevation for consistency with HomePage
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0), // Consistent padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SummaryInsightCard(mealsData: _mealsData, moodsData: _moodsData),
            const SizedBox(height: 20),
            // Timeframe selection dropdown
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: DropdownButtonFormField<String>(
                // Changed to DropdownButtonFormField
                decoration: InputDecoration(
                  labelText: 'Time Frame',
                  labelStyle: Theme.of(context).textTheme.headlineSmall,
                  border: const OutlineInputBorder(), // Consistent border
                ),
                dropdownColor:
                    _dropdownBackgroundColor, // Apply consistent dropdown background
                value: _selectedTimeframe,
                items: [
                  DropdownMenuItem(
                    value: 'weekly',
                    child: Text(
                      'Weekly',
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.merge(_dropdownItemTextStyle),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'monthly',
                    child: Text(
                      'Monthly',
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.merge(_dropdownItemTextStyle),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'quarterly',
                    child: Text(
                      'Quarterly',
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.merge(_dropdownItemTextStyle),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'yearly',
                    child: Text(
                      'Yearly',
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.merge(_dropdownItemTextStyle),
                    ),
                  ),
                ],
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedTimeframe = newValue;
                      _fetchData(); // Call _fetchData here
                    });
                  }
                },
              ),
            ),
            const SizedBox(height: 20),
            MoodTrendChart(
              timeframe: _selectedTimeframe,
              moodsData: _moodsData,
              viewStartDate: _getViewStartDate(),
              viewEndDate: _getViewEndDate(),
            ),
            const SizedBox(height: 20),
            IngredientImpactSection(
                timeframe: _selectedTimeframe,
                mealsData: _mealsData,
                moodsData: _moodsData,
                recipes: _recipes),
            const SizedBox(height: 20),
            WeeklyStatsSection(
                timeframe: _selectedTimeframe,
                mealsData: _mealsData,
                moodsData: _moodsData,
                recipesList: _recipes),
            const SizedBox(height: 20),
            IngredientDiversityGraph(
              timeframe: _selectedTimeframe,
              mealsData: _mealsData,
              viewStartDate: _getViewStartDate(),
              viewEndDate: _getViewEndDate(),
            ),
            const SizedBox(height: 20),
            LoggingStreakCard(mealsData: _mealsData, moodsData: _moodsData),
            const SizedBox(height: 20),
            IngredientSearchSection(allRecipes: _recipes),
          ],
        ),
      ),
    );
  }
}

class SummaryInsightCard extends StatefulWidget {
  const SummaryInsightCard(
      {super.key, required this.mealsData, required this.moodsData});
  final List<Map<String, dynamic>> mealsData;
  final List<Map<String, dynamic>> moodsData;

  @override
  State<SummaryInsightCard> createState() => _SummaryInsightCardState();
}

class _SummaryInsightCardState extends State<SummaryInsightCard> {
  String aiInsight = "Generating AI insights..."; // Initial loading message
  bool _isFetchingInsights = true; // To track loading state

  @override
  void initState() {
    super.initState();
    getAIInsights();
  }

  Future<void> getAIInsights() async {
    setState(() {
      _isFetchingInsights = true;
    });

    final String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      setState(() {
        aiInsight = "Could not identify user to fetch AI insights.";
        _isFetchingInsights = false;
      });
      return;
    }

    final ConnectDb dbService = ConnectDb(); // Consider passing via constructor or Provider
    Map<String, dynamic>? surveyData;
    try {
      surveyData = await dbService.getSurveyData(userId);
    } catch (e) {
      print("Error fetching survey data: $e");
      // Handle error, maybe set a specific insight message
    }

    // Constructing the prompt
    String prompt = """
Analyze the following user data to provide personalized insights, feedback, and suggestions.
The user wants to improve their health and reach their intentions based on this data.

User Survey Data:
${surveyData?.entries.map((e) => "${e.key}: ${e.value}").join('\n') ?? "No survey data available."}

Logged Meals Data (last period):
${widget.mealsData.map((day) {
      String date = day['date'];
      List meals = day['meals'] as List? ?? [];
      return "On $date:\n" +
          meals.map((meal) {
            String mealTitle = meal['mealTitle'] ?? 'Unknown Meal';
            List recipeIds = meal['recipes'] as List? ?? [];
            // TODO: Fetch recipe details if needed, for now just IDs
            return "- $mealTitle: ${recipeIds.join(', ')}";
          }).join('\n');
    }).join('\n\n')
    }
    ${widget.mealsData.isEmpty ? "No meal data logged for this period." : ""}

Logged Moods Data (last period):
${widget.moodsData.map((day) {
      String date = day['date'];
      List moods = day['moods'] as List? ?? [];
      return "On $date:\n" +
          moods.map((mood) {
            String title = mood['title'] ?? 'Unknown Mood';
            int score = mood['score'] ?? -1;
            return "- $title: Score $score";
          }).join('\n');
    }).join('\n\n')
    }
    ${widget.moodsData.isEmpty ? "No mood data logged for this period." : ""}

Based on all the above, provide:
1. Key insights drawn from correlations between their survey (goals, challenges, preferences) and their logged meals/moods.
2. Constructive feedback on their current logging patterns or dietary choices in relation to their stated goals.
3. Actionable suggestions for what they can do to improve and reach their intentions. For example, if they want to improve energy and log low energy after certain meals, suggest alternatives. If they mention a health goal in the survey and their logs don't align, point that out with suggestions.
Please be thorough and empathetic.
""";

    print("AI Prompt: $prompt"); // For debugging

    try {
      GoogleApi gemini = GoogleApi(prompt: prompt);
      final response = await gemini.generateContentResponse();
      if (response.text != null && response.text!.isNotEmpty) {
        setState(() {
          aiInsight = response.text!;
        });
      } else {
        setState(() {
          aiInsight =
              "Could not generate AI insights at this time. Please try again later.";
        });
      }
    } catch (e) {
      print("Error calling Gemini API: $e");
      setState(() {
        aiInsight =
            "An error occurred while fetching AI insights. Check logs for details.";
      });
    } finally {
      setState(() {
        _isFetchingInsights = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // AI Insight is now fetched in initState, build just displays it or loading state.
    // Other insights (moodInsight, mealInsight) are calculated directly in build as before.

    String moodInsight = "No mood data available.";
    if (widget.moodsData.isNotEmpty) {
      // Example: find the average mood score
      double totalScore = 0;
      int moodCount = 0;
      for (var moodDay in widget.moodsData) {
        if (moodDay['moods'] != null) {
          for (var moodEntry in moodDay['moods']) {
            if (moodEntry['score'] != null && moodEntry['score'] != -1) {
              totalScore += moodEntry['score'];
              moodCount++;
            }
          }
        }
      }
      if (moodCount > 0) {
        moodInsight =
            "Average mood score: ${(totalScore / moodCount).toStringAsFixed(1)}/5.";
      } else {
        moodInsight = "Mood data found, but no scores recorded.";
      }
    }

    String mealInsight = "No meal data available.";
    if (widget.mealsData.isNotEmpty) {
      // Example: count logged meals
      int mealLogCount = 0;
      for (var mealDay in widget.mealsData) {
        if (mealDay['meals'] != null) {
          for (var mealTime in mealDay['meals']) {
            if (mealTime['recipes'] != null &&
                (mealTime['recipes'] as List).isNotEmpty) {
              mealLogCount++;
            }
          }
        }
      }
      mealInsight = "You've logged meals $mealLogCount times in this period.";
    }
    
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(12)), // Consistent rounded corners
      color: const Color.fromARGB(255, 9, 37, 29),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Summary & AI Insights', // Updated title
              style: Theme.of(context)
                  .textTheme
                  .labelLarge, // Consistent title style
            ),
            const SizedBox(height: 8),
            Text(
              moodInsight,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge, // Consistent body text style
            ),
            Text(
              mealInsight,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge, // Consistent body text style
            ),
            const SizedBox(height: 12), // Added space before AI insight
            // Display AI insight or loading indicator
            _isFetchingInsights
                ? const Row(
                    children: [
                      CircularProgressIndicator(strokeWidth: 2),
                      SizedBox(width: 8),
                      Text("Generating AI insights...", style: TextStyle(color: Colors.white70)),
                    ],
                  )
                : Text(
                    aiInsight, // This will show the fetched insight or an error/default message
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge, // Consistent body text style
                  ),
          ],
        ),
      ),
    );
  }
}

class MoodTrendChart extends StatefulWidget {
  final String timeframe;
  final List<Map<String, dynamic>> moodsData;
  final DateTime viewStartDate;
  final DateTime viewEndDate;

  const MoodTrendChart({
    super.key,
    required this.timeframe,
    required this.moodsData,
    required this.viewStartDate,
    required this.viewEndDate,
  });

  @override
  State<MoodTrendChart> createState() => _MoodTrendChartState();
}

class _MoodTrendChartState extends State<MoodTrendChart> {
  ProcessedChartData? _chartData;

  @override
  void initState() {
    super.initState();
    _processData();
  }

  @override
  void didUpdateWidget(MoodTrendChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.moodsData != oldWidget.moodsData ||
        widget.timeframe != oldWidget.timeframe ||
        widget.viewStartDate != oldWidget.viewStartDate ||
        widget.viewEndDate != oldWidget.viewEndDate) {
      _processData();
    }
  }

  void _processData() {
    // Step 2.3 will fully implement this. For now, it prepares the structure.
    // This ensures TrendChartUtils is callable.
    // In a real scenario, might show loading or use placeholder until TrendChartUtils is fully integrated.
    setState(() {
      // Temporarily setting to null or a default. Full integration in next step.
      _chartData = TrendChartUtils.processDataForChart(
        timeframe: widget.timeframe,
        dailyEntries: widget.moodsData,
        overallStartDate: widget.viewStartDate,
        overallEndDate: widget.viewEndDate,
        dataAggregator: _aggregateMoodScores,
      );
    });
  }

  double _aggregateMoodScores(
      List<Map<String, dynamic>> dailyMoodEntriesForPeriod) {
    if (dailyMoodEntriesForPeriod.isEmpty) return 0;
    double periodTotalScore = 0;
    int daysWithMoodsInPeriod = 0;
    for (var dayEntry in dailyMoodEntriesForPeriod) {
      if (dayEntry['moods'] == null) continue;
      List dailyMoods = dayEntry['moods'];
      double singleDayTotalScore = 0;
      int singleDayMoodCount = 0;
      for (var mood in dailyMoods) {
        if (mood['score'] != null && mood['score'] != -1) {
          singleDayTotalScore += mood['score'];
          singleDayMoodCount++;
        }
      }
      if (singleDayMoodCount > 0) {
        periodTotalScore += (singleDayTotalScore / singleDayMoodCount);
        daysWithMoodsInPeriod++;
      }
    }
    return daysWithMoodsInPeriod > 0
        ? periodTotalScore / daysWithMoodsInPeriod
        : 0;
  }

  @override
  Widget build(BuildContext context) {
    // Display a loading or empty state if _chartData is not yet processed or is empty
    if (_chartData == null || _chartData!.spots.isEmpty) {
      return Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: const Color.fromARGB(255, 9, 37, 29),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mood Trend (${widget.timeframe[0].toUpperCase()}${widget.timeframe.substring(1)})',
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 200,
                child: Center(
                    child: Text(
                        'No mood data for this period or data is processing.',
                        style: TextStyle(color: Colors.white70))),
              ),
            ],
          ),
        ),
      );
    }

    // If _chartData is available, build the chart
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(12)), // Consistent rounded corners
      color: Color.fromARGB(255, 9, 37, 29),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mood Trend (${widget.timeframe[0].toUpperCase()}${widget.timeframe.substring(1)})', // Use widget.timeframe
              style: Theme.of(context)
                  .textTheme
                  .labelMedium, // Consistent title style
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        interval: 2, // Adjusted interval for 0-10 range
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 20,
                        interval: _chartData!
                            .intervalX, // Use from ProcessedChartData
                        getTitlesWidget: (value, meta) {
                          final title = _chartData!.bottomTitles[value.toInt()];
                          if (title != null) {
                            return SideTitleWidget(
                                meta: meta,
                                space: 4.0,
                                child: Text(title,
                                    style:
                                        Theme.of(context).textTheme.bodySmall));
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(
                      color: const Color(0xff37434d),
                      width: 1,
                    ),
                  ),
                  minX: 0,
                  maxX: _chartData!.maxX, // Use from ProcessedChartData
                  minY: 0,
                  maxY: 10, // Mood scores are 0-10
                  lineBarsData: [
                    LineChartBarData(
                      spots: _chartData!.spots, // Use from ProcessedChartData
                      isCurved: true,
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade200, Colors.blue.shade800],
                      ),
                      barWidth: 4,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            Colors.blue.shade200.withValues(alpha: 0.3),
                            Colors.blue.shade800.withValues(alpha: 0.3),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class IngredientImpactCard extends StatelessWidget {
  final String ingredient;
  final String impact;

  const IngredientImpactCard({
    super.key,
    required this.ingredient,
    required this.impact,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(
        '$ingredient - $impact',
        style: Theme.of(context).textTheme.bodyLarge, // Consistent text style
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      backgroundColor: Color.fromARGB(255, 9, 37, 29),
    );
  }
}

class IngredientImpactSection extends StatelessWidget {
  final String timeframe;
  final List<Map<String, dynamic>> mealsData;
  final List<Map<String, dynamic>> moodsData;
  final List<Recipe> recipes;

  const IngredientImpactSection({
    super.key,
    required this.timeframe,
    required this.mealsData,
    required this.moodsData,
    required this.recipes,
  });

  Map<String, List<double>> _calculateIngredientMoodScores(
      List<Map<String, dynamic>> mealsData,
      List<Map<String, dynamic>> moodsData) {
    Map<String, List<double>> scores = {};
    Map<String, double> dailyAverageMoods = {};

    for (var moodDay in moodsData) {
      if (moodDay['date'] == null || moodDay['moods'] == null) continue;
      String date = moodDay['date'];
      double totalScore = 0;
      int count = 0;
      for (var moodEntry in moodDay['moods']) {
        if (moodEntry['score'] != null && moodEntry['score'] != -1) {
          totalScore += moodEntry['score'];
          count++;
        }
      }
      if (count > 0) {
        dailyAverageMoods[date] = totalScore / count;
      }
    }

    for (var mealDay in mealsData) {
      if (mealDay['date'] == null || mealDay['meals'] == null) continue;
      String date = mealDay['date'];

      if (!dailyAverageMoods.containsKey(date)) continue;
      double dayMoodScore = dailyAverageMoods[date]!;

      List dailyMeals = mealDay['meals'];
      for (var meal in dailyMeals) {
        if (meal['recipes'] == null) continue;
        List recipeIds = meal['recipes'];
        for (var recipeId in recipeIds) {
          String id = recipeId.toString();
          scores.putIfAbsent(id, () => []).add(dayMoodScore);
        }
      }
    }
    return scores;
  }

  List<Map<String, String>> _getImpactDisplayData(
      Map<String, List<double>> ingredientMoodScores, List<Recipe> allRecipes) {
    if (ingredientMoodScores.isEmpty) return [];
    List<Map<String, dynamic>> processedIngredients = [];

    ingredientMoodScores.forEach((recipeId, scores) {
      if (scores.isNotEmpty) {
        double averageScore = scores.reduce((a, b) => a + b) / scores.length;
        // Find recipe by ID. Note: Recipe ID in Firebase might be String.
        Recipe? recipe =
            allRecipes.firstWhere((r) => r.id.toString() == recipeId);
        processedIngredients.add({
          'name': recipe.title,
          'avgScore': averageScore,
          'logCount': scores.length
        });
      }
    });

    processedIngredients.removeWhere((item) => item['logCount'] < 3);
    processedIngredients.sort((a, b) => b['avgScore'].compareTo(a['avgScore']));

    List<Map<String, String>> displayData = [];
    int displayCount = 3;

    // Top positive impacts
    for (int i = 0; i < processedIngredients.length && i < displayCount; i++) {
      var item = processedIngredients[i];
      String impactString =
          "👍 ${item['avgScore'].toStringAsFixed(1)}/10 (${item['logCount']} logs)";
      displayData.add({'ingredient': item['name'], 'impact': impactString});
    }

    // Top negative impacts (if any after positive ones)
    // Sorting again for lowest scores
    processedIngredients.sort((a, b) => a['avgScore'].compareTo(b['avgScore']));
    int negativeDisplayCount = 3;
    for (int i = 0;
        i < processedIngredients.length && i < negativeDisplayCount;
        i++) {
      var item = processedIngredients[i];
      // Ensure not already added as a positive impact if lists overlap significantly
      if (displayData.where((d) => d['ingredient'] == item['name']).isEmpty &&
          item['avgScore'] < 5.0) {
        // Example threshold for "negative"
        String impactString =
            "👎 ${item['avgScore'].toStringAsFixed(1)}/10 (${item['logCount']} logs)";
        displayData.add({'ingredient': item['name'], 'impact': impactString});
      }
      if (displayData.length >= displayCount + negativeDisplayCount) break;
    }

    return displayData;
  }

  @override
  Widget build(BuildContext context) {
    final ingredientMoodScores =
        _calculateIngredientMoodScores(mealsData, moodsData);
    final impactData = _getImpactDisplayData(ingredientMoodScores, recipes);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ingredient Mood Impact (${timeframe[0].toUpperCase()}${timeframe.substring(1)})',
          style:
              Theme.of(context).textTheme.labelMedium, // Consistent title style
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: impactData.map((data) {
            return IngredientImpactCard(
              ingredient: data['ingredient']!,
              impact: data['impact']!,
            );
          }).toList(),
        ),
      ],
    );
  }
}

class WeeklyStatsSection extends StatelessWidget {
  final String timeframe;
  final List<Map<String, dynamic>> mealsData;
  final List<Map<String, dynamic>> moodsData;
  final List<Recipe> recipesList;

  const WeeklyStatsSection({
    super.key,
    required this.timeframe,
    required this.mealsData,
    required this.moodsData,
    required this.recipesList,
  });

  String _calculateAverageMood(List<Map<String, dynamic>> moodsData) {
    if (moodsData.isEmpty) return 'N/A';
    double totalDailyAverageScore = 0;
    int daysWithMoods = 0;
    for (var moodDay in moodsData) {
      if (moodDay['moods'] == null) continue;
      List dailyMoodEntries = moodDay['moods'];
      double currentDayTotalScore = 0;
      int currentDayMoodCount = 0;
      for (var moodEntry in dailyMoodEntries) {
        if (moodEntry['score'] != null && moodEntry['score'] != -1) {
          currentDayTotalScore += moodEntry['score'];
          currentDayMoodCount++;
        }
      }
      if (currentDayMoodCount > 0) {
        totalDailyAverageScore += (currentDayTotalScore / currentDayMoodCount);
        daysWithMoods++;
      }
    }
    return daysWithMoods > 0
        ? '${(totalDailyAverageScore / daysWithMoods).toStringAsFixed(1)}/10'
        : 'N/A';
  }

  String _calculateMostLoggedIngredient(
      List<Map<String, dynamic>> mealsData, List<Recipe> recipesList) {
    if (mealsData.isEmpty || recipesList.isEmpty) return 'N/A';
    Map<String, int> ingredientCounts = {};
    for (var mealDay in mealsData) {
      if (mealDay['meals'] == null) continue;
      List dailyMeals = mealDay['meals'];
      for (var meal in dailyMeals) {
        if (meal['recipes'] == null) continue;
        List recipeIds = meal['recipes'];
        for (var recipeId in recipeIds) {
          String id = recipeId.toString();
          ingredientCounts[id] = (ingredientCounts[id] ?? 0) + 1;
        }
      }
    }
    if (ingredientCounts.isEmpty) return 'N/A';
    // Find the recipeId with the max count
    String? mostLoggedId;
    int maxCount = 0;
    ingredientCounts.forEach((id, count) {
      if (count > maxCount) {
        maxCount = count;
        mostLoggedId = id;
      }
    });
    if (mostLoggedId == null) return 'N/A';
    Recipe? recipe =
        recipesList.firstWhere((r) => r.id.toString() == mostLoggedId);
    return '${recipe.title} ($maxCount times)';
  }

  // Fake data for weekly stats based on timeframe
  // Map<String, String> _generateStatsData(String timeframe) {
  //  // ... removed ...
  // }

  @override
  Widget build(BuildContext context) {
    final String avgMood = _calculateAverageMood(moodsData);
    final String mostLogged =
        _calculateMostLoggedIngredient(mealsData, recipesList);
    final statsData = {
      'Average Mood': avgMood,
      'Most Logged Ingredient': mostLogged
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Statistics (${timeframe[0].toUpperCase()}${timeframe.substring(1)})',
          style:
              Theme.of(context).textTheme.labelMedium, // Consistent title style
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
                child: Text('Average Mood: ${statsData['Average Mood']}',
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge)), // Consistent body text style
            Expanded(
                child: Text(
                    'Most Logged Ingredient: ${statsData['Most Logged Ingredient']}',
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge)), // Consistent body text style
          ],
        ),
      ],
    );
  }
}

class IngredientDiversityGraph extends StatefulWidget {
  final String timeframe;
  final List<Map<String, dynamic>> mealsData;
  final DateTime viewStartDate;
  final DateTime viewEndDate;

  const IngredientDiversityGraph({
    super.key,
    required this.timeframe,
    required this.mealsData,
    required this.viewStartDate,
    required this.viewEndDate,
  });

  @override
  State<IngredientDiversityGraph> createState() =>
      _IngredientDiversityGraphState();
}

class _IngredientDiversityGraphState extends State<IngredientDiversityGraph> {
  ProcessedChartData? _chartData;

  @override
  void initState() {
    super.initState();
    _processData();
  }

  @override
  void didUpdateWidget(IngredientDiversityGraph oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.mealsData != oldWidget.mealsData ||
        widget.timeframe != oldWidget.timeframe ||
        widget.viewStartDate != oldWidget.viewStartDate ||
        widget.viewEndDate != oldWidget.viewEndDate) {
      _processData();
    }
  }

  void _processData() {
    setState(() {
      _chartData = TrendChartUtils.processDataForChart(
        timeframe: widget.timeframe,
        dailyEntries: widget.mealsData,
        overallStartDate: widget.viewStartDate,
        overallEndDate: widget.viewEndDate,
        dataAggregator: _aggregateRecipeDiversity,
      );
    });
  }

  double _aggregateRecipeDiversity(
      List<Map<String, dynamic>> dailyMealEntriesForPeriod) {
    if (dailyMealEntriesForPeriod.isEmpty) return 0;
    Set<String> uniqueRecipeIdsInPeriod = {};
    for (var dayEntry in dailyMealEntriesForPeriod) {
      if (dayEntry['meals'] == null) continue;
      List dailyMeals = dayEntry['meals'];
      for (var meal in dailyMeals) {
        if (meal['recipes'] == null) continue;
        List recipeIds = meal['recipes'];
        for (var id in recipeIds) {
          uniqueRecipeIdsInPeriod.add(id.toString());
        }
      }
    }
    return uniqueRecipeIdsInPeriod.length.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    if (_chartData == null || _chartData!.spots.isEmpty) {
      return Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: const Color.fromARGB(255, 9, 37, 29),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ingredient Variety Over Time (${widget.timeframe[0].toUpperCase()}${widget.timeframe.substring(1)})',
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const SizedBox(height: 16),
              const SizedBox(
                height: 200,
                child: Center(
                    child: Text('No meal data for this period.',
                        style: TextStyle(color: Colors.white70))),
              ),
            ],
          ),
        ),
      );
    }

    final double maxY = _chartData!.spots.isNotEmpty
        ? _chartData!.spots.map((s) => s.y).reduce(max) + 2
        : 20; // Add padding

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(12)), // Consistent rounded corners
      color: const Color.fromARGB(255, 9, 37, 29), // Added const
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ingredient Variety Over Time (${widget.timeframe[0].toUpperCase()}${widget.timeframe.substring(1)})', // Use widget.timeframe
              style: Theme.of(context)
                  .textTheme
                  .labelMedium, // Consistent title style
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        interval: maxY / 5, // Dynamic interval based on max Y
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 20,
                        interval: _chartData!.intervalX,
                        getTitlesWidget: (value, meta) {
                          final title = _chartData!.bottomTitles[value.toInt()];
                          if (title != null) {
                            return SideTitleWidget(
                                meta: meta,
                                space: 4.0, // Or your preferred spacing
                                child: Text(title,
                                    style:
                                        Theme.of(context).textTheme.bodySmall));
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(
                      color: const Color(0xff37434d),
                      width: 1,
                    ),
                  ),
                  minX: 0,
                  maxX: _chartData!.maxX, // Use from ProcessedChartData
                  minY: 0,
                  maxY: maxY,
                  lineBarsData: [
                    LineChartBarData(
                      spots: _chartData!.spots, // Use from ProcessedChartData
                      isCurved: true,
                      gradient: LinearGradient(
                        colors: [Colors.green.shade200, Colors.green.shade800],
                      ),
                      barWidth: 4,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            Colors.green.shade200.withValues(alpha: 0.3),
                            Colors.green.shade800.withValues(alpha: 0.3),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LoggingStreakCard extends StatelessWidget {
  final List<Map<String, dynamic>> mealsData;
  final List<Map<String, dynamic>> moodsData;

  const LoggingStreakCard(
      {super.key, required this.mealsData, required this.moodsData});

  int _calculateLoggingStreak(List<Map<String, dynamic>> mealsData,
      List<Map<String, dynamic>> moodsData) {
    Set<String> loggedDatesStr = {};
    for (var mealDay in mealsData) {
      if (mealDay['date'] != null) loggedDatesStr.add(mealDay['date']);
    }
    for (var moodDay in moodsData) {
      if (moodDay['date'] != null) loggedDatesStr.add(moodDay['date']);
    }

    if (loggedDatesStr.isEmpty) return 0;

    List<DateTime> sortedDates =
        loggedDatesStr.map((dateStr) => DateTime.parse(dateStr)).toList();
    sortedDates.sort((a, b) => b.compareTo(a)); // Sort descending

    // Check if today is logged. If not, streak is 0 unless yesterday was the last log.
    DateTime today = DateTime.now();
    DateTime todayDateOnly = DateTime(today.year, today.month, today.day);

    // Find the most recent log date
    DateTime mostRecentLogDate = sortedDates.first;
    mostRecentLogDate = DateTime(
        mostRecentLogDate.year, mostRecentLogDate.month, mostRecentLogDate.day);

    // If the most recent log isn't today or yesterday, the current streak is 0.
    if (!mostRecentLogDate.isAtSameMomentAs(todayDateOnly) &&
        !mostRecentLogDate.isAtSameMomentAs(
            todayDateOnly.subtract(const Duration(days: 1)))) {
      return 0;
    }

    int streak = 0;
    DateTime expectedDate = todayDateOnly;

    // If the most recent log is yesterday, start checking from yesterday
    if (mostRecentLogDate
        .isAtSameMomentAs(todayDateOnly.subtract(const Duration(days: 1)))) {
      expectedDate = mostRecentLogDate;
    }

    for (DateTime date in sortedDates) {
      DateTime dateOnly = DateTime(date.year, date.month, date.day);
      if (dateOnly.isAtSameMomentAs(expectedDate)) {
        streak++;
        expectedDate = expectedDate.subtract(const Duration(days: 1));
      } else if (dateOnly.isBefore(expectedDate)) {
        // Gap in logging, streak broken before this point
        break;
      }
      // If dateOnly is after expectedDate, it means duplicate entries for a day or unsorted data - handled by Set and sort.
    }
    return streak;
  }

  @override
  Widget build(BuildContext context) {
    final int streak = _calculateLoggingStreak(mealsData, moodsData);
    String streakMessage = '🎉 $streak-day streak! Keep it up!';
    if (streak == 0) {
      streakMessage = 'Start logging today to build your streak!';
    } else if (streak == 1) {
      streakMessage =
          '🎉 $streak-day streak! Log again tomorrow to keep it going!';
    }

    return Center(
      child: SizedBox(
        width: 300,
        child: Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(12)), // Consistent rounded corners
          color: const Color.fromARGB(255, 45, 190, 120), // Use const for color
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(
                  'Logging Streak',
                  style: Theme.of(context)
                      .textTheme
                      .labelMedium, // Consistent title style
                ),
                const SizedBox(height: 8),
                Text(
                  streakMessage,
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge, // Consistent body text style
                  textAlign: TextAlign.center, // Good for multi-line messages
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class IngredientSearchSection extends StatefulWidget {
  final List<Recipe> allRecipes;
  const IngredientSearchSection({super.key, required this.allRecipes});

  @override
  State<IngredientSearchSection> createState() =>
      _IngredientSearchSectionState();
}

class _IngredientSearchSectionState extends State<IngredientSearchSection> {
  final TextEditingController _searchController = TextEditingController();
  List<Recipe> _searchResults = [];

  @override
  void initState() {
    super.initState();
    // Initially, you might want to show all recipes or popular ones
    // For simplicity, start with empty results or a subset of widget.allRecipes
    // _searchResults = widget.allRecipes.take(5).toList(); // Example: show first 5 initially
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    String query = _searchController.text.toLowerCase();
    if (query.isEmpty) {
      setState(() {
        // _searchResults = widget.allRecipes.take(5).toList(); // Or clear
        _searchResults = [];
      });
      return;
    }
    setState(() {
      _searchResults = widget.allRecipes
          .where((recipe) => recipe.title.toLowerCase().contains(query))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ingredient Lookup',
          style: Theme.of(context).textTheme.labelMedium,
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search for an ingredient...',
            labelStyle: Theme.of(context).textTheme.headlineSmall,
            prefixIcon: const Icon(Icons.search),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        // Display search results
        if (_searchController.text.isNotEmpty && _searchResults.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Text(
              'No ingredients found for "${_searchController.text}".',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          )
        else if (_searchResults.isNotEmpty)
          ListView.builder(
            shrinkWrap: true, // Important for ListView inside Column
            physics:
                const NeverScrollableScrollPhysics(), // If Column is scrollable
            itemCount: _searchResults.length,
            itemBuilder: (context, index) {
              final recipe = _searchResults[index];
              // For now, just display the title. More info can be added.
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Text(
                  '- ${recipe.title}',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              );
            },
          )
        else if (_searchController
            .text.isEmpty) // Optional: Show initial message or popular items
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Text(
              'Enter a search term to find ingredients.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          )
        // Original placeholder for popular ingredients can be removed or adapted
        // if you want to show something when search is empty.
      ],
    );
  }
}
