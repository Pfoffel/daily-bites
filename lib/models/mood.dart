import 'package:flutter/material.dart';
import 'package:health_app_v1/service/connect_db.dart';

class Mood extends ChangeNotifier {
  
  bool _initialized = false; 

  Map<String, dynamic> _moods = {};
  List<dynamic> _categories = [];
  String _currentDate = '';

  int _totalScore = -1;

  List<dynamic> get categories => _categories;
  int get totalScore => _totalScore;

  void initializeMood(Map<String, dynamic> newMoods, String currentDate) {
    if (_initialized) return;
    _moods = newMoods;
    _currentDate = currentDate;
    _categories = _moods[currentDate];
    _initialized = true;
  }

  void updateCategories(newCategories){
    _categories = newCategories;
    notifyListeners();
  }

  void setCurrentDate(String newDate){
    _currentDate = newDate;
  }

  void updateScore(int index, int newScore) {
    _categories[index]['score'] = newScore;
    ConnectDb().updateMood({_currentDate:_categories});
    notifyListeners();
  }

  int updateTotalScore(List<dynamic> newCategories){
    double sumScore = 0;
    int i = 0;
    final int newScore;
    for (var category in newCategories){
      if (category['score'] != -1) {
        sumScore += category['score'];
        i++;
      }
    }
    if (i != 0) {
      newScore = (sumScore/i).round();
    } else {
      newScore = -1;
    }

    _totalScore = newScore;
    return newScore;
  }
  
  void signOut() {
    _moods.clear();
    _categories.clear();
    _currentDate = '';
    _totalScore = -1;
    _initialized = false; 
    notifyListeners();
  }
}