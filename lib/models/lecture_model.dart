class LectureSubTask {
  final String id;
  String title;
  bool completed;

  LectureSubTask({
    required this.id,
    required this.title,
    this.completed = false,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'completed': completed ? 1 : 0,
  };

  factory LectureSubTask.fromMap(Map<String, dynamic> map) => LectureSubTask(
    id: map['id'] as String,
    title: map['title'] as String,
    completed: (map['completed'] as int) == 1,
  );
}

class LectureNote {
  final String id;
  final int timestampSeconds;
  String content;

  LectureNote({
    required this.id,
    required this.timestampSeconds,
    required this.content,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'timestampSeconds': timestampSeconds,
        'content': content,
      };

  factory LectureNote.fromMap(Map<String, dynamic> map) => LectureNote(
        id: map['id'] as String,
        timestampSeconds: map['timestampSeconds'] as int,
        content: map['content'] as String,
      );
}

class LectureChunk {
  final int index;
  final int startSeconds;
  final int endSeconds;
  bool completed;

  LectureChunk({
    required this.index,
    required this.startSeconds,
    required this.endSeconds,
    this.completed = false,
  });

  Map<String, dynamic> toMap() => {
        'index': index,
        'startSeconds': startSeconds,
        'endSeconds': endSeconds,
        'completed': completed ? 1 : 0,
      };

  factory LectureChunk.fromMap(Map<String, dynamic> map) => LectureChunk(
        index: map['index'] as int,
        startSeconds: map['startSeconds'] as int,
        endSeconds: map['endSeconds'] as int,
        completed: (map['completed'] as int) == 1,
      );
}

class LectureModel {
  final String id;
  String title;
  String subtitle;
  String url;
  String videoId;
  int totalDurationSeconds;
  int watchedSeconds;
  int lastPositionSeconds;
  bool completed;
  DateTime createdAt;
  String? courseId;
  String? courseTitle;
  List<LectureNote> notes;
  List<LectureChunk> chunks;
  List<LectureSubTask> subTasks;

  LectureModel({
    required this.id,
    required this.title,
    this.subtitle = '',
    required this.url,
    required this.videoId,
    this.totalDurationSeconds = 0,
    this.watchedSeconds = 0,
    this.lastPositionSeconds = 0,
    this.completed = false,
    required this.createdAt,
    this.courseId,
    this.courseTitle,
    this.notes = const [],
    this.chunks = const [],
    this.subTasks = const [],
  });

  double get progressPercent {
    if (totalDurationSeconds == 0) return 0;
    return (watchedSeconds / totalDurationSeconds).clamp(0.0, 1.0);
  }

  String get progressText {
    final percent = (progressPercent * 100).round();
    return '$percent%';
  }

  String get remainingText {
    final remaining = totalDurationSeconds - watchedSeconds;
    if (remaining <= 0) return 'Completed';
    final mins = remaining ~/ 60;
    if (mins < 60) return '${mins}m remaining';
    return '${mins ~/ 60}h ${mins % 60}m remaining';
  }

  int get xpValue => completed ? 100 : (progressPercent * 100).round();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'url': url,
      'videoId': videoId,
      'totalDurationSeconds': totalDurationSeconds,
      'watchedSeconds': watchedSeconds,
      'lastPositionSeconds': lastPositionSeconds,
      'completed': completed ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
      'courseId': courseId,
      'courseTitle': courseTitle,
      'notes': notes.map((n) => n.toMap()).toList().toString(),
      'chunks': chunks.map((c) => c.toMap()).toList().toString(),
    };
  }

  factory LectureModel.fromMap(Map<String, dynamic> map) {
    return LectureModel(
      id: map['id'] as String,
      title: map['title'] as String,
      subtitle: (map['subtitle'] as String?) ?? '',
      url: map['url'] as String,
      videoId: map['videoId'] as String,
      totalDurationSeconds: (map['totalDurationSeconds'] as int?) ?? 0,
      watchedSeconds: (map['watchedSeconds'] as int?) ?? 0,
      lastPositionSeconds: (map['lastPositionSeconds'] as int?) ?? 0,
      completed: (map['completed'] as int) == 1,
      createdAt: DateTime.parse(map['createdAt'] as String),
      courseId: map['courseId'] as String?,
      courseTitle: map['courseTitle'] as String?,
    );
  }

  /// Split into 25-minute chunks
  List<LectureChunk> generateChunks() {
    if (totalDurationSeconds <= 0) return [];
    const chunkDuration = 25 * 60; // 25 minutes
    final chunkCount = (totalDurationSeconds / chunkDuration).ceil();
    return List.generate(chunkCount, (i) {
      final start = i * chunkDuration;
      final end = ((i + 1) * chunkDuration).clamp(0, totalDurationSeconds);
      return LectureChunk(
        index: i,
        startSeconds: start,
        endSeconds: end,
        completed: watchedSeconds >= end,
      );
    });
  }
}
