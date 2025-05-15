// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  int _counter = 0;

  void _increaseCounter(){

    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("You have touched this many times:"),
            Text(
              _counter.toString(),
              style: TextStyle(
                fontSize: 40
              ),
            ),
            FloatingActionButton(
              onPressed: _increaseCounter, 
              child: Text("+")
            ),
          ],
        ),
      ),
    );
  }
}