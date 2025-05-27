import 'package:flutter/material.dart';
import 'package:health_app_v1/components/meal/my_macronutrient.dart';
import 'package:health_app_v1/models/user_settings.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

// ignore: must_be_immutable
class MyMacroTile extends StatelessWidget {
  final double amount;
  final String type;

  const MyMacroTile({
    super.key,
    required this.amount,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    final NumberFormat numberFormat = NumberFormat('0.0');
    bool goalEnabled = context.watch<UserSettings>().goalsEnabled;
    return Container(
        margin: EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Color.fromARGB(255, 9, 37, 29),
        ),
        height: 115,
        child: goalEnabled
            ? MyMacronutrient(
                type: type,
                amount: amount,
              )
            : Center(
                child: Text(
                  '${numberFormat.format(amount)}g\n$type',
                  style: Theme.of(context).textTheme.labelSmall,
                  textAlign: TextAlign.center,
                ),
              ));
  }
}
