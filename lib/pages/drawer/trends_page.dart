import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart'; // Import for charts
import 'package:provider/provider.dart';
import 'package:health_app_v1/service/connect_db.dart'; // Import ConnectDb

class TrendsPage extends StatefulWidget {
  const TrendsPage({super.key});

  @override
  State<TrendsPage> createState() => _TrendsPageState();
}

class _TrendsPageState extends State<TrendsPage> {
  String _selectedTimeframe = 'weekly';

  // Define the consistent dropdown background color, similar to survey_page.dart
  final Color _dropdownBackgroundColor = const Color.fromARGB(255, 9, 37, 29);
  // Define a text style for dropdown items on a dark background
  final TextStyle _dropdownItemTextStyle = const TextStyle(color: Colors.white);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Trends', style: Theme.of(context).textTheme.labelLarge),
        elevation: 1, // Added elevation for consistency with HomePage
      ),
      body: Consumer<ConnectDb>( // Wrap with Consumer
        builder: (context, connectDb, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0), // Consistent padding
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SummaryInsightCard(),
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
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(height: 20),
                // Updated MoodTrendChart to use FutureBuilder
                FutureBuilder<List<FlSpot>>(
                  future: connectDb.getMoodData(_selectedTimeframe),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      print('Error loading mood data: ${snapshot.error}');
                      return _buildErrorWidget(context, 'Could not load mood data.');
                    }
                    // Pass a specific no-data message to MoodTrendChart
                    return MoodTrendChart(
                        timeframe: _selectedTimeframe,
                        spots: snapshot.data ?? [],
                        noDataMessage: 'No mood data available for this period.');
                  },
                ),
                const SizedBox(height: 20),
                // Updated IngredientImpactSection to use FutureBuilder
                FutureBuilder<List<Map<String, String>>>(
                  future: connectDb.getIngredientImpactData(_selectedTimeframe),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      print('Error loading ingredient impact data: ${snapshot.error}');
                      return _buildErrorWidget(context, 'Could not load ingredient impact data.');
                    }
                    return IngredientImpactSection(
                        timeframe: _selectedTimeframe,
                        impactData: snapshot.data ?? []);
                  },
                ),
                const SizedBox(height: 20),
                // Updated WeeklyStatsSection to use FutureBuilder
                FutureBuilder<Map<String, String>>(
                  future: connectDb.getStatisticsData(_selectedTimeframe),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      print('Error loading statistics data: ${snapshot.error}');
                      return _buildErrorWidget(context, 'Could not load statistics.');
                    }
                    return WeeklyStatsSection(
                        timeframe: _selectedTimeframe,
                        statsData: snapshot.data ?? {});
                  },
                ),
                const SizedBox(height: 20),
                // Updated IngredientDiversityGraph to use FutureBuilder
                FutureBuilder<List<FlSpot>>(
                  future: connectDb.getIngredientDiversityData(_selectedTimeframe),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      print('Error loading ingredient diversity data: ${snapshot.error}');
                      return _buildErrorWidget(context, 'Could not load ingredient diversity data.');
                    }
                    // Pass a specific no-data message to IngredientDiversityGraph
                    return IngredientDiversityGraph(
                        timeframe: _selectedTimeframe,
                        spots: snapshot.data ?? [],
                        noDataMessage: 'Not enough variety data to display chart.');
                  },
                ),
                const SizedBox(height: 20),
                const LoggingStreakCard(),
                const SizedBox(height: 20),
                const IngredientSearchSection(),
              ],
            ),
          );
        },
      ),
    );
  }

  // Helper widget for displaying styled error messages
  Widget _buildErrorWidget(BuildContext context, String message) {
    return Center(
      child: Card(
        color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.7),
        margin: const EdgeInsets.all(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            message,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onErrorContainer,
              fontSize: Theme.of(context).textTheme.bodyLarge?.fontSize,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class SummaryInsightCard extends StatelessWidget {
  const SummaryInsightCard({super.key});

  @override
  Widget build(BuildContext context) {
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
              'Weekly Summary',
              style: Theme.of(context)
                  .textTheme
                  .labelLarge, // Consistent title style
            ),
            const SizedBox(height: 8),
            Text(
              'Based on your logs, you felt best on days with avocados and berries.',
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge, // Consistent body text style
            ),
            Text(
              'Foods like cheese and fried food correlated with lower mood scores.',
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge, // Consistent body text style
            ),
            Text(
              'Hydration levels showed a positive correlation with energy levels.',
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

class MoodTrendChart extends StatelessWidget {
  final String timeframe;
  final List<FlSpot> spots;
  final String noDataMessage; // Added for custom no-data message

  const MoodTrendChart({
    super.key,
    required this.timeframe,
    required this.spots,
    this.noDataMessage = "No data to display chart.", // Default message
  });

  List<String> _getBottomTitles(String timeframe, double value) {
    // Titles might need to be adjusted based on actual data from FlSpot.x values
    // For now, keep existing logic, but it might need to be more dynamic
    // if FlSpot.x values are not simple indices like 0, 1, 2...
    switch (timeframe) {
      case 'weekly':
        const titles = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        if (value.toInt() >= 0 && value.toInt() < titles.length) {
          return [titles[value.toInt()]];
        }
        return ['']; // Default or error case
      case 'monthly':
        // If spots.x are days 1-31
        return [value.toInt().toString()];
      case 'quarterly':
         // If spots.x are days (0-90 approx)
        return ['Day ${value.toInt() + 1}']; // Example
      case 'yearly':
        // If spots.x are days (0-365 approx)
        return ['Day ${value.toInt() + 1}']; // Example
      default:
        return [''];
    }
  }

  double _getMaxX(String timeframe, List<FlSpot> spots) {
    if (spots.isEmpty) return 0;
    // Determine maxX from the actual data spots
    // This makes the chart more adaptive to the data range
    double maxVal = spots.map((spot) => spot.x).reduce((a, b) => a > b ? a : b);

    // Add some padding or use specific logic per timeframe if needed
    switch (timeframe) {
      case 'weekly':
        return 6; // Assuming 0-6 for days of week
      case 'monthly':
        // For days of month, could be up to 30 or 31
        return DateTime(DateTime.now().year, DateTime.now().month + 1, 0).day.toDouble() -1;
      default:
        return maxVal; // For other timeframes, use the max x from data
    }
  }

  double _getIntervalX(String timeframe) {
    switch (timeframe) {
      case 'weekly':
        return 1;
      case 'monthly':
         return 7; // Show weekly ticks for monthly view if x is day number
      default:
        // Dynamic interval based on range, or fixed as before
        return 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxX = _getMaxX(timeframe, spots);
    final intervalX = _getIntervalX(timeframe);

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
              'Mood Trend (${timeframe[0].toUpperCase()}${timeframe.substring(1)})',
              style: Theme.of(context)
                  .textTheme
                  .labelMedium, // Consistent title style
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: spots.isEmpty
                  ? Center(
                      child: Text(
                      noDataMessage,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white70),
                      textAlign: TextAlign.center,
                    ))
                  : LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        interval: 2, // Mood score 0-10, interval 2
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 20,
                        interval: intervalX,
                        getTitlesWidget: (value, meta) {
                          final titles = _getBottomTitles(timeframe, value);
                          if (titles.isNotEmpty) {
                            return SideTitleWidget(
                                meta: meta,
                                child: Text(titles.first,
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
                  maxX: maxX,
                  minY: 0, // Mood score 0-10
                  maxY: 10, // Mood score 0-10
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots, // Use passed spots
                      isCurved: true,
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade200, Colors.blue.shade800],
                      ),
                      barWidth: 4,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: true), // Show dots on data points
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            Colors.blue.shade200.withOpacity(0.3), // Use withOpacity
                            Colors.blue.shade800.withOpacity(0.3), // Use withOpacity
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
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white), // Ensure text is visible on dark chip
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      backgroundColor: const Color.fromARGB(255, 15, 69, 53), // Slightly different color for emphasis
    );
  }
}

class IngredientImpactSection extends StatelessWidget {
  final String timeframe;
  final List<Map<String, String>> impactData;

  const IngredientImpactSection({super.key, required this.timeframe, required this.impactData});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ingredient Mood Impact (${timeframe[0].toUpperCase()}${timeframe.substring(1)})',
          style:
              Theme.of(context).textTheme.labelMedium, // Consistent title style
        ),
        const SizedBox(height: 8),
        impactData.isEmpty
            ? Center(
                child: Padding( // Added padding for consistency
                  padding: const EdgeInsets.symmetric(vertical: 20.0),
                  child: Text(
                    "No ingredient impact data available for this period.",
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                ))
            : Wrap(
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
  final Map<String, String> statsData;

  const WeeklyStatsSection({super.key, required this.timeframe, required this.statsData});

  @override
  Widget build(BuildContext context) {
    final String avgMood = statsData['Average Mood'] ?? 'N/A';
    final String mostLogged = statsData['Most Logged Ingredient'] ?? 'N/A';
    final bool noData = (avgMood == 'N/A' && mostLogged == 'N/A') ||
                        (avgMood == 'No data' && mostLogged == 'No data') ||
                        (statsData.isEmpty && avgMood == 'N/A'); // Check if initial map was empty

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Statistics (${timeframe[0].toUpperCase()}${timeframe.substring(1)})',
          style:
              Theme.of(context).textTheme.labelMedium, // Consistent title style
        ),
        const SizedBox(height: 8),
        noData
          ? Center(
              child: Padding( // Added padding for consistency
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: Text(
                  "No statistics available for this period.",
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
              ))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Average Mood: $avgMood',
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge),
                const SizedBox(height: 4),
                Text('Most Logged Ingredient: $mostLogged',
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge),
              ],
            ),
      ],
    );
  }
}

class IngredientDiversityGraph extends StatelessWidget {
  final String timeframe;
  final List<FlSpot> spots;
  final String noDataMessage; // Added for custom no-data message

  const IngredientDiversityGraph({
    super.key,
    required this.timeframe,
    required this.spots,
    this.noDataMessage = "No data to display chart.", // Default message
  });

  List<String> _getBottomTitles(String timeframe, double value) {
    // This logic might need to be more dynamic based on FlSpot.x values from DB
    switch (timeframe) {
      case 'weekly':
        const titles = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
         if (value.toInt() >= 0 && value.toInt() < titles.length) {
          return [titles[value.toInt()]];
        }
        return [''];
      case 'monthly': // Assuming x is week number 1-4/5
        return ['Wk ${value.toInt()}'];
      case 'quarterly': // Assuming x is month number 1-3 for the quarter
        return ['M${value.toInt()}'];
      case 'yearly': // Assuming x is month number 1-12
        return ['M${value.toInt()}'];
      default:
        return [''];
    }
  }

  double _getMaxX(String timeframe, List<FlSpot> spots) {
    if (spots.isEmpty) return 0;
    double maxVal = spots.map((spot) => spot.x).reduce((a, b) => a > b ? a : b);

    switch (timeframe) {
      case 'weekly':
        return 6; // 0-6 for days
      case 'monthly':
        return spots.isNotEmpty ? maxVal : 4; // Max week number, default 4
      case 'quarterly':
         return spots.isNotEmpty ? maxVal : 3; // Max month in Q, default 3
      case 'yearly':
        return spots.isNotEmpty ? maxVal : 12; // Max month in Y, default 12
      default:
        return maxVal;
    }
  }

  double _getIntervalX(String timeframe) {
    // This can remain fairly static or be made dynamic if needed
    return 1;
  }

  double _getMaxY(List<FlSpot> spots) {
    if (spots.isEmpty) return 20; // Default if no data
    double maxVal = spots.map((spot) => spot.y).reduce((a, b) => a > b ? a : b);
    return (maxVal / 5).ceil() * 5; // Round up to nearest 5 for nice ticks
  }

  @override
  Widget build(BuildContext context) {
    final maxX = _getMaxX(timeframe, spots);
    final intervalX = _getIntervalX(timeframe);
    final maxY = _getMaxY(spots);

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
              'Ingredient Variety Over Time (${timeframe[0].toUpperCase()}${timeframe.substring(1)})',
              style: Theme.of(context)
                  .textTheme
                  .labelMedium, // Consistent title style
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: spots.isEmpty
                ? Center(
                    child: Text(
                    noDataMessage,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ))
                : LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28, // Adjust as needed
                        interval: (maxY / 4).ceilToDouble(), // Dynamic interval
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 20,
                        interval: intervalX,
                        getTitlesWidget: (value, meta) {
                          final titles = _getBottomTitles(timeframe, value);
                          if (titles.isNotEmpty) {
                            return SideTitleWidget(
                              meta: meta,
                              child: Text(titles.first,
                                  style: Theme.of(context).textTheme.bodySmall),
                            );
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
                  maxX: maxX,
                  minY: 0,
                  maxY: maxY,
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots, // Use passed spots
                      isCurved: true,
                      gradient: LinearGradient(
                        colors: [Colors.green.shade200, Colors.green.shade800],
                      ),
                      barWidth: 4,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: true), // Show dots
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            Colors.green.shade200.withOpacity(0.3), // Use withOpacity
                            Colors.green.shade800.withOpacity(0.3), // Use withOpacity
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
  const LoggingStreakCard({super.key});

  @override
  Widget build(BuildContext context) {
    final connectDb = Provider.of<ConnectDb>(context, listen: false);
    return FutureBuilder<int>(
      future: connectDb.getUserLoggingStreak(),
      builder: (context, snapshot) {
        String streakText = 'Loading streak...';
        bool hasError = false;
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            hasError = true;
            streakText = 'Error loading streak';
            print('Error loading streak: ${snapshot.error}'); // Log error
          } else {
            final streak = snapshot.data ?? 0;
            if (streak == 0) {
              streakText = 'No active streak. Log today!';
            } else if (streak == 1) {
              streakText = '🎉 1-day streak!';
            } else {
              streakText = '🎉 $streak-day streak! Keep it up!';
            }
          }
        }

        return Center(
          child: SizedBox(
            width: 300,
            child: Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(12)), // Consistent rounded corners
              color: hasError
                  ? Theme.of(context).colorScheme.errorContainer.withOpacity(0.8)
                  : const Color.fromARGB(255, 45, 190, 120),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'Logging Streak',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: hasError ? Theme.of(context).colorScheme.onErrorContainer : Colors.white
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (snapshot.connectionState == ConnectionState.waiting)
                      CircularProgressIndicator(
                        color: hasError ? Theme.of(context).colorScheme.onErrorContainer : Colors.white,
                      )
                    else
                      Text(
                        streakText,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: hasError ? Theme.of(context).colorScheme.onErrorContainer : Colors.white
                        ),
                        textAlign: TextAlign.center,
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class IngredientSearchSection extends StatelessWidget {
  const IngredientSearchSection({super.key});

  @override
  Widget build(BuildContext context) {
    final connectDb = Provider.of<ConnectDb>(context, listen: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ingredient Lookup',
          style:
              Theme.of(context).textTheme.labelMedium, // Consistent title style
        ),
        const SizedBox(height: 8),
        TextField(
          decoration: InputDecoration(
            hintText: 'Search for an ingredient...',
            labelStyle: Theme.of(context)
                .textTheme
                .headlineSmall, // Consistent label style
            prefixIcon: const Icon(Icons.search),
            border: const OutlineInputBorder(), // Consistent border
          ),
        ),
        const SizedBox(height: 12),
        Text( // Added a small sub-header for clarity
          'Popular Ingredients:',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.white70),
        ),
        const SizedBox(height: 8),
        FutureBuilder<List<String>>(
          future: connectDb.getPopularIngredients(limit: 8),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              print('Error popular ingredients: ${snapshot.error}'); // Log error
              return _buildErrorWidget(context, 'Could not load popular ingredients.'); // Use helper
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Padding( // Added padding for consistency
                  padding: const EdgeInsets.symmetric(vertical: 20.0),
                  child: Text(
                    'No popular ingredients found.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                ));
            }

            final popularIngredients = snapshot.data!;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: popularIngredients
                  .map(
                    (ingredient) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Text(
                        '- $ingredient',
                        style: Theme.of(context)
                            .textTheme
                            .bodyLarge, // Consistent body text style
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}
