import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:health_app_v1/models/current_date.dart';
import 'package:health_app_v1/models/mood.dart';
import 'package:health_app_v1/models/recipe_list.dart';
import 'package:health_app_v1/service/connect_db.dart';
import 'package:provider/provider.dart';

class MyDrawer extends StatelessWidget {
  const MyDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
        backgroundColor: const Color.fromARGB(255, 6, 23, 18),
        child: Column(
          children: [
            const DrawerHeader(
                child: Icon(
              Icons.fitness_center,
              size: 72,
              color: Color.fromARGB(255, 45, 190, 120),
            )),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 30),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.chat),
                          title: Text(
                            "Notifications",
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.pushNamed(context, '/notification_page');
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.home),
                          title: Text(
                            "Home",
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                          onTap: () => Navigator.pop(context),
                        ),
                        ListTile(
                          leading: const Icon(Icons.calendar_month),
                          title: Text(
                            "Calendar",
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.pushNamed(context, '/calendar_page');
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.insert_chart_outlined),
                          title: Text(
                            "Trends",
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.pushNamed(context, '/trends_page');
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.settings),
                          title: Text(
                            "Settings",
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.pushNamed(context, '/settings_page');
                          },
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: ListTile(
                      leading: const Icon(Icons.logout_rounded),
                      title: Text(
                        "Log Out",
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, "/main_page");
                        Provider.of<ConnectDb>(context, listen: false)
                            .signOut();
                        Provider.of<RecipeList>(context, listen: false)
                            .signOut();
                        Provider.of<CurrentDate>(context, listen: false)
                            .signOut();
                        Provider.of<Mood>(context, listen: false).signOut();
                        FirebaseAuth.instance.signOut();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ));
  }
}
