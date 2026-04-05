import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_stats.dart';
import '../services/database_service.dart';
import '../services/widget_service.dart';
import '../services/sync_service.dart';

class StatsProvider extends ChangeNotifier {
  UserStats _stats = UserStats();
  List<Map<String, dynamic>> _dailyStats = [];
  bool _isLoading = false;

  UserStats get stats => _stats;
  List<Map<String, dynamic>> get dailyStats => _dailyStats;
  bool get isLoading => _isLoading;

  Future<void> loadStats() async {
    _isLoading = true;
    notifyListeners();
    _stats = await DatabaseService.getUserStats();
    _dailyStats = await DatabaseService.getDailyStats(30);
    _isLoading = false;
    notifyListeners();
    _pushWidgetData();
  }

  Future<bool> addXP(int xp) async {
    final prevLevel = _stats.currentLevel;
    _stats.addXP(xp);
    _stats.updateStreak();
    await DatabaseService.updateUserStats(_stats);
    notifyListeners();
    _pushWidgetData();
    return _stats.currentLevel > prevLevel; // returns true if leveled up
  }

  Future<void> refreshStats() async {
    _stats = await DatabaseService.getUserStats();
    _dailyStats = await DatabaseService.getDailyStats(30);
    notifyListeners();
    _pushWidgetData();
  }

  Future<void> updateStats(UserStats newStats) async {
    _stats = newStats;
    await DatabaseService.updateUserStats(_stats);
    notifyListeners();
    _pushWidgetData();
  }

  Future<void> _pushWidgetData() async {
    final prefs = await SharedPreferences.getInstance();

    // Read cached task data (written by TaskProvider)
    List<Map<String, dynamic>> taskData = [];
    final taskJson = prefs.getString('widget_tasks');
    if (taskJson != null) {
      try {
        final list = jsonDecode(taskJson) as List;
        taskData = list.cast<Map<String, dynamic>>();
      } catch (_) {}
    }

    // Read cached lecture data (written by LectureProvider)
    List<Map<String, dynamic>> lecData = [];
    final lecJson = prefs.getString('widget_lectures');
    if (lecJson != null) {
      try {
        final list = jsonDecode(lecJson) as List;
        lecData = list.cast<Map<String, dynamic>>();
      } catch (_) {}
    }

    await WidgetService.syncAll(
      totalXP: _stats.totalXP,
      currentLevel: _stats.currentLevel,
      streakDays: _stats.streakDays,
      totalTasksCompleted: _stats.totalTasksCompleted,
      totalLecturesCompleted: _stats.totalLecturesCompleted,
      tasks: taskData,
      lectures: lecData,
      username: _stats.username,
    );
    SyncService.pushStats(_stats);
  }

  int get todayTasksCompleted {
    final today = DateTime.now().toIso8601String().split('T')[0];
    final todayStat = _dailyStats.where((s) => s['date'] == today);
    if (todayStat.isEmpty) return 0;
    return todayStat.first['tasksCompleted'] as int;
  }

  int get todayLectureMinutes {
    final today = DateTime.now().toIso8601String().split('T')[0];
    final todayStat = _dailyStats.where((s) => s['date'] == today);
    if (todayStat.isEmpty) return 0;
    return todayStat.first['lectureMinutes'] as int;
  }

  int get todayXP {
    final today = DateTime.now().toIso8601String().split('T')[0];
    final todayStat = _dailyStats.where((s) => s['date'] == today);
    if (todayStat.isEmpty) return 0;
    return todayStat.first['xpEarned'] as int;
  }

  int get weekTasksCompleted {
    int total = 0;
    final now = DateTime.now();
    for (final s in _dailyStats) {
      final date = DateTime.parse(s['date'] as String);
      if (now.difference(date).inDays < 7) {
        total += s['tasksCompleted'] as int;
      }
    }
    return total;
  }
}
