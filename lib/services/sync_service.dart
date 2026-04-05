import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';
import 'database_service.dart';
import '../models/task_model.dart';
import '../models/lecture_model.dart';
import '../models/user_stats.dart';

/// Offline-first sync engine.
/// Local SQLite is always the source of truth.
/// Firestore is the cloud backup that syncs in the background.
class SyncService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const _lastSyncKey = 'last_sync_timestamp';

  // ──────────────── Connectivity ────────────────

  static Future<bool> _isOnline() async {
    final result = await Connectivity().checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }

  // ──────────────── Collection refs ────────────────

  static DocumentReference _userDoc() {
    final uid = AuthService.uid!;
    return _db.collection('users').doc(uid);
  }

  static CollectionReference _tasksCol() => _userDoc().collection('tasks');
  static CollectionReference _lecturesCol() => _userDoc().collection('lectures');
  static CollectionReference _notesCol() => _userDoc().collection('lecture_notes');
  static CollectionReference _subTasksCol() => _userDoc().collection('lecture_subtasks');
  static CollectionReference _dailyStatsCol() => _userDoc().collection('daily_stats');

  // ──────────────── Sync to Cloud ────────────────

  /// Push all local data to Firestore (runs on every login).
  static Future<void> syncToCloud() async {
    if (!AuthService.isSignedIn) return;
    if (!await _isOnline()) return;

    try {
      // Upload tasks
      final tasks = await DatabaseService.getTasks();
      for (final t in tasks) {
        await _tasksCol().doc(t.id).set(_taskToFirestore(t), SetOptions(merge: true));
      }

      // Upload lectures
      final lectures = await DatabaseService.getLectures();
      for (final l in lectures) {
        await _lecturesCol().doc(l.id).set(_lectureToFirestore(l), SetOptions(merge: true));
        // Upload notes
        for (final n in l.notes) {
          await _notesCol().doc(n.id).set({
            'lectureId': l.id,
            'timestampSeconds': n.timestampSeconds,
            'content': n.content,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
        // Upload subtasks
        for (final st in l.subTasks) {
          await _subTasksCol().doc(st.id).set({
            'lectureId': l.id,
            'title': st.title,
            'completed': st.completed,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
      }

      // Upload user stats
      final stats = await DatabaseService.getUserStats();
      await _userDoc().set({
        'stats': _statsToFirestore(stats),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Upload daily stats
      final dailyStats = await DatabaseService.getDailyStats(365);
      for (final ds in dailyStats) {
        final date = ds['date'] as String;
        await _dailyStatsCol().doc(date).set({
          'tasksCompleted': ds['tasksCompleted'],
          'lectureMinutes': ds['lectureMinutes'],
          'xpEarned': ds['xpEarned'],
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());
    } catch (_) {
      // Silently fail — will retry next time
    }
  }

  // ──────────────── Pull Remote Changes ────────────────

  /// Pull changes from Firestore and merge with local data.
  static Future<void> pullRemoteChanges() async {
    if (!AuthService.isSignedIn) return;
    if (!await _isOnline()) return;

    try {
      // Pull ALL remote data (not just recent changes)
      // This ensures we get everything from cloud on re-login

      // Pull tasks
      final taskSnap = await _tasksCol().get();
      for (final doc in taskSnap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final task = _taskFromFirestore(doc.id, data);
        await DatabaseService.insertTask(task); // upsert
      }

      // Pull lectures
      final lecSnap = await _lecturesCol().get();
      for (final doc in lecSnap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final lecture = _lectureFromFirestore(doc.id, data);
        await DatabaseService.insertLecture(lecture); // upsert
      }

      // Pull notes
      final noteSnap = await _notesCol().get();
      for (final doc in noteSnap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final note = LectureNote(
          id: doc.id,
          timestampSeconds: data['timestampSeconds'] as int? ?? 0,
          content: data['content'] as String? ?? '',
        );
        final lectureId = data['lectureId'] as String? ?? '';
        if (lectureId.isNotEmpty) {
          await DatabaseService.insertNote(lectureId, note);
        }
      }

      // Pull subtasks
      final stSnap = await _subTasksCol().get();
      for (final doc in stSnap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final st = LectureSubTask(
          id: doc.id,
          title: data['title'] as String? ?? '',
          completed: data['completed'] as bool? ?? false,
        );
        final lectureId = data['lectureId'] as String? ?? '';
        if (lectureId.isNotEmpty) {
          await DatabaseService.insertSubTask(lectureId, st);
        }
      }

      // Pull stats
      final userDoc = await _userDoc().get();
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>?;
        if (data != null && data.containsKey('stats')) {
          final remoteStats = _statsFromFirestore(data['stats'] as Map<String, dynamic>);
          final localStats = await DatabaseService.getUserStats();
          // Merge: take the higher values for cumulative stats
          localStats.totalXP = _max(localStats.totalXP, remoteStats.totalXP);
          localStats.currentLevel = _max(localStats.currentLevel, remoteStats.currentLevel);
          localStats.streakDays = _max(localStats.streakDays, remoteStats.streakDays);
          localStats.totalTasksCompleted = _max(localStats.totalTasksCompleted, remoteStats.totalTasksCompleted);
          localStats.totalLecturesCompleted = _max(localStats.totalLecturesCompleted, remoteStats.totalLecturesCompleted);
          localStats.totalStudyMinutes = _max(localStats.totalStudyMinutes, remoteStats.totalStudyMinutes);
          if (remoteStats.username != 'Super Hero' && localStats.username == 'Super Hero') {
            localStats.username = remoteStats.username;
          }
          await DatabaseService.updateUserStats(localStats);
        }
      }

      // Pull daily stats
      final dsSnap = await _dailyStatsCol().get();
      for (final doc in dsSnap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        // Use raw insert/replace since recordDailyStats is additive
        await DatabaseService.upsertDailyStats(
          date: doc.id,
          tasksCompleted: data['tasksCompleted'] as int? ?? 0,
          lectureMinutes: data['lectureMinutes'] as int? ?? 0,
          xpEarned: data['xpEarned'] as int? ?? 0,
        );
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());
    } catch (_) {
      // Silently fail
    }
  }

  // ──────────────── Push Helpers ────────────────

  /// Push a task change to Firestore.
  static Future<void> pushTask(TaskModel task) async {
    if (!AuthService.isSignedIn) return;
    try {
      await _tasksCol().doc(task.id).set(_taskToFirestore(task), SetOptions(merge: true));
    } catch (_) {}
  }

  /// Push a lecture change to Firestore.
  static Future<void> pushLecture(LectureModel lecture) async {
    if (!AuthService.isSignedIn) return;
    try {
      await _lecturesCol().doc(lecture.id).set(_lectureToFirestore(lecture), SetOptions(merge: true));
    } catch (_) {}
  }

  /// Push user stats to Firestore.
  static Future<void> pushStats(UserStats stats) async {
    if (!AuthService.isSignedIn) return;
    try {
      await _userDoc().set({
        'stats': _statsToFirestore(stats),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  /// Push a lecture note to Firestore.
  static Future<void> pushNote(String lectureId, LectureNote note) async {
    if (!AuthService.isSignedIn) return;
    try {
      await _notesCol().doc(note.id).set({
        'lectureId': lectureId,
        'timestampSeconds': note.timestampSeconds,
        'content': note.content,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  /// Push a lecture subtask to Firestore.
  static Future<void> pushSubTask(String lectureId, LectureSubTask st) async {
    if (!AuthService.isSignedIn) return;
    try {
      await _subTasksCol().doc(st.id).set({
        'lectureId': lectureId,
        'title': st.title,
        'completed': st.completed,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  /// Push daily stats to Firestore.
  static Future<void> pushDailyStats({
    required String date,
    required int tasksCompleted,
    required int lectureMinutes,
    required int xpEarned,
  }) async {
    if (!AuthService.isSignedIn) return;
    try {
      await _dailyStatsCol().doc(date).set({
        'tasksCompleted': tasksCompleted,
        'lectureMinutes': lectureMinutes,
        'xpEarned': xpEarned,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  // ──────────────── Delete Helpers ────────────────

  static Future<void> deleteTask(String id) async {
    if (!AuthService.isSignedIn) return;
    try { await _tasksCol().doc(id).delete(); } catch (_) {}
  }

  static Future<void> deleteLecture(String id) async {
    if (!AuthService.isSignedIn) return;
    try { await _lecturesCol().doc(id).delete(); } catch (_) {}
  }

  static Future<void> deleteNote(String id) async {
    if (!AuthService.isSignedIn) return;
    try { await _notesCol().doc(id).delete(); } catch (_) {}
  }

  static Future<void> deleteSubTask(String id) async {
    if (!AuthService.isSignedIn) return;
    try { await _subTasksCol().doc(id).delete(); } catch (_) {}
  }

  // ──────────────── Firestore Helpers ─────────────

  static int _max(int a, int b) => a > b ? a : b;

  static Map<String, dynamic> _taskToFirestore(TaskModel t) => {
    'title': t.title,
    'description': t.description,
    'priority': t.priority.index,
    'category': t.category.index,
    'completed': t.completed,
    'createdAt': t.createdAt.toIso8601String(),
    'dueDate': t.dueDate?.toIso8601String(),
    'completedAt': t.completedAt?.toIso8601String(),
    'xpValue': t.xpValue,
    'updatedAt': FieldValue.serverTimestamp(),
  };

  static TaskModel _taskFromFirestore(String id, Map<String, dynamic> data) => TaskModel(
    id: id,
    title: data['title'] as String? ?? '',
    description: data['description'] as String? ?? '',
    priority: TaskPriority.values[(data['priority'] as int?) ?? 1],
    category: TaskCategory.values[(data['category'] as int?) ?? 0],
    completed: data['completed'] as bool? ?? false,
    createdAt: DateTime.tryParse(data['createdAt'] as String? ?? '') ?? DateTime.now(),
    dueDate: data['dueDate'] != null ? DateTime.tryParse(data['dueDate'] as String) : null,
    completedAt: data['completedAt'] != null ? DateTime.tryParse(data['completedAt'] as String) : null,
    xpValue: data['xpValue'] as int? ?? 20,
  );

  static Map<String, dynamic> _lectureToFirestore(LectureModel l) => {
    'title': l.title,
    'subtitle': l.subtitle,
    'url': l.url,
    'videoId': l.videoId,
    'totalDurationSeconds': l.totalDurationSeconds,
    'watchedSeconds': l.watchedSeconds,
    'lastPositionSeconds': l.lastPositionSeconds,
    'completed': l.completed,
    'createdAt': l.createdAt.toIso8601String(),
    'courseId': l.courseId,
    'courseTitle': l.courseTitle,
    'updatedAt': FieldValue.serverTimestamp(),
  };

  static LectureModel _lectureFromFirestore(String id, Map<String, dynamic> data) => LectureModel(
    id: id,
    title: data['title'] as String? ?? '',
    subtitle: data['subtitle'] as String? ?? '',
    url: data['url'] as String? ?? '',
    videoId: data['videoId'] as String? ?? '',
    totalDurationSeconds: data['totalDurationSeconds'] as int? ?? 0,
    watchedSeconds: data['watchedSeconds'] as int? ?? 0,
    lastPositionSeconds: data['lastPositionSeconds'] as int? ?? 0,
    completed: data['completed'] as bool? ?? false,
    createdAt: DateTime.tryParse(data['createdAt'] as String? ?? '') ?? DateTime.now(),
    courseId: data['courseId'] as String?,
    courseTitle: data['courseTitle'] as String?,
  );

  static Map<String, dynamic> _statsToFirestore(UserStats s) => {
    'totalXP': s.totalXP,
    'currentLevel': s.currentLevel,
    'streakDays': s.streakDays,
    'lastActiveDate': s.lastActiveDate?.toIso8601String(),
    'totalTasksCompleted': s.totalTasksCompleted,
    'totalLecturesCompleted': s.totalLecturesCompleted,
    'totalStudyMinutes': s.totalStudyMinutes,
    'unlockedThemes': s.unlockedThemes.join(','),
    'currentTheme': s.currentTheme,
    'username': s.username,
  };

  static UserStats _statsFromFirestore(Map<String, dynamic> m) => UserStats(
    totalXP: m['totalXP'] as int? ?? 0,
    currentLevel: m['currentLevel'] as int? ?? 1,
    streakDays: m['streakDays'] as int? ?? 0,
    lastActiveDate: m['lastActiveDate'] != null ? DateTime.tryParse(m['lastActiveDate'] as String) : null,
    totalTasksCompleted: m['totalTasksCompleted'] as int? ?? 0,
    totalLecturesCompleted: m['totalLecturesCompleted'] as int? ?? 0,
    totalStudyMinutes: m['totalStudyMinutes'] as int? ?? 0,
    unlockedThemes: m['unlockedThemes'] != null ? (m['unlockedThemes'] as String).split(',') : ['iron_man'],
    currentTheme: m['currentTheme'] as String? ?? 'iron_man',
    username: m['username'] as String? ?? 'Super Hero',
  );
}
