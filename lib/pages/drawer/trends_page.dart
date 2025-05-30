import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart'; // Import for charts

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
      body: SingleChildScrollView(
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
            MoodTrendChart(timeframe: _selectedTimeframe),
            const SizedBox(height: 20),
            IngredientImpactSection(timeframe: _selectedTimeframe),
            const SizedBox(height: 20),
            WeeklyStatsSection(timeframe: _selectedTimeframe),
            const SizedBox(height: 20),
            IngredientDiversityGraph(timeframe: _selectedTimeframe),
            const SizedBox(height: 20),
            const LoggingStreakCard(),
            const SizedBox(height: 20),
            const IngredientSearchSection(),
          ],
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
      color: Color.fromARGB(255, 9, 37, 29),
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
  const MoodTrendChart({super.key, required this.timeframe});

  // Fake data generation based on timeframe
  List<FlSpot> _generateMoodSpots(String timeframe) {
    switch (timeframe) {
      case 'weekly':
        // 7 days
        return [
          const FlSpot(0, 3),
          const FlSpot(1, 5),
          const FlSpot(2, 4),
          const FlSpot(3, 6),
          const FlSpot(4, 7),
          const FlSpot(5, 5),
          const FlSpot(6, 6),
        ];
      case 'monthly':
        // 4 weeks
        return [
          const FlSpot(0, 4),
          const FlSpot(1, 5.5),
          const FlSpot(2, 5),
          const FlSpot(3, 6.5),
        ];
      case 'quarterly':
        // 3 months
        return [
          const FlSpot(0, 5),
          const FlSpot(1, 6),
          const FlSpot(2, 5.5),
        ];
      case 'yearly':
        // 4 quarters
        return [
          const FlSpot(0, 5.5),
          const FlSpot(1, 6),
          const FlSpot(2, 6.5),
          const FlSpot(3, 7),
        ];
      default:
        return [];
    }
  }

  List<String> _getBottomTitles(String timeframe, double value) {
    switch (timeframe) {
      case 'weekly':
        const titles = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        return [titles[value.toInt()]];
      case 'monthly':
        const titles = ['Week 1', 'Week 2', 'Week 3', 'Week 4'];
        if (value.toInt() < titles.length) return [titles[value.toInt()]];
        return [];
      case 'quarterly':
        const titles = ['Month 1', 'Month 2', 'Month 3'];
        if (value.toInt() < titles.length) return [titles[value.toInt()]];
        return [];
      case 'yearly':
        const titles = ['Q1', 'Q2', 'Q3', 'Q4'];
        if (value.toInt() < titles.length) return [titles[value.toInt()]];
        return [];
      default:
        return [];
    }
  }

  double _getMaxX(String timeframe) {
    switch (timeframe) {
      case 'weekly':
        return 6;
      case 'monthly':
        return 3;
      case 'quarterly':
        return 2;
      case 'yearly':
        return 3;
      default:
        return 0;
    }
  }

  double _getIntervalX(String timeframe) {
    switch (timeframe) {
      case 'weekly':
        return 1;
      case 'monthly':
        return 1;
      case 'quarterly':
        return 1;
      case 'yearly':
        return 1;
      default:
        return 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final spots = _generateMoodSpots(timeframe);
    final maxX = _getMaxX(timeframe);
    final intervalX = _getIntervalX(timeframe);

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
              'Mood Trend (${timeframe[0].toUpperCase()}${timeframe.substring(1)})',
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
                        interval: 1,
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
                  minY: 0,
                  maxY: 8,
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
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
  const IngredientImpactSection({super.key, required this.timeframe});

  // Fake data for ingredient impact based on timeframe
  List<Map<String, String>> _generateImpactData(String timeframe) {
    switch (timeframe) {
      case 'weekly':
        return [
          {'ingredient': 'Avocado', 'impact': '👍 85% Good'},
          {'ingredient': 'Cheese', 'impact': '👎 70% Bad'},
          {'ingredient': 'Banana', 'impact': '👍 75% Good'},
          {'ingredient': 'Salmon', 'impact': '👍 90% Good'},
          {'ingredient': 'Sugar', 'impact': '👎 80% Bad'},
          {'ingredient': 'Berries', 'impact': '👍 88% Good'},
        ];
      case 'monthly':
        return [
          {'ingredient': 'Broccoli', 'impact': '👍 80% Good'},
          {'ingredient': 'Rice', 'impact': '👍 70% Good'},
          {'ingredient': 'Chicken Breast', 'impact': '👍 95% Good'},
          {'ingredient': 'Sugar', 'impact': '👎 85% Bad'},
        ];
      case 'quarterly':
        return [
          {'ingredient': 'Salmon', 'impact': '👍 92% Good'},
          {'ingredient': 'Berries', 'impact': '👍 90% Good'},
          {'ingredient': 'Cheese', 'impact': '👎 75% Bad'},
        ];
      case 'yearly':
        return [
          {'ingredient': 'Avocado', 'impact': '👍 88% Good'},
          {'ingredient': 'Salmon', 'impact': '👍 93% Good'},
          {'ingredient': 'Sugar', 'impact': '👎 78% Bad'},
        ];
      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final impactData = _generateImpactData(timeframe);

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
  const WeeklyStatsSection({super.key, required this.timeframe});

  // Fake data for weekly stats based on timeframe
  Map<String, String> _generateStatsData(String timeframe) {
    switch (timeframe) {
      case 'weekly':
        return {
          'Average Mood': '6.2/10',
          'Most Logged Ingredient': 'Water (56 times)',
        };
      case 'monthly':
        return {
          'Average Mood': '6.5/10',
          'Most Logged Ingredient': 'Water (210 times)',
        };
      case 'quarterly':
        return {
          'Average Mood': '6.8/10',
          'Most Logged Ingredient': 'Water (600 times)',
        };
      case 'yearly':
        return {
          'Average Mood': '7.0/10',
          'Most Logged Ingredient': 'Water (2200 times)',
        };
      default:
        return {};
    }
  }

  @override
  Widget build(BuildContext context) {
    final statsData = _generateStatsData(timeframe);

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

class IngredientDiversityGraph extends StatelessWidget {
  final String timeframe;
  const IngredientDiversityGraph({super.key, required this.timeframe});

  // Fake data generation based on timeframe
  List<FlSpot> _generateDiversitySpots(String timeframe) {
    switch (timeframe) {
      case 'weekly':
        // 7 days
        return [
          const FlSpot(0, 10),
          const FlSpot(1, 12),
          const FlSpot(2, 11),
          const FlSpot(3, 15),
          const FlSpot(4, 13),
          const FlSpot(5, 14),
          const FlSpot(6, 16),
        ];
      case 'monthly':
        // 4 weeks
        return [
          const FlSpot(0, 15),
          const FlSpot(1, 18),
          const FlSpot(2, 17),
          const FlSpot(3, 20),
        ];
      case 'quarterly':
        // 3 months
        return [
          const FlSpot(0, 20),
          const FlSpot(1, 25),
          const FlSpot(2, 23),
        ];
      case 'yearly':
        // 4 quarters
        return [
          const FlSpot(0, 25),
          const FlSpot(1, 30),
          const FlSpot(2, 28),
          const FlSpot(3, 35),
        ];
      default:
        return [];
    }
  }

  List<String> _getBottomTitles(String timeframe, double value) {
    switch (timeframe) {
      case 'weekly':
        const titles = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        return [titles[value.toInt()]];
      case 'monthly':
        const titles = ['Week 1', 'Week 2', 'Week 3', 'Week 4'];
        if (value.toInt() < titles.length) return [titles[value.toInt()]];
        return [];
      case 'quarterly':
        const titles = ['Month 1', 'Month 2', 'Month 3'];
        if (value.toInt() < titles.length) return [titles[value.toInt()]];
        return [];
      case 'yearly':
        const titles = ['Q1', 'Q2', 'Q3', 'Q4'];
        if (value.toInt() < titles.length) return [titles[value.toInt()]];
        return [];
      default:
        return [];
    }
  }

  double _getMaxX(String timeframe) {
    switch (timeframe) {
      case 'weekly':
        return 6;
      case 'monthly':
        return 3;
      case 'quarterly':
        return 2;
      case 'yearly':
        return 3;
      default:
        return 0;
    }
  }

  double _getIntervalX(String timeframe) {
    switch (timeframe) {
      case 'weekly':
        return 1;
      case 'monthly':
        return 1;
      case 'quarterly':
        return 1;
      case 'yearly':
        return 1;
      default:
        return 1;
    }
  }

  double _getMaxY(String timeframe) {
    switch (timeframe) {
      case 'weekly':
        return 20;
      case 'monthly':
        return 25;
      case 'quarterly':
        return 30;
      case 'yearly':
        return 40;
      default:
        return 20;
    }
  }

  @override
  Widget build(BuildContext context) {
    final diversitySpots = _generateDiversitySpots(timeframe);
    final maxX = _getMaxX(timeframe);
    final intervalX = _getIntervalX(timeframe);
    final maxY = _getMaxY(timeframe);

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
              'Ingredient Variety Over Time (${timeframe[0].toUpperCase()}${timeframe.substring(1)})',
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
                      spots: diversitySpots,
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
  const LoggingStreakCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 300,
        child: Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(12)), // Consistent rounded corners
          color: Color.fromARGB(255, 45, 190, 120),
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
                  '🎉 21-day streak! Keep it up!',
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge, // Consistent body text style
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class IngredientSearchSection extends StatelessWidget {
  const IngredientSearchSection({super.key});

  @override
  Widget build(BuildContext context) {
    // Fake list of popular ingredients for search results
    const List<String> popularIngredients = [
      'Chicken Breast',
      'Broccoli',
      'Rice',
      'Eggs',
      'Milk',
      'Bread',
      'Apple',
      'Salmon',
    ];

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
        // Displaying fake popular ingredients as a placeholder for search results
        Column(
          // Use Column to display the list of ingredients
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
        ),
      ],
    );
  }
}
