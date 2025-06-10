import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart'; // For date formatting

class ProcessedChartData {
  final List<FlSpot> spots;
  final double maxX;
  final Map<int, String> bottomTitles; // Key: x-axis index, Value: Label
  final double intervalX;

  ProcessedChartData({
    required this.spots,
    required this.maxX,
    required this.bottomTitles,
    this.intervalX = 1.0,
  });
}

class TrendChartUtils {
  static ProcessedChartData processDataForChart({
    required String timeframe,
    required List<Map<String, dynamic>> dailyEntries,
    required DateTime overallStartDate, // Actual start date of the fetched data range
    required DateTime overallEndDate,   // Actual end date of the fetched data range
    required double Function(List<Map<String, dynamic>> dailyDataForPeriod) dataAggregator,
  }) {
    List<FlSpot> spots = [];
    Map<int, String> bottomTitles = {};
    double maxX = 0;
    double intervalX = 1.0;

    if (dailyEntries.isEmpty) {
      return ProcessedChartData(spots: [], maxX: 0, bottomTitles: {});
    }

    // Normalize overallStartDate and overallEndDate to midnight for consistent comparison
    overallStartDate = DateTime(overallStartDate.year, overallStartDate.month, overallStartDate.day);
    overallEndDate = DateTime(overallEndDate.year, overallEndDate.month, overallEndDate.day, 23, 59, 59);


    switch (timeframe) {
      case 'weekly':
        // Display 7 days, ending with overallEndDate
        // The actual startDate for weekly view should be overallEndDate.subtract(days:6)
        DateTime weekViewStartDate = overallEndDate.subtract(const Duration(days: 6));
        weekViewStartDate = DateTime(weekViewStartDate.year, weekViewStartDate.month, weekViewStartDate.day);


        for (int i = 0; i < 7; i++) {
          DateTime currentDay = weekViewStartDate.add(Duration(days: i));
          List<Map<String, dynamic>> entriesForDay = dailyEntries.where((entry) {
            DateTime entryDate = DateTime.parse(entry['date']);
            entryDate = DateTime(entryDate.year, entryDate.month, entryDate.day);
            return entryDate.isAtSameMomentAs(currentDay);
          }).toList();

          double aggregatedValue = dataAggregator(entriesForDay);
          spots.add(FlSpot(i.toDouble(), aggregatedValue));
          bottomTitles[i] = DateFormat.E().format(currentDay); // Mon, Tue
        }
        maxX = 6;
        intervalX = 1;
        break;

      case 'monthly':
        // Display 4 weeks, with each week ending on overallEndDate, (endDate - 1w), etc.
        // Or, more robustly, group by ISO weeks within the month of overallEndDate.
        // For simplicity here, let's consider weeks leading up to overallEndDate.
        // Number of weeks in the month of overallEndDate:
        // This needs to align with how _TrendsPageState defines 'monthly' (e.g., last 30 days or calendar month)
        // Assuming 'monthly' means roughly the last 4 weeks ending on overallEndDate for now.

        // Let's determine the start of the 4-week period
        DateTime monthViewStartDate = overallEndDate.subtract(Duration(days: 4 * 7 - 1)); // Approx 4 weeks
        monthViewStartDate = DateTime(monthViewStartDate.year, monthViewStartDate.month, monthViewStartDate.day);


        for (int i = 0; i < 4; i++) { // 4 weeks
          DateTime weekStartDate = monthViewStartDate.add(Duration(days: i * 7));
          DateTime weekEndDate = weekStartDate.add(const Duration(days: 6));

          List<Map<String, dynamic>> entriesForWeek = dailyEntries.where((entry) {
            DateTime entryDate = DateTime.parse(entry['date']);
            entryDate = DateTime(entryDate.year, entryDate.month, entryDate.day);
            return !entryDate.isBefore(weekStartDate) && !entryDate.isAfter(weekEndDate);
          }).toList();

          double aggregatedValue = dataAggregator(entriesForWeek);
          spots.add(FlSpot(i.toDouble(), aggregatedValue));
          bottomTitles[i] = 'Wk ${i + 1}';
        }
        maxX = 3;
        intervalX = 1;
        break;

      case 'quarterly':
        // Display 3 months, ending with overallEndDate's month.
        // The quarter is defined by overallEndDate.
        int endMonth = overallEndDate.month;
        int endYear = overallEndDate.year;

        // Determine the months of the quarter
        List<DateTime> quarterMonthStarts = [];
        if (endMonth >= 1 && endMonth <= 3) { // Q1
          quarterMonthStarts = [DateTime(endYear, 1, 1), DateTime(endYear, 2, 1), DateTime(endYear, 3, 1)];
        } else if (endMonth >= 4 && endMonth <= 6) { // Q2
          quarterMonthStarts = [DateTime(endYear, 4, 1), DateTime(endYear, 5, 1), DateTime(endYear, 6, 1)];
        } else if (endMonth >= 7 && endMonth <= 9) { // Q3
          quarterMonthStarts = [DateTime(endYear, 7, 1), DateTime(endYear, 8, 1), DateTime(endYear, 9, 1)];
        } else { // Q4
          quarterMonthStarts = [DateTime(endYear, 10, 1), DateTime(endYear, 11, 1), DateTime(endYear, 12, 1)];
        }

        for (int i = 0; i < 3; i++) {
          DateTime monthStartDate = quarterMonthStarts[i];
          DateTime monthEndDate = DateTime(monthStartDate.year, monthStartDate.month + 1, 0); // Last day of month

          List<Map<String, dynamic>> entriesForMonth = dailyEntries.where((entry) {
            DateTime entryDate = DateTime.parse(entry['date']);
            entryDate = DateTime(entryDate.year, entryDate.month, entryDate.day);
            return !entryDate.isBefore(monthStartDate) && !entryDate.isAfter(monthEndDate);
          }).toList();

          double aggregatedValue = dataAggregator(entriesForMonth);
          spots.add(FlSpot(i.toDouble(), aggregatedValue));
          bottomTitles[i] = DateFormat.MMM().format(monthStartDate); // Jan, Feb
        }
        maxX = 2;
        intervalX = 1;
        break;

      case 'yearly':
        // Display 4 quarters of the year ending with overallEndDate's quarter.
        int endYear = overallEndDate.year;
        for (int i = 0; i < 4; i++) { // Q1, Q2, Q3, Q4
          DateTime quarterStartDate = DateTime(endYear, i * 3 + 1, 1);
          DateTime quarterEndDate = DateTime(endYear, (i + 1) * 3 + 1, 0); // Last day of last month of quarter

          List<Map<String, dynamic>> entriesForQuarter = dailyEntries.where((entry) {
            DateTime entryDate = DateTime.parse(entry['date']);
            entryDate = DateTime(entryDate.year, entryDate.month, entryDate.day);
            return !entryDate.isBefore(quarterStartDate) && !entryDate.isAfter(quarterEndDate);
          }).toList();

          double aggregatedValue = dataAggregator(entriesForQuarter);
          spots.add(FlSpot(i.toDouble(), aggregatedValue));
          bottomTitles[i] = 'Q${i + 1}';
        }
        maxX = 3;
        intervalX = 1;
        break;

      default:
        // Should not happen if timeframe is validated, but default to weekly-like if it does
         DateTime defaultStartDate = overallEndDate.subtract(const Duration(days: 6));
         defaultStartDate = DateTime(defaultStartDate.year, defaultStartDate.month, defaultStartDate.day);
        for (int i = 0; i < 7; i++) {
           DateTime currentDay = defaultStartDate.add(Duration(days: i));
           List<Map<String, dynamic>> entriesForDay = dailyEntries.where((entry) {
            DateTime entryDate = DateTime.parse(entry['date']);
            entryDate = DateTime(entryDate.year, entryDate.month, entryDate.day);
            return entryDate.isAtSameMomentAs(currentDay);
          }).toList();
          spots.add(FlSpot(i.toDouble(), dataAggregator(entriesForDay)));
          bottomTitles[i] = DateFormat.E().format(currentDay);
        }
        maxX = 6;
    }

    // Ensure spots are sorted by x-value, especially if date iteration logic changes
    spots.sort((a, b) => a.x.compareTo(b.x));

    return ProcessedChartData(
      spots: spots,
      maxX: maxX,
      bottomTitles: bottomTitles,
      intervalX: intervalX,
    );
  }
}

// Example aggregators (can be defined elsewhere or passed anonymously)
// double aggregateMoodScores(List<Map<String, dynamic>> dailyMoodEntriesForPeriod) {
//   if (dailyMoodEntriesForPeriod.isEmpty) return 0;
//   double periodTotalScore = 0;
//   int daysWithMoodsInPeriod = 0;
//   for (var dayEntry in dailyMoodEntriesForPeriod) {
//     if (dayEntry['moods'] == null) continue;
//     List dailyMoods = dayEntry['moods'];
//     double singleDayTotalScore = 0;
//     int singleDayMoodCount = 0;
//     for (var mood in dailyMoods) {
//       if (mood['score'] != null && mood['score'] != -1) {
//         singleDayTotalScore += mood['score'];
//         singleDayMoodCount++;
//       }
//     }
//     if (singleDayMoodCount > 0) {
//       periodTotalScore += (singleDayTotalScore / singleDayMoodCount);
//       daysWithMoodsInPeriod++;
//     }
//   }
//   return daysWithMoodsInPeriod > 0 ? periodTotalScore / daysWithMoodsInPeriod : 0;
// }

// double aggregateRecipeDiversity(List<Map<String, dynamic>> dailyMealEntriesForPeriod) {
//   if (dailyMealEntriesForPeriod.isEmpty) return 0;
//   Set<String> uniqueRecipeIdsInPeriod = {};
//   for (var dayEntry in dailyMealEntriesForPeriod) {
//      if (dayEntry['meals'] == null) continue;
//     List dailyMeals = dayEntry['meals'];
//     for (var meal in dailyMeals) {
//        if (meal['recipes'] == null) continue;
//       List recipeIds = meal['recipes'];
//       for (var id in recipeIds) {
//         uniqueRecipeIdsInPeriod.add(id.toString());
//       }
//     }
//   }
//   return uniqueRecipeIdsInPeriod.length.toDouble();
// }
