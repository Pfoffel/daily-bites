import 'package:flutter/material.dart';

class MacroInfoPage extends StatelessWidget {
  const MacroInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Info", style: Theme.of(context).textTheme.labelLarge),
      ),
    );
  }
}