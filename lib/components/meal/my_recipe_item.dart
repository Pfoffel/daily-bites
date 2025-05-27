import 'package:flutter/material.dart';

// ignore: must_be_immutable
class MyRecipeItem extends StatelessWidget {
  final String title;
  final String imgUrl;
  final IconData icon;
  void Function()? onPressed;
  void Function()? onTap;

  MyRecipeItem({
    super.key,
    required this.title,
    required this.imgUrl,
    required this.icon,
    required this.onPressed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 15, horizontal: 30),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: const Color.fromARGB(255, 9, 37, 29),
        ),
        child: Row(
          children: [
            Container(
              height: 90,
              width: 90,
              margin: EdgeInsets.only(right: 15),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                image: DecorationImage(
                  image: NetworkImage(imgUrl),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.labelMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis, // Avoids text overflow
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: IconButton(
                onPressed: onPressed,
                icon: Icon(
                  icon,
                  color: Color.fromARGB(255, 45, 190, 120),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
