import 'package:flutter/material.dart';
import 'package:health_app_v1/models/user_settings.dart';
import 'package:health_app_v1/service/notifications_service.dart';
import 'package:provider/provider.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  Future<void> _scheduleTime(
      BuildContext context, String key, TimeOfDay? selectedTime) async {
    final TimeOfDay? pickedTime = await showTimePicker(
        context: context, initialTime: selectedTime ?? TimeOfDay.now());
    if (pickedTime != null && pickedTime != selectedTime) {
      setState(() {
        selectedTime = pickedTime;
        Provider.of<UserSettings>(context, listen: false)
            .updateTime(key, pickedTime);
        NotificationsService.scheduleNotification(key, pickedTime, 0);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic> schedule = context.watch<UserSettings>().schedule;
    List entries = schedule.entries.toList();

    return Scaffold(
      appBar: AppBar(
        title: Text("Notifications",
            style: Theme.of(context).textTheme.labelLarge),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: ListView.builder(
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              String title = entry.key;
              TimeOfDay? time = entry.value;
              return Column(
                children: [
                  Text(
                    time != null
                        ? "Selected $title Time: ${time.format(context)}"
                        : 'No time selected for $title Reminder',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  ElevatedButton(
                      onPressed: () => _scheduleTime(context, title, time),
                      child: Text(
                        'Update Streak Time',
                        style: Theme.of(context).textTheme.labelMedium,
                      )),
                  SizedBox(
                    height: 10,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
