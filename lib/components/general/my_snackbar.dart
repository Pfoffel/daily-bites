import 'package:flutter/material.dart';

SnackBar mySnackBar(BuildContext context, String message, String buttonLabel,
    void Function()? onPressed) {
  return SnackBar(
    content: Container(
      padding: EdgeInsets.symmetric(vertical: 5, horizontal: 20),
      margin: EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Color.fromARGB(255, 45, 190, 120),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            message,
            style: Theme.of(context).textTheme.labelSmall,
          ),
          ElevatedButton(
            onPressed: onPressed,
            style: ButtonStyle(
              backgroundColor:
                  WidgetStatePropertyAll(Color.fromARGB(255, 9, 37, 29)),
            ),
            child: Text(
              buttonLabel,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
        ],
      ),
    ),
    behavior: SnackBarBehavior.floating,
    duration: const Duration(seconds: 3),
    backgroundColor: Colors.transparent,
  );
}

void showMySnackBar(BuildContext context, String message, String buttonLabel,
    void Function()? onPressed) {
  ScaffoldMessenger.of(context)
      .showSnackBar(mySnackBar(context, message, buttonLabel, onPressed));
}
