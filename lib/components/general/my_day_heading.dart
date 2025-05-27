import 'package:flutter/material.dart';
import 'package:health_app_v1/models/current_date.dart';
import 'package:provider/provider.dart';

// ignore: must_be_immutable
class MyDayHeading extends StatelessWidget {

  void Function()? previousDay;
  void Function()? nextDay;

  MyDayHeading(
    {
      super.key,
      required this.previousDay,
      required this.nextDay,
    }
    );

  @override
  Widget build(BuildContext context) {

    return Consumer<CurrentDate>(
      builder: (context, value, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: previousDay,
              icon: Icon(Icons.chevron_left_rounded),
            ),
            Text(
              value.currentDateStr,
              style: Theme.of(context).textTheme.displayLarge
            ),
            IconButton(
              onPressed: nextDay,
              icon: Icon(Icons.chevron_right_rounded)
            ),
          ],
        );
      }
    );
  }
}