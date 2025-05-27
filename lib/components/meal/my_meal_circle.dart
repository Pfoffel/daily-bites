import 'package:flutter/material.dart';

class MyMealCircle extends StatelessWidget {

  final String imgUrl;

  const MyMealCircle({super.key,
    required this.imgUrl
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(right: 20),
      padding: EdgeInsets.all(5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white,
          width: 2,
        ),
      ),
      child: CircleAvatar(
      radius: 25,
        backgroundColor: const Color.fromARGB(255, 9, 37, 29),
        backgroundImage: NetworkImage(imgUrl),
      ),
    );
  }
}