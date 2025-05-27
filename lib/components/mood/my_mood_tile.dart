import 'package:flutter/material.dart';
import 'package:health_app_v1/models/mood.dart';
import 'package:health_app_v1/models/recipe_list.dart';
import 'package:provider/provider.dart';

// ignore: must_be_immutable
class MyMoodTile extends StatelessWidget {

  final double height;
  final String title;
  final int categoryIndex;
  final EdgeInsets margin;
  final List<String> symbols;
  int selectedIndex;
  final bool tapable;  

  MyMoodTile({super.key,
    required this.height,
    required this.title,
    this.categoryIndex = -1,
    required this.margin,
    required this.symbols,
    this.selectedIndex = -1,
    this.tapable = true,    
  });

  @override
  Widget build(BuildContext context) {

    return Consumer<RecipeList>(
      builder: (context, value, child) {
        return Container(
          height: height,
          margin: margin,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [BoxShadow(
              blurRadius: 2,
              offset: Offset(2, 2)
            ),],
            color: const Color.fromARGB(255, 9, 37, 29),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 20, top: 10),
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              SizedBox(height: 10,),
              Container(
                height: 80,
                margin: const EdgeInsets.symmetric(horizontal: 20),
                clipBehavior: Clip.antiAlias,
                // padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(symbols.length, (index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: tapable
                      ? GestureDetector(
                        onTap: () {
                          if (selectedIndex == index) {
                            context.read<Mood>().updateScore(categoryIndex, -1);
                            // context.read<Mood>().updateTotalScore();
                          } else {
                            context.read<Mood>().updateScore(categoryIndex, index);
                            // context.read<Mood>().updateTotalScore();
                          }
                        },
                        child: Text(
                          symbols[index],
                          style: TextStyle(
                            fontSize: selectedIndex == index
                              ? 50
                              : 35
                          ),
                        ),
                      )
                      : Text(
                        symbols[index],
                        style: TextStyle(
                          fontSize: selectedIndex == index
                            ? 50
                            : 35
                        ),
                      ),
                    );
                  },),
                )
              ),
            ],
          ),
        );
      },
    );
  }
}