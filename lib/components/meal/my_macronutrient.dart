import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

class MyMacronutrient extends StatelessWidget {
  final String type;
  final double amount;

  const MyMacronutrient({
    super.key,
    required this.type,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic> goals = {
      'Carbs': 1.0,
      'Proteins': 1.0,
      'Fats': 1.0,
    };
    final double goal = goals[type];
    bool isOverachieved = amount > goal;
    return Padding(
      padding: const EdgeInsets.all(5),
      child: CircularPercentIndicator(
        // 11.97, 1.98, 0.88
        radius: 50,
        percent: (amount % goal),
        circularStrokeCap: CircularStrokeCap.round,
        progressColor: isOverachieved
            ? Colors.red[900]
            : Color.fromARGB(255, 45, 190, 120),
        lineWidth: 10,
        backgroundColor: isOverachieved
            ? Color.fromARGB(255, 45, 190, 120)
            : Color.fromARGB(255, 6, 23, 18),
        center: Text(
          type,
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ),
    );
  }
}
