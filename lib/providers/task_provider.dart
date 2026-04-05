import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/task_model.dart';
import '../services/database_service.dart';
import '../services/widget_service.dart';
import '../services/sync_service.dart';

class TaskProvider extends ChangeNotifier {
  List<TaskModel> _tasks = [];
  bool _isLoading = false;

  List<TaskModel> get tasks => _tasks;
  bool get isLoading => _isLoading;

  List<TaskModel> get completedTasks =>
      _tasks.where((t) => t.completed).toList();
  List<TaskModel> get pendingTasks =>
      _tasks.where((t) => !t.completed).toList();
  List<TaskModel> get todayTasks {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _tasks.where((t) {
      if (t.dueDate != null) {
        final due = DateTime(t.dueDate!.year, t.dueDate!.month, t.dueDate!.day);
        return due.isAtSameMomentAs(today) || due.isBefore(today);
      }
      final created =
          DateTime(t.createdAt.year, t.createdAt.month, t.createdAt.day);
      return created.isAtSameMomentAs(today);
    }).toList();
  }

  int get todayCompleted =>
      todayTasks.where((t) => t.completed).length;
  int get todayRemaining =>
      todayTasks.where((t) => !t.completed).length;

  Future<void> loadTasks() async {
    _isLoading = true;
    notifyListeners();
    _tasks = await DatabaseService.getTasks();
    _isLoading = false;
    notifyListeners();
    _syncWidget();
  }

  Future<void> _syncWidget() async {
    final prefs = await SharedPreferences.getInstance();

    // Prepare task data
    final taskData = _tasks.map((t) => {'title': t.title, 'completed': t.completed}).toList();

    // Read cached lectures (lecture provider writes these separately)
    List<Map<String, dynamic>> lecData = [];
    final lecJson = prefs.getString('widget_lectures');
    if (lecJson != null) {
      try {
        final list = jsonDecode(lecJson) as List;
        lecData = list.cast<Map<String, dynamic>>();
      } catch (_) {}
    }

    // Read stats
    final stats = await DatabaseService.getUserStats();

    await WidgetService.syncAll(
      totalXP: stats.totalXP,
      currentLevel: stats.currentLevel,
      streakDays: stats.streakDays,
      totalTasksCompleted: stats.totalTasksCompleted,
      totalLecturesCompleted: stats.totalLecturesCompleted,
      tasks: taskData,
      lectures: lecData,
      username: stats.username,
    );
  }

  Future<TaskModel> addTask({
    required String title,
    String description = '',
    TaskPriority priority = TaskPriority.medium,
    TaskCategory category = TaskCategory.study,
    DateTime? dueDate,
  }) async {
    final task = TaskModel(
      id: const Uuid().v4(),
      title: title,
      description: description,
      priority: priority,
      category: category,
      createdAt: DateTime.now(),
      dueDate: dueDate,
      xpValue: _xpForPriority(priority),
    );
    await DatabaseService.insertTask(task);
    _tasks.insert(0, task);
    notifyListeners();
    _syncWidget();
    SyncService.pushTask(task);
    return task;
  }

  Future<int> completeTask(String id) async {
    final idx = _tasks.indexWhere((t) => t.id == id);
    if (idx == -1) return 0;
    final task = _tasks[idx];
    task.completed = true;
    task.completedAt = DateTime.now();
    await DatabaseService.updateTask(task);

    // Update user stats
    final stats = await DatabaseService.getUserStats();
    final xp = task.calculatedXP;
    stats.addXP(xp);
    stats.totalTasksCompleted++;
    stats.updateStreak();
    await DatabaseService.updateUserStats(stats);

    // Record daily stats
    await DatabaseService.recordDailyStats(
        tasksCompleted: 1, lectureMinutes: 0, xpEarned: xp);

    notifyListeners();
    _syncWidget();
    SyncService.pushTask(task);
    SyncService.pushStats(stats);
    return xp;
  }

  Future<void> uncompleteTask(String id) async {
    final idx = _tasks.indexWhere((t) => t.id == id);
    if (idx == -1) return;
    _tasks[idx].completed = false;
    _tasks[idx].completedAt = null;
    await DatabaseService.updateTask(_tasks[idx]);
    notifyListeners();
    _syncWidget();
    SyncService.pushTask(_tasks[idx]);
  }

  Future<void> updateTask(TaskModel task) async {
    await DatabaseService.updateTask(task);
    SyncService.pushTask(task);
    final idx = _tasks.indexWhere((t) => t.id == task.id);
    if (idx != -1) _tasks[idx] = task;
    notifyListeners();
  }

  Future<void> deleteTask(String id) async {
    await DatabaseService.deleteTask(id);
    _tasks.removeWhere((t) => t.id == id);
    notifyListeners();
    _syncWidget();
    SyncService.deleteTask(id);
  }

  int _xpForPriority(TaskPriority p) {
    switch (p) {
      case TaskPriority.high:
        return 50;
      case TaskPriority.medium:
        return 25;
      case TaskPriority.low:
        return 10;
    }
  }
}
