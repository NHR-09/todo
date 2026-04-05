import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/task_model.dart';
import '../models/lecture_model.dart';
import '../models/user_stats.dart';

class DatabaseService {
  static Database? _database;

  static Future<Database> get database async {
    _database ??= await _initDB();
    return _database!;
  }

  static Future<Database> _initDB() async {
    final path = join(await getDatabasesPath(), 'marvel_todo.db');
    return openDatabase(
      path,
      version: 6,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE tasks (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            description TEXT DEFAULT '',
            priority INTEGER DEFAULT 1,
            category INTEGER DEFAULT 0,
            completed INTEGER DEFAULT 0,
            createdAt TEXT NOT NULL,
            dueDate TEXT,
            completedAt TEXT,
            xpValue INTEGER DEFAULT 20
          )
        ''');

        await db.execute('''
          CREATE TABLE lectures (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            subtitle TEXT DEFAULT '',
            url TEXT NOT NULL,
            videoId TEXT NOT NULL,
            totalDurationSeconds INTEGER DEFAULT 0,
            watchedSeconds INTEGER DEFAULT 0,
            lastPositionSeconds INTEGER DEFAULT 0,
            completed INTEGER DEFAULT 0,
            createdAt TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE lecture_notes (
            id TEXT PRIMARY KEY,
            lectureId TEXT NOT NULL,
            timestampSeconds INTEGER NOT NULL,
            content TEXT NOT NULL,
            FOREIGN KEY (lectureId) REFERENCES lectures(id) ON DELETE CASCADE
          )
        ''');

        await db.execute('''
          CREATE TABLE user_stats (
            id INTEGER PRIMARY KEY DEFAULT 1,
            totalXP INTEGER DEFAULT 0,
            currentLevel INTEGER DEFAULT 1,
            streakDays INTEGER DEFAULT 0,
            lastActiveDate TEXT,
            totalTasksCompleted INTEGER DEFAULT 0,
            totalLecturesCompleted INTEGER DEFAULT 0,
            totalStudyMinutes INTEGER DEFAULT 0,
            unlockedThemes TEXT DEFAULT 'iron_man',
            currentTheme TEXT DEFAULT 'iron_man',
            username TEXT DEFAULT 'Super Hero'
          )
        ''');

        await db.execute('''
          CREATE TABLE daily_stats (
            date TEXT PRIMARY KEY,
            tasksCompleted INTEGER DEFAULT 0,
            lectureMinutes INTEGER DEFAULT 0,
            xpEarned INTEGER DEFAULT 0
          )
        ''');

        // Insert default user stats
        await db.insert('user_stats', UserStats().toMap()..['id'] = 1);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE lectures ADD COLUMN subtitle TEXT DEFAULT ""');
        }
        if (oldVersion < 3) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS lecture_subtasks (
              id TEXT PRIMARY KEY,
              lectureId TEXT NOT NULL,
              title TEXT NOT NULL,
              completed INTEGER DEFAULT 0,
              FOREIGN KEY (lectureId) REFERENCES lectures(id) ON DELETE CASCADE
            )
          ''');
        }
        if (oldVersion < 4) {
          await db.execute('ALTER TABLE lectures ADD COLUMN courseId TEXT');
          await db.execute('ALTER TABLE lectures ADD COLUMN courseTitle TEXT');
        }
        if (oldVersion < 5) {
          await db.execute('ALTER TABLE user_stats ADD COLUMN username TEXT DEFAULT "Super Hero"');
        }
        if (oldVersion < 6) {
          // Ensure courseId and courseTitle columns exist
          try {
            await db.execute('ALTER TABLE lectures ADD COLUMN courseId TEXT');
          } catch (_) {
            // Column might already exist
          }
          try {
            await db.execute('ALTER TABLE lectures ADD COLUMN courseTitle TEXT');
          } catch (_) {
            // Column might already exist
          }
        }
      },
    );
  }

  // -- Tasks --
  static Future<List<TaskModel>> getTasks() async {
    final db = await database;
    final maps = await db.query('tasks', orderBy: 'createdAt DESC');
    return maps.map((m) => TaskModel.fromMap(m)).toList();
  }

  static Future<void> insertTask(TaskModel task) async {
    final db = await database;
    await db.insert('tasks', task.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<void> updateTask(TaskModel task) async {
    final db = await database;
    await db.update('tasks', task.toMap(), where: 'id = ?', whereArgs: [task.id]);
  }

  static Future<void> deleteTask(String id) async {
    final db = await database;
    await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }

  // -- Lectures --
  static Future<List<LectureModel>> getLectures() async {
    final db = await database;
    final maps = await db.query('lectures', orderBy: 'createdAt DESC');
    final lectures = <LectureModel>[];
    for (final m in maps) {
      final lecture = LectureModel.fromMap(m);
      lecture.notes = await _getNotesForLecture(lecture.id);
      lecture.subTasks = await _getSubTasksForLecture(lecture.id);
      lecture.chunks = lecture.generateChunks();
      lectures.add(lecture);
    }
    return lectures;
  }

  static Future<List<LectureNote>> _getNotesForLecture(String lectureId) async {
    final db = await database;
    final maps = await db.query('lecture_notes',
        where: 'lectureId = ?',
        whereArgs: [lectureId],
        orderBy: 'timestampSeconds ASC');
    return maps.map((m) => LectureNote.fromMap(m)).toList();
  }

  static Future<void> insertLecture(LectureModel lecture) async {
    final db = await database;
    await db.insert(
      'lectures',
      {
        'id': lecture.id,
        'title': lecture.title,
        'subtitle': lecture.subtitle,
        'url': lecture.url,
        'videoId': lecture.videoId,
        'totalDurationSeconds': lecture.totalDurationSeconds,
        'watchedSeconds': lecture.watchedSeconds,
        'lastPositionSeconds': lecture.lastPositionSeconds,
        'completed': lecture.completed ? 1 : 0,
        'createdAt': lecture.createdAt.toIso8601String(),
        'courseId': lecture.courseId,
        'courseTitle': lecture.courseTitle,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<void> updateLecture(LectureModel lecture) async {
    final db = await database;
    await db.update(
      'lectures',
      {
        'title': lecture.title,
        'subtitle': lecture.subtitle,
        'totalDurationSeconds': lecture.totalDurationSeconds,
        'watchedSeconds': lecture.watchedSeconds,
        'lastPositionSeconds': lecture.lastPositionSeconds,
        'completed': lecture.completed ? 1 : 0,
      },
      where: 'id = ?',
      whereArgs: [lecture.id],
    );
  }

  static Future<void> deleteLecture(String id) async {
    final db = await database;
    await db.delete('lecture_notes', where: 'lectureId = ?', whereArgs: [id]);
    await db.delete('lectures', where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> insertNote(String lectureId, LectureNote note) async {
    final db = await database;
    await db.insert(
      'lecture_notes',
      note.toMap()..['lectureId'] = lectureId,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<void> deleteNote(String noteId) async {
    final db = await database;
    await db.delete('lecture_notes', where: 'id = ?', whereArgs: [noteId]);
  }

  // -- Lecture Sub-Tasks --
  static Future<List<LectureSubTask>> _getSubTasksForLecture(String lectureId) async {
    final db = await database;
    final maps = await db.query('lecture_subtasks',
        where: 'lectureId = ?', whereArgs: [lectureId]);
    return maps.map((m) => LectureSubTask.fromMap(m)).toList();
  }

  static Future<void> insertSubTask(String lectureId, LectureSubTask st) async {
    final db = await database;
    await db.insert('lecture_subtasks', st.toMap()..['lectureId'] = lectureId,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<void> updateSubTask(LectureSubTask st) async {
    final db = await database;
    await db.update('lecture_subtasks', {'completed': st.completed ? 1 : 0},
        where: 'id = ?', whereArgs: [st.id]);
  }

  static Future<void> deleteSubTask(String id) async {
    final db = await database;
    await db.delete('lecture_subtasks', where: 'id = ?', whereArgs: [id]);
  }

  // -- User Stats --
  static Future<UserStats> getUserStats() async {
    final db = await database;
    final maps = await db.query('user_stats', where: 'id = ?', whereArgs: [1]);
    if (maps.isEmpty) return UserStats();
    return UserStats.fromMap(maps.first);
  }

  static Future<void> updateUserStats(UserStats stats) async {
    final db = await database;
    await db.update('user_stats', stats.toMap()..['id'] = 1,
        where: 'id = ?', whereArgs: [1]);
  }

  // -- Daily Stats --
  static Future<void> recordDailyStats({
    required int tasksCompleted,
    required int lectureMinutes,
    required int xpEarned,
  }) async {
    final db = await database;
    final today = DateTime.now().toIso8601String().split('T')[0];
    final existing =
        await db.query('daily_stats', where: 'date = ?', whereArgs: [today]);
    if (existing.isEmpty) {
      await db.insert('daily_stats', {
        'date': today,
        'tasksCompleted': tasksCompleted,
        'lectureMinutes': lectureMinutes,
        'xpEarned': xpEarned,
      });
    } else {
      await db.update(
        'daily_stats',
        {
          'tasksCompleted':
              (existing.first['tasksCompleted'] as int) + tasksCompleted,
          'lectureMinutes':
              (existing.first['lectureMinutes'] as int) + lectureMinutes,
          'xpEarned': (existing.first['xpEarned'] as int) + xpEarned,
        },
        where: 'date = ?',
        whereArgs: [today],
      );
    }
  }

  static Future<List<Map<String, dynamic>>> getDailyStats(int days) async {
    final db = await database;
    return db.query(
      'daily_stats',
      orderBy: 'date DESC',
      limit: days,
    );
  }

  /// Upsert daily stats from remote sync (replaces rather than adds).
  static Future<void> upsertDailyStats({
    required String date,
    required int tasksCompleted,
    required int lectureMinutes,
    required int xpEarned,
  }) async {
    final db = await database;
    final existing =
        await db.query('daily_stats', where: 'date = ?', whereArgs: [date]);
    if (existing.isEmpty) {
      await db.insert('daily_stats', {
        'date': date,
        'tasksCompleted': tasksCompleted,
        'lectureMinutes': lectureMinutes,
        'xpEarned': xpEarned,
      });
    } else {
      // Take the higher values (merge remote + local)
      final local = existing.first;
      await db.update(
        'daily_stats',
        {
          'tasksCompleted': _max(local['tasksCompleted'] as int, tasksCompleted),
          'lectureMinutes': _max(local['lectureMinutes'] as int, lectureMinutes),
          'xpEarned': _max(local['xpEarned'] as int, xpEarned),
        },
        where: 'date = ?',
        whereArgs: [date],
      );
    }
  }

  static int _max(int a, int b) => a > b ? a : b;
}
