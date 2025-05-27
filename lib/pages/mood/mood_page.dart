import 'package:flutter/material.dart';
import 'package:health_app_v1/components/mood/my_mood_tile.dart';
import 'package:health_app_v1/models/mood.dart';
import 'package:provider/provider.dart';

class MoodPage extends StatefulWidget {
  const MoodPage({super.key});

  @override
  State<MoodPage> createState() => _MoodPageState();
}

class _MoodPageState extends State<MoodPage> {
  @override
  Widget build(BuildContext context) {

    final List<dynamic> categories = context.watch<Mood>().categories;
    final List<String> symbols = ["😢", "🥺", "😐", "😊", "😆"];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Mood',
          style: Theme.of(context).textTheme.labelLarge,
        ),
      ),
      body: ListView.builder(
        itemCount: categories.length,
        itemBuilder: (context, index) {
          return MyMoodTile(
            height: 180, 
            title: categories[index]['title'], 
            selectedIndex: categories[index]['score'],
            categoryIndex: index,
            margin: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            symbols: symbols,
          );
      },),
    );
  }
}