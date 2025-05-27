import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CurrentDate extends ChangeNotifier {
  String _currentDateStr = "Today";
  DateTime _currentDate = DateTime.now();

  String get currentDateStr => _currentDateStr;
  String get currentDate => _getFormatedDate(_currentDate);
  String get sanitizedDate => _getSanitizedDate(_currentDate);

  String nextDay() {
    _currentDate = _currentDate.add(Duration(days: 1));
    if (_getFormatedDate(_currentDate) == _getFormatedDate(DateTime.now())) {
      _currentDateStr = "Today";
    } else {
      switch (_currentDate.weekday) {
        case 1:
          _currentDateStr = 'Mon';
        case 2:
          _currentDateStr = 'Tue';
        case 3:
          _currentDateStr = 'Wed';
        case 4:
          _currentDateStr = 'Thu';
        case 5:
          _currentDateStr = 'Fri';
        case 6:
          _currentDateStr = 'Sat';
        case 7:
          _currentDateStr = 'Sun';
        default:
          _currentDateStr = 'Unknown';
      }
    }
    notifyListeners();
    return _getSanitizedDate(_currentDate);
  }

  String previousDay() {
    _currentDate = _currentDate.subtract(Duration(days: 1));
    if (_getFormatedDate(_currentDate) == _getFormatedDate(DateTime.now())) {
      _currentDateStr = "Today";
    } else {
      switch (_currentDate.weekday) {
        case 1:
          _currentDateStr = 'Mon';
        case 2:
          _currentDateStr = 'Tue';
        case 3:
          _currentDateStr = 'Wed';
        case 4:
          _currentDateStr = 'Thu';
        case 5:
          _currentDateStr = 'Fri';
        case 6:
          _currentDateStr = 'Sat';
        case 7:
          _currentDateStr = 'Sun';
        default:
          _currentDateStr = 'Unknown';
      }
    }
    notifyListeners();
    return _getSanitizedDate(_currentDate);
  }

  String getDate(int days) {
    final DateTime newDate = _currentDate.add(Duration(days: days));
    print("new Date $newDate");
    return DateFormat('yyyy-MM-dd').format(newDate);
  }

  String _getFormatedDate(date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  String _getSanitizedDate(date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  void signOut() {
    _currentDateStr = "Today";
    _currentDate = DateTime.now();
  }
}
