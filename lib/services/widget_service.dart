import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Single source of truth for pushing data to the native Android widget.
/// All widget data updates go through this service to avoid race conditions.
class WidgetService {
  static const _methodChannel = MethodChannel('com.marvel.todo/widget');

  /// Push all widget data at once — stats + pending tasks + pending lectures.
  static Future<void> syncAll({
    required int totalXP,
    required int currentLevel,
    required int streakDays,
    required int totalTasksCompleted,
    required int totalLecturesCompleted,
    required List<Map<String, dynamic>> tasks,
    required List<Map<String, dynamic>> lectures,
    String username = 'Hero',
  }) async {
    final prefs = await SharedPreferences.getInstance();

    // Stats
    await prefs.setInt('widget_totalXP', totalXP);
    await prefs.setInt('widget_currentLevel', currentLevel);
    await prefs.setInt('widget_streakDays', streakDays);
    await prefs.setInt('widget_totalTasksCompleted', totalTasksCompleted);
    await prefs.setInt('widget_totalLecturesCompleted', totalLecturesCompleted);
    await prefs.setString('widget_username', username);

    // Tasks & lectures as JSON arrays
    await prefs.setString('widget_tasks', jsonEncode(tasks));
    await prefs.setString('widget_lectures', jsonEncode(lectures));

    // Build combined pending items list (tasks first, then courses, then standalone lectures)
    final pendingItems = <Map<String, String>>[];

    // Pending tasks
    for (final t in tasks) {
      if (t['completed'] != true) {
        pendingItems.add({'type': 'task', 'title': t['title'] ?? 'Untitled'});
      }
    }

    // Group lectures by courseId — courses show as one item, standalone lectures as individual
    final courseMap = <String, Map<String, dynamic>>{};
    final standaloneLecs = <Map<String, dynamic>>[];
    for (final l in lectures) {
      final cId = l['courseId'];
      if (cId != null && cId.toString().isNotEmpty) {
        courseMap.putIfAbsent(cId.toString(), () => {
          'title': l['courseTitle'] ?? 'Course',
          'total': 0,
          'completed': 0,
        });
        courseMap[cId.toString()]!['total'] = (courseMap[cId.toString()]!['total'] as int) + 1;
        if (l['completed'] == true) {
          courseMap[cId.toString()]!['completed'] = (courseMap[cId.toString()]!['completed'] as int) + 1;
        }
      } else if (l['completed'] != true) {
        standaloneLecs.add(l);
      }
    }

    // Add courses with remaining lectures
    for (final entry in courseMap.entries) {
      final c = entry.value;
      final done = c['completed'] as int;
      final total = c['total'] as int;
      if (done < total) {
        pendingItems.add({'type': 'course', 'title': '${c['title']} ($done/$total)'});
      }
    }

    // Add standalone pending lectures
    for (final l in standaloneLecs) {
      pendingItems.add({'type': 'lecture', 'title': l['title'] ?? 'Untitled'});
    }

    await prefs.setString('widget_pending_items', jsonEncode(pendingItems));

    await triggerNativeUpdate();
  }

  /// Legacy compat — just trigger native update
  static Future<void> updateWidget({
    required int totalXP,
    required int currentLevel,
    required int streakDays,
    required int totalTasksCompleted,
    required int totalLecturesCompleted,
    List<Map<String, dynamic>> pendingTasks = const [],
    List<Map<String, dynamic>> pendingLectures = const [],
    String username = 'Hero',
  }) async {
    await syncAll(
      totalXP: totalXP,
      currentLevel: currentLevel,
      streakDays: streakDays,
      totalTasksCompleted: totalTasksCompleted,
      totalLecturesCompleted: totalLecturesCompleted,
      tasks: pendingTasks,
      lectures: pendingLectures,
      username: username,
    );
  }

  static Future<void> triggerNativeUpdate() async {
    try {
      await _methodChannel.invokeMethod('updateWidget');
    } catch (_) {
      // Widget may not be placed on home screen yet
    }
  }
}
