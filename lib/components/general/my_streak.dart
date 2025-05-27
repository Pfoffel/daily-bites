import 'package:flutter/material.dart';

class MyStreak extends StatelessWidget {
  final int streakCount;

  const MyStreak({super.key, required this.streakCount});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/survey_page');
      },
      child: Container(
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 45, 190, 120),
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const Icon(
                Icons.fire_extinguisher,
                shadows: [],
              ),
              const SizedBox(width: 10),
              Text(
                streakCount.toString(),
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          )),
    );
  }
}
