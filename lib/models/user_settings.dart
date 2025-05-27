import 'package:flutter/material.dart';
import 'package:health_app_v1/service/connect_db.dart';

class UserSettings extends ChangeNotifier {
  Map<String, dynamic> _schedule = {};
  Map<String, dynamic> _goals = {};

  bool _initialized = false;

  Map<String, dynamic> get schedule => _schedule;
  Map<String, dynamic> get goals => _goals;
  bool get goalsEnabled => _goals['enabled'] ?? false;

  void initializeSettings(
      Map<String, dynamic> newSchedule, Map<String, dynamic> newGoals) {
    if (!_initialized) {
      Map<String, dynamic> updatedSchedule = {};
      for (var category in newSchedule.keys) {
        final List timeSplit = newSchedule[category].toString().split(':');
        updatedSchedule[category] = TimeOfDay(
            hour: int.parse(timeSplit[0]), minute: int.parse(timeSplit[1]));
      }
      _schedule = updatedSchedule;
      _goals = newGoals;
      _initialized = true;
      notifyListeners();
    }
  }

  Map<String, dynamic> toMap() {
    Map<String, dynamic> scheduleMap = {};
    for (var key in _schedule.keys) {
      String hour = _schedule[key].hour.toString();
      String minute = _schedule[key].minute.toString();
      scheduleMap.addEntries({key: '$hour:$minute'}.entries);
    }
    return scheduleMap;
  }

  void updateTime(String key, TimeOfDay newTime) {
    _schedule.update(key, (value) => newTime);
    Map<String, dynamic> updatedSchedule = toMap();
    ConnectDb().updateSettings(updatedSchedule, _goals);
    notifyListeners();
  }

  void updateGoals(String key, {double? newGoal, bool? newState}) {
    if (newGoal != null) {
      _goals.update(
        key,
        (value) => newGoal,
      );
    } else if (newState != null) {
      _goals.update(
        key,
        (value) => newState,
      );
    } else {
      throw Exception('Argument missing');
    }
    ConnectDb().updateSettings(toMap(), _goals);
    notifyListeners();
  }

  void logout() {
    _schedule.clear();
    _initialized = false;
  }
}
