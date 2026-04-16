import 'package:flutter/material.dart';
import '../services/mongodb_service.dart';
import '../models/schedule.dart';

class ScheduleProvider with ChangeNotifier {
  List<Schedule> _schedules = [];
  bool _isLoading = false;

  List<Schedule> get schedules => _schedules;
  bool get isLoading => _isLoading;

  Future<void> fetchSchedules() async {
    _isLoading = true;
    notifyListeners();
    
    final maps = await MongoDBService.getSchedules();
    _schedules = maps.map((m) => Schedule.fromMap(m)).toList();
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addSchedule(Schedule schedule) async {
    await MongoDBService.addSchedule(schedule.toMap());
    _schedules.add(schedule);
    notifyListeners();
  }

  // Commute Logic: Returns recommendation based on current time
  String getCommuteRecommendation() {
    final now = DateTime.now();
    final threshold = DateTime(now.year, now.month, now.day, 7, 10);
    final officeTime = DateTime(now.year, now.month, now.day, 8, 15);

    if (now.isBefore(threshold)) {
      return "You're good to go! Local bus or regular transport is perfect for today.";
    } else if (now.isBefore(officeTime)) {
      return "You're running a bit late! Recommendation: Use Uber or Pathao to reach office by 8:15 AM.";
    } else {
      return "Office has already started! Hurry up!";
    }
  }
}
