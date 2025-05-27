import 'package:flutter/material.dart';

class MySettingsTile extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const MySettingsTile({super.key, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return ListTile(
        title: Text(
          title,
          style: Theme.of(context).textTheme.labelMedium,
        ),
        trailing: trailing);
  }
}
