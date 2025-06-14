import 'package:flutter/material.dart';
import 'package:health_app_v1/components/settings/my_settings_tile.dart';
import 'package:health_app_v1/models/user_settings.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Settings", style: Theme.of(context).textTheme.labelLarge),
      ),
      body: Consumer<UserSettings>(
        builder: (context, userSettings, child) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
            child: ListView(
              children: [
                MySettingsTile(
                  title: 'Goals',
                  trailing: Switch(
                    value: userSettings.goalsEnabled,
                    onChanged: (newValue) {
                      userSettings.updateGoals('enabled', newState: newValue);
                    },
                  ),
                ),
                MySettingsTile(
                    title: 'Personaize Experience',
                    trailing: ElevatedButton(
                        onPressed: () => Navigator.pushNamed(
                            context, '/survey_page',
                            arguments: {'source': 'settings'}),
                        child: Text(
                          'Update',
                          style: Theme.of(context).textTheme.labelSmall,
                        ))),
              ],
            ),
          );
        },
      ),
    );
  }
}
