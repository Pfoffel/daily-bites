import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationsService {
  static final Map<String, dynamic> _scheduleIDs = {
    'Streak': 0,
    'Breakfast': 10,
    'Lunch': 20,
    'Dinner': 30,
  };

  static final Map<String, dynamic> _notificationMessage = {
    'Streak': {
      'title': 'Streak Reminder',
      'body': 'Fill in all your meals for today!',
    },
    'Breakfast': {
      'title': 'Breakfast Reminder',
      'body': 'What are you having for Breakfast?',
    },
    'Lunch': {
      'title': 'Lunch Reminder',
      'body': 'What are you having for Lunch?',
    },
    'Dinner': {
      'title': 'Dinner Reminder',
      'body': 'What are you having for Dinner?',
    },
  };

  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static Future<void> onDidReceiveNotification(
      NotificationResponse notificationResponse) async {}

  static Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: onDidReceiveNotification,
      onDidReceiveBackgroundNotificationResponse: onDidReceiveNotification,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  static Future<void> showNotification(String title, String body) async {
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: AndroidNotificationDetails(
          "daily_reminder_channel", "Daily_Reminders",
          importance: Importance.max, priority: Priority.high),
    );
    await flutterLocalNotificationsPlugin.show(
        0, title, body, platformChannelSpecifics);
  }

  static Future<void> showScheduledNotification(
      String title, String body, DateTime scheduledDate) async {
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: AndroidNotificationDetails(
          "daily_reminder_channel", "Daily_Reminders",
          importance: Importance.high, priority: Priority.high),
    );
    await flutterLocalNotificationsPlugin.zonedSchedule(
      1,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      platformChannelSpecifics,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  static Future<void> scheduleNotification(
      String key, TimeOfDay streakTime, int startDay) async {
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: AndroidNotificationDetails(
          "daily_reminder_channel", "Daily_Reminders",
          importance: Importance.high, priority: Priority.high),
    );
    DateTime today = DateTime.now();
    DateTime scheduledDate = DateTime(today.year, today.month,
        today.day + startDay, streakTime.hour, streakTime.minute);
    if (scheduledDate.isBefore(today)) {
      scheduledDate = DateTime(today.year, today.month, today.day + 1,
          streakTime.hour, streakTime.minute);
    }

    int days = 0;
    final Map<String, dynamic> notification = _notificationMessage[key];
    final String title = notification['title'];
    final String body = notification['body'];
    for (var i = _scheduleIDs[key]; i < _scheduleIDs[key] + 7; i++) {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        i,
        title,
        body,
        tz.TZDateTime.from(scheduledDate.add(Duration(days: days)), tz.local),
        platformChannelSpecifics,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.exact,
      );
      days++;
    }
  }

  static Future<bool> isMealDataComplete(String uid) async {
    final formattedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

    final snapshot =
        await FirebaseFirestore.instance.collection('meals').doc(uid).get();

    if (!snapshot.exists) return false;

    final data = snapshot.data();
    if (data == null) return false;

    final meals = data[formattedDate] as List?;
    if (meals == null || meals.isEmpty) return false;

    for (final Map<String, dynamic> meal in meals) {
      if (meal['recipes']!.isEmpty) return false;
    }

    return true;
  }

  static Future<bool> isNotificationScheduled(int id) async {
    List<PendingNotificationRequest> pendingNotifications =
        await flutterLocalNotificationsPlugin.pendingNotificationRequests();
    final bool found =
        pendingNotifications.any((notification) => notification.id == id);
    // print('is scheduled: $found');
    // for (var notification in pendingNotifications) {
    //   print('${notification.id}, title: ${notification.title}');
    // }
    return found;
  }

  static Future<void> cancelNotification() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }
}
