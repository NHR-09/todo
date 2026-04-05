import '../models/task_model.dart';
import '../models/lecture_model.dart';
import '../models/user_stats.dart';

class SmartSuggestion {
  final String icon;
  final String title;
  final String subtitle;
  final String? actionType; // 'task', 'lecture', 'streak'
  final String? actionId;

  SmartSuggestion({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionType,
    this.actionId,
  });
}

class SmartEngine {
  static List<SmartSuggestion> generateSuggestions({
    required List<TaskModel> tasks,
    required List<LectureModel> lectures,
    required UserStats stats,
  }) {
    final suggestions = <SmartSuggestion>[];

    // 1. Continue lecture suggestion
    final inProgress = lectures
        .where((l) => !l.completed && l.watchedSeconds > 0)
        .toList();
    if (inProgress.isNotEmpty) {
      inProgress.sort((a, b) => b.watchedSeconds.compareTo(a.watchedSeconds));
      final lec = inProgress.first;
      suggestions.add(SmartSuggestion(
        icon: 'play',
        title: 'Continue "${lec.title}"',
        subtitle: 'You left at ${lec.progressText} — ${lec.remainingText}',
        actionType: 'lecture',
        actionId: lec.id,
      ));
    }

    // 2. High priority overdue tasks
    final now = DateTime.now();
    final overdue = tasks.where((t) {
      return !t.completed &&
          t.dueDate != null &&
          t.dueDate!.isBefore(now) &&
          t.priority == TaskPriority.high;
    }).toList();
    if (overdue.isNotEmpty) {
      suggestions.add(SmartSuggestion(
        icon: 'alert',
        title: '${overdue.length} overdue high-priority task${overdue.length > 1 ? "s" : ""}',
        subtitle: 'Complete "${overdue.first.title}" first!',
        actionType: 'task',
        actionId: overdue.first.id,
      ));
    }

    // 3. Streak motivation
    if (stats.streakDays > 0) {
      if (stats.streakDays == 4) {
        suggestions.add(SmartSuggestion(
          icon: 'fire',
          title: 'Almost there! 5-day streak tomorrow!',
          subtitle: 'Complete at least 1 task to keep your streak alive.',
          actionType: 'streak',
        ));
      } else if (stats.streakDays >= 7) {
        suggestions.add(SmartSuggestion(
          icon: 'trophy',
          title: '${stats.streakDays}-day streak — ${stats.heroTitle} mode!',
          subtitle: 'You\'re unstoppable! Keep the momentum going.',
          actionType: 'streak',
        ));
      }
    }

    // 4. Pending tasks count
    final pending = tasks.where((t) => !t.completed).length;
    if (pending > 0) {
      suggestions.add(SmartSuggestion(
        icon: 'tasks',
        title: '$pending task${pending > 1 ? "s" : ""} remaining today',
        subtitle: 'Focus on high-priority items first.',
        actionType: 'task',
      ));
    }

    // 5. Unwatched lectures
    final notStarted =
        lectures.where((l) => !l.completed && l.watchedSeconds == 0).toList();
    if (notStarted.isNotEmpty) {
      suggestions.add(SmartSuggestion(
        icon: 'lecture',
        title: '${notStarted.length} lecture${notStarted.length > 1 ? "s" : ""} waiting',
        subtitle: 'Start "${notStarted.first.title}" — fresh content ready!',
        actionType: 'lecture',
        actionId: notStarted.first.id,
      ));
    }

    // 6. Level up motivation
    final xpToNext = stats.xpForNextLevel - stats.xpInCurrentLevel;
    if (xpToNext <= 50) {
      suggestions.add(SmartSuggestion(
        icon: 'star',
        title: 'Only $xpToNext XP to Level ${stats.currentLevel + 1}!',
        subtitle: 'Complete a couple tasks to level up!',
      ));
    }

    return suggestions;
  }

  /// Auto-sort tasks by smart priority
  static List<TaskModel> smartSort(List<TaskModel> tasks) {
    final sorted = List<TaskModel>.from(tasks);
    sorted.sort((a, b) {
      // Completed last
      if (a.completed != b.completed) return a.completed ? 1 : -1;
      // Overdue first
      final now = DateTime.now();
      final aOverdue = a.dueDate != null && a.dueDate!.isBefore(now);
      final bOverdue = b.dueDate != null && b.dueDate!.isBefore(now);
      if (aOverdue != bOverdue) return aOverdue ? -1 : 1;
      // High priority first
      if (a.priority != b.priority) return a.priority.index.compareTo(b.priority.index);
      // Earliest due date first
      if (a.dueDate != null && b.dueDate != null) {
        return a.dueDate!.compareTo(b.dueDate!);
      }
      if (a.dueDate != null) return -1;
      if (b.dueDate != null) return 1;
      // Newest first
      return b.createdAt.compareTo(a.createdAt);
    });
    return sorted;
  }
}
