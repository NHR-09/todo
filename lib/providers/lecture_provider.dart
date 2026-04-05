import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import '../models/lecture_model.dart';
import '../services/database_service.dart';
import '../services/widget_service.dart';
import '../services/sync_service.dart';

class VideoInfo {
  final String title;
  final String thumbnailUrl;
  final int durationSeconds;
  VideoInfo({
    required this.title,
    required this.thumbnailUrl,
    required this.durationSeconds,
  });
}

class LectureProvider extends ChangeNotifier {
  List<LectureModel> _lectures = [];
  bool _isLoading = false;
  String? _lastPlaylistImportError;

  List<LectureModel> get lectures => _lectures;
  bool get isLoading => _isLoading;
  String? get lastPlaylistImportError => _lastPlaylistImportError;

  List<LectureModel> get completedLectures =>
      _lectures.where((l) => l.completed).toList();
  List<LectureModel> get inProgressLectures =>
      _lectures.where((l) => !l.completed && l.watchedSeconds > 0).toList();
  List<LectureModel> get notStartedLectures =>
      _lectures.where((l) => !l.completed && l.watchedSeconds == 0).toList();

  double get overallProgress {
    if (_lectures.isEmpty) return 0;
    final totalWatched = _lectures.fold<int>(
      0,
      (sum, l) => sum + l.watchedSeconds,
    );
    final totalDuration = _lectures.fold<int>(
      0,
      (sum, l) => sum + l.totalDurationSeconds,
    );
    if (totalDuration == 0) return 0;
    return (totalWatched / totalDuration).clamp(0.0, 1.0);
  }

  Future<void> loadLectures() async {
    _isLoading = true;
    notifyListeners();
    _lectures = await DatabaseService.getLectures();
    _isLoading = false;
    notifyListeners();

    // Retroactive sync: fix totalLecturesCompleted if it's behind actual count
    final actualCompleted = _lectures.where((l) => l.completed).length;
    final stats = await DatabaseService.getUserStats();
    if (actualCompleted > stats.totalLecturesCompleted) {
      stats.totalLecturesCompleted = actualCompleted;
      await DatabaseService.updateUserStats(stats);
    }

    _syncWidget();
  }

  Future<void> _syncWidget() async {
    final prefs = await SharedPreferences.getInstance();

    // Prepare lecture data
    final lecData = _lectures
        .map(
          (l) => {
            'title': l.title,
            'completed': l.completed,
            'courseId': l.courseId,
            'courseTitle': l.courseTitle,
          },
        )
        .toList();
    // Also cache it raw for TaskProvider to read
    await prefs.setString('widget_lectures', jsonEncode(lecData));

    // Read cached tasks
    List<Map<String, dynamic>> taskData = [];
    final taskJson = prefs.getString('widget_tasks');
    if (taskJson != null) {
      try {
        final list = jsonDecode(taskJson) as List;
        taskData = list.cast<Map<String, dynamic>>();
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

  Future<LectureModel> addLecture({
    required String title,
    required String url,
    required String videoId,
    int totalDurationSeconds = 0,
    String? courseId,
    String? courseTitle,
  }) async {
    final lecture = LectureModel(
      id: const Uuid().v4(),
      title: title,
      url: url,
      videoId: videoId,
      totalDurationSeconds: totalDurationSeconds,
      createdAt: DateTime.now(),
      courseId: courseId,
      courseTitle: courseTitle,
    );
    await DatabaseService.insertLecture(lecture);
    _lectures.insert(0, lecture);
    notifyListeners();
    _syncWidget();
    SyncService.pushLecture(lecture);
    return lecture;
  }

  /// Import all videos from a YouTube playlist as a course
  Future<int> addPlaylist(String url) async {
    final playlistId = extractPlaylistId(url);
    if (playlistId == null) {
      _setPlaylistImportError(
        'Invalid playlist URL. Add a link containing list=...',
      );
      return 0;
    }

    _isLoading = true;
    _lastPlaylistImportError = null;
    notifyListeners();

    try {
      final res = await http.get(
        Uri.parse('https://www.youtube.com/playlist?list=$playlistId'),
        headers: {'User-Agent': 'Mozilla/5.0'},
      ).timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) {
        _setPlaylistImportError(
          'Network error: YouTube returned ${res.statusCode}. Please try again.',
        );
        return 0;
      }

      final body = res.body;
      final availabilityError = _detectPlaylistAvailabilityError(body);
      if (availabilityError != null) {
        _setPlaylistImportError(availabilityError);
        return 0;
      }
      final playlistTitle = _extractPlaylistTitle(body);

      List<Map<String, dynamic>> renderers = [];
      final apiKey = _extractInnertubeApiKey(body);
      final clientVersion = _extractInnertubeClientVersion(body);
      if (apiKey != null && clientVersion != null) {
        renderers = await _fetchPlaylistVideoRenderersFromInnertube(
          playlistId: playlistId,
          apiKey: apiKey,
          clientVersion: clientVersion,
        );
      }
      if (renderers.isEmpty) {
        final initialDataJson = _extractInitialDataJson(body);
        if (initialDataJson != null) {
          try {
            final data = jsonDecode(initialDataJson);
            renderers = _extractPlaylistVideoRenderersFromData(data);
          } catch (_) {
            renderers = [];
          }
        }
      }
      if (renderers.isEmpty) {
        renderers = _extractPlaylistVideoRenderersFromHtml(body);
      }

      if (renderers.isEmpty) {
        _setPlaylistImportError(
          'Parse error: could not read videos from this playlist page.',
        );
        return 0;
      }

      final cId = const Uuid().v4();
      int added = 0;
      final seenVideoIds = <String>{};

      for (final renderer in renderers) {
        final videoId = renderer['videoId'] as String?;
        if (videoId == null || videoId.isEmpty || !seenVideoIds.add(videoId)) {
          continue;
        }

        final vTitle = _extractText(renderer['title']) ?? 'Untitled';
        final duration = _extractDurationSeconds(renderer);

        final lecture = LectureModel(
          id: const Uuid().v4(),
          title: vTitle,
          url: 'https://www.youtube.com/watch?v=$videoId',
          videoId: videoId,
          totalDurationSeconds: duration,
          createdAt: DateTime.now(),
          courseId: cId,
          courseTitle: playlistTitle,
        );
        await DatabaseService.insertLecture(lecture);
        _lectures.add(lecture);
        SyncService.pushLecture(lecture);
        added++;
      }

      if (added > 0) {
        await _syncWidget();
      } else {
        _setPlaylistImportError(
          'Parse error: playlist loaded but no playable videos were found.',
        );
      }
      return added;
    } on SocketException {
      _setPlaylistImportError(
        'Network error: could not reach YouTube. Check your connection.',
      );
      return 0;
    } on TimeoutException {
      _setPlaylistImportError(
        'Timeout: YouTube took too long to respond. Try again.',
      );
      return 0;
    } catch (e) {
      _setPlaylistImportError(
        'Parse error: ${e.toString()}',
      );
      return 0;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- Course helpers ---

  static String _extractPlaylistTitle(String body) {
    final titleMatch = RegExp(
      r'<title>(.*?)(?:\s*-\s*YouTube)?</title>',
      caseSensitive: false,
      dotAll: true,
    ).firstMatch(body);
    final title = titleMatch?.group(1)?.trim();
    return title == null || title.isEmpty ? 'Untitled Playlist' : title;
  }

  static String? _extractInitialDataJson(String body) {
    const markers = [
      'var ytInitialData = ',
      'window["ytInitialData"] = ',
      'ytInitialData = ',
    ];

    for (final marker in markers) {
      final markerIndex = body.indexOf(marker);
      if (markerIndex == -1) continue;

      final jsonStart = body.indexOf('{', markerIndex + marker.length);
      if (jsonStart == -1) continue;

      final json = _extractBalancedJsonObject(body, jsonStart);
      if (json != null) return json;
    }

    return null;
  }

  static String? _extractInnertubeApiKey(String body) {
    final match = RegExp(r'"INNERTUBE_API_KEY":"([^"]+)"').firstMatch(body);
    return match?.group(1);
  }

  static String? _extractInnertubeClientVersion(String body) {
    final match = RegExp(
      r'"INNERTUBE_CLIENT_VERSION":"([^"]+)"',
    ).firstMatch(body);
    return match?.group(1);
  }

  static Future<List<Map<String, dynamic>>>
  _fetchPlaylistVideoRenderersFromInnertube({
    required String playlistId,
    required String apiKey,
    required String clientVersion,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('https://www.youtube.com/youtubei/v1/browse?key=$apiKey'),
            headers: {
              'Content-Type': 'application/json',
              'User-Agent': 'Mozilla/5.0',
              'X-YouTube-Client-Name': '1',
              'X-YouTube-Client-Version': clientVersion,
            },
            body: jsonEncode({
              'context': {
                'client': {
                  'clientName': 'WEB',
                  'clientVersion': clientVersion,
                  'hl': 'en',
                  'gl': 'US',
                },
              },
              'browseId': 'VL$playlistId',
            }),
          )
          .timeout(const Duration(seconds: 12));

      if (response.statusCode != 200 || response.body.isEmpty) {
        return [];
      }

      final data = jsonDecode(response.body);
      return _extractPlaylistVideoRenderersFromData(data);
    } catch (_) {
      return [];
    }
  }

  static String? _extractBalancedJsonObject(String source, int startIndex) {
    var depth = 0;
    var inString = false;
    var escaped = false;

    for (var i = startIndex; i < source.length; i++) {
      final char = source[i];

      if (escaped) {
        escaped = false;
        continue;
      }

      if (char == '\\') {
        if (inString) escaped = true;
        continue;
      }

      if (char == '"') {
        inString = !inString;
        continue;
      }

      if (inString) continue;

      if (char == '{') {
        depth++;
      } else if (char == '}') {
        depth--;
        if (depth == 0) {
          return source.substring(startIndex, i + 1);
        }
      }
    }

    return null;
  }

  static List<Map<String, dynamic>> _extractPlaylistVideoRenderersFromData(
    dynamic node,
  ) {
    final renderers = <Map<String, dynamic>>[];
    final seenVideoIds = <String>{};

    void walk(dynamic value) {
      if (value is List) {
        for (final item in value) {
          walk(item);
        }
        return;
      }

      if (value is! Map) return;

      for (final entry in value.entries) {
        final key = entry.key?.toString();
        final child = entry.value;

        if ((key == 'playlistVideoRenderer' ||
                key == 'playlistPanelVideoRenderer') &&
            child is Map) {
          final renderer = Map<String, dynamic>.from(child);
          final videoId = renderer['videoId'] as String?;
          if (videoId != null &&
              videoId.isNotEmpty &&
              seenVideoIds.add(videoId)) {
            renderers.add(renderer);
          }
        }

        walk(child);
      }
    }

    walk(node);
    return renderers;
  }

  static List<Map<String, dynamic>> _extractPlaylistVideoRenderersFromHtml(
    String body,
  ) {
    final renderers = <Map<String, dynamic>>[];
    final seenVideoIds = <String>{};
    final patterns = [
      RegExp(
        r'"(?:playlistVideoRenderer|playlistPanelVideoRenderer)":\{.*?"videoId":"([a-zA-Z0-9_-]{11})".*?"title":\{"runs":\[\{"text":"((?:\\.|[^"\\])*)"',
        dotAll: true,
      ),
      RegExp(
        r'"(?:playlistVideoRenderer|playlistPanelVideoRenderer)":\{.*?"videoId":"([a-zA-Z0-9_-]{11})".*?"title":\{"simpleText":"((?:\\.|[^"\\])*)"',
        dotAll: true,
      ),
      RegExp(
        r'"(?:playlistVideoRenderer|playlistPanelVideoRenderer)":\{[^{}]*?"videoId":"([a-zA-Z0-9_-]{11})"',
        dotAll: true,
      ),
    ];

    for (final pattern in patterns) {
      for (final match in pattern.allMatches(body)) {
        final videoId = match.group(1);
        if (videoId == null || !seenVideoIds.add(videoId)) continue;

        final matchedTitle = match.groupCount >= 2 ? match.group(2) : null;
        renderers.add({
          'videoId': videoId,
          'title': {'simpleText': _decodeJsonText(matchedTitle ?? 'Untitled')},
        });
      }
    }

    // Last-resort fallback: raw watch URLs often still expose playlist videos.
    if (renderers.isEmpty) {
      final watchUrlMatches = RegExp(
        r'/watch\?v=([a-zA-Z0-9_-]{11})',
      ).allMatches(body);
      for (final match in watchUrlMatches) {
        final videoId = match.group(1);
        if (videoId == null || !seenVideoIds.add(videoId)) continue;
        renderers.add({
          'videoId': videoId,
          'title': {'simpleText': 'Untitled'},
        });
      }
    }

    return renderers;
  }

  static String? _extractText(dynamic value) {
    if (value is String) {
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }

    if (value is Map) {
      final simpleText = value['simpleText'];
      if (simpleText is String && simpleText.trim().isNotEmpty) {
        return simpleText.trim();
      }

      final runs = value['runs'];
      if (runs is List) {
        final text = runs
            .whereType<Map>()
            .map((run) => run['text'])
            .whereType<String>()
            .join()
            .trim();
        if (text.isNotEmpty) return text;
      }
    }

    return null;
  }

  static int _extractDurationSeconds(Map<String, dynamic> renderer) {
    final lengthSeconds = renderer['lengthSeconds'];
    if (lengthSeconds is String) {
      final parsed = int.tryParse(lengthSeconds);
      if (parsed != null) return parsed;
    }

    final durationText = _extractText(renderer['lengthText']);
    if (durationText == null) return 0;

    final parts = durationText
        .split(':')
        .map((part) => int.tryParse(part.trim()))
        .toList();

    if (parts.any((part) => part == null)) return 0;
    final values = parts.cast<int>();

    if (values.length == 2) {
      return values[0] * 60 + values[1];
    }

    if (values.length == 3) {
      return values[0] * 3600 + values[1] * 60 + values[2];
    }

    return 0;
  }

  static String _decodeJsonText(String text) {
    return text
        .replaceAll(r'\"', '"')
        .replaceAll(r"\'", "'")
        .replaceAll(r'\n', ' ')
        .replaceAll(r'\u0026', '&');
  }

  static String? _detectPlaylistAvailabilityError(String body) {
    final unavailablePhrases = [
      'This playlist is private',
      'This playlist does not exist',
      'The playlist does not exist',
      'This playlist is unavailable',
      'playlist is unavailable',
    ];
    for (final phrase in unavailablePhrases) {
      if (body.contains(phrase)) {
        return 'Playlist unavailable: $phrase';
      }
    }
    return null;
  }

  void _setPlaylistImportError(String message) {
    _lastPlaylistImportError = message;
    debugPrint('[PlaylistImport] $message');
  }

  /// Get unique course groups: `Map<courseId, {title, lectures}>`.
  Map<String, Map<String, dynamic>> get courses {
    final map = <String, Map<String, dynamic>>{};
    for (final l in _lectures) {
      if (l.courseId == null) continue;
      map.putIfAbsent(
        l.courseId!,
        () => {
          'title': l.courseTitle ?? 'Course',
          'lectures': <LectureModel>[],
        },
      );
      (map[l.courseId!]!['lectures'] as List<LectureModel>).add(l);
    }
    return map;
  }

  /// Lectures not part of any course
  List<LectureModel> get standaloneLectures =>
      _lectures.where((l) => l.courseId == null).toList();

  /// Progress for a course: {completed, total, percent}
  Map<String, dynamic> courseProgress(String courseId) {
    final lecs = _lectures.where((l) => l.courseId == courseId).toList();
    final completed = lecs.where((l) => l.completed).length;
    final total = lecs.length;
    return {
      'completed': completed,
      'total': total,
      'percent': total > 0 ? (completed / total * 100).round() : 0,
    };
  }

  /// Extract playlist ID from YouTube URL
  static String? extractPlaylistId(String url) {
    final trimmed = url.trim();
    final uri = Uri.tryParse(trimmed);
    if (uri != null) {
      final listId = uri.queryParameters['list'];
      if (listId != null && listId.isNotEmpty) return listId;
    }

    final match = RegExp(r'[?&]list=([a-zA-Z0-9_-]+)').firstMatch(trimmed);
    if (match != null) return match.group(1);

    // Allow users to paste just the playlist ID.
    if (RegExp(r'^[a-zA-Z0-9_-]{10,}$').hasMatch(trimmed)) {
      return trimmed;
    }

    return null;
  }

  Future<void> updateProgress(
    String id,
    int watchedSeconds,
    int lastPosition,
  ) async {
    final idx = _lectures.indexWhere((l) => l.id == id);
    if (idx == -1) return;
    final lecture = _lectures[idx];
    lecture.watchedSeconds = watchedSeconds;
    lecture.lastPositionSeconds = lastPosition;

    final wasCompleted = lecture.completed;

    if (watchedSeconds >= lecture.totalDurationSeconds * 0.95) {
      lecture.completed = true;
    }

    await DatabaseService.updateLecture(lecture);
    lecture.chunks = lecture.generateChunks();

    // If just completed, update stats (XP, streak, counter)
    if (lecture.completed && !wasCompleted) {
      final stats = await DatabaseService.getUserStats();
      stats.totalLecturesCompleted++;
      stats.addXP(30);
      stats.updateStreak();
      await DatabaseService.updateUserStats(stats);

      await DatabaseService.recordDailyStats(
        tasksCompleted: 0,
        lectureMinutes: 1,
        xpEarned: 30,
      );
    } else {
      // Record study time
      await DatabaseService.recordDailyStats(
        tasksCompleted: 0,
        lectureMinutes: 1,
        xpEarned: 0,
      );
    }

    _syncWidget();
    SyncService.pushLecture(lecture);
    notifyListeners();
  }

  Future<void> updateLectureDetails(
    String id, {
    String? title,
    String? subtitle,
    int? watchedSeconds,
  }) async {
    final idx = _lectures.indexWhere((l) => l.id == id);
    if (idx == -1) return;
    final lecture = _lectures[idx];
    if (title != null) lecture.title = title;
    if (subtitle != null) lecture.subtitle = subtitle;
    if (watchedSeconds != null) {
      lecture.watchedSeconds = watchedSeconds;
      if (watchedSeconds >= lecture.totalDurationSeconds * 0.95) {
        lecture.completed = true;
      }
    }
    await DatabaseService.updateLecture(lecture);
    lecture.chunks = lecture.generateChunks();
    _syncWidget();
    SyncService.pushLecture(lecture);
    notifyListeners();
  }

  Future<void> setDuration(String id, int durationSeconds) async {
    final idx = _lectures.indexWhere((l) => l.id == id);
    if (idx == -1) return;
    _lectures[idx].totalDurationSeconds = durationSeconds;
    _lectures[idx].chunks = _lectures[idx].generateChunks();
    await DatabaseService.updateLecture(_lectures[idx]);
    notifyListeners();
  }

  Future<void> addNote(
    String lectureId,
    int timestampSeconds,
    String content,
  ) async {
    final note = LectureNote(
      id: const Uuid().v4(),
      timestampSeconds: timestampSeconds,
      content: content,
    );
    await DatabaseService.insertNote(lectureId, note);
    SyncService.pushNote(lectureId, note);
    final idx = _lectures.indexWhere((l) => l.id == lectureId);
    if (idx != -1) {
      _lectures[idx].notes = List.from(_lectures[idx].notes)..add(note);
      _lectures[idx].notes.sort(
        (a, b) => a.timestampSeconds.compareTo(b.timestampSeconds),
      );
    }
    notifyListeners();
  }

  Future<void> deleteNote(String lectureId, String noteId) async {
    await DatabaseService.deleteNote(noteId);
    SyncService.deleteNote(noteId);
    final idx = _lectures.indexWhere((l) => l.id == lectureId);
    if (idx != -1) {
      _lectures[idx].notes = _lectures[idx].notes
          .where((n) => n.id != noteId)
          .toList();
    }
    notifyListeners();
  }

  Future<void> deleteLecture(String id) async {
    await DatabaseService.deleteLecture(id);
    _lectures.removeWhere((l) => l.id == id);
    notifyListeners();
    _syncWidget();
    SyncService.deleteLecture(id);
  }

  Future<void> deleteCourse(String courseId) async {
    final courseLectures = _lectures
        .where((l) => l.courseId == courseId)
        .toList();
    for (final l in courseLectures) {
      await DatabaseService.deleteLecture(l.id);
    }
    _lectures.removeWhere((l) => l.courseId == courseId);
    notifyListeners();
    _syncWidget();
  }

  // -- Sub-Tasks --
  Future<void> addSubTask(String lectureId, String title) async {
    final st = LectureSubTask(id: const Uuid().v4(), title: title);
    await DatabaseService.insertSubTask(lectureId, st);
    SyncService.pushSubTask(lectureId, st);
    final idx = _lectures.indexWhere((l) => l.id == lectureId);
    if (idx != -1) {
      _lectures[idx].subTasks = List.from(_lectures[idx].subTasks)..add(st);
    }
    notifyListeners();
  }

  Future<void> toggleSubTask(String lectureId, String subTaskId) async {
    final idx = _lectures.indexWhere((l) => l.id == lectureId);
    if (idx == -1) return;
    final stIdx = _lectures[idx].subTasks.indexWhere((s) => s.id == subTaskId);
    if (stIdx == -1) return;
    _lectures[idx].subTasks[stIdx].completed =
        !_lectures[idx].subTasks[stIdx].completed;
    await DatabaseService.updateSubTask(_lectures[idx].subTasks[stIdx]);
    SyncService.pushSubTask(lectureId, _lectures[idx].subTasks[stIdx]);
    notifyListeners();
  }

  Future<void> deleteSubTask(String lectureId, String subTaskId) async {
    await DatabaseService.deleteSubTask(subTaskId);
    SyncService.deleteSubTask(subTaskId);
    final idx = _lectures.indexWhere((l) => l.id == lectureId);
    if (idx != -1) {
      _lectures[idx].subTasks = _lectures[idx].subTasks
          .where((s) => s.id != subTaskId)
          .toList();
    }
    notifyListeners();
  }

  /// Fetch title, thumbnail, and duration from a YouTube URL (no API key needed)
  static Future<VideoInfo?> fetchVideoInfo(String url) async {
    final videoId = extractVideoId(url);
    if (videoId == null) return null;
    try {
      // oEmbed gives us title + thumbnail
      final oembedRes = await http
          .get(
            Uri.parse(
              'https://www.youtube.com/oembed?url=https://www.youtube.com/watch?v=$videoId&format=json',
            ),
          )
          .timeout(const Duration(seconds: 10));
      if (oembedRes.statusCode != 200) return null;
      final data = jsonDecode(oembedRes.body) as Map<String, dynamic>;
      final title = data['title'] as String? ?? '';
      final thumbnail = 'https://img.youtube.com/vi/$videoId/hqdefault.jpg';

      // Parse duration from YouTube page HTML
      int durationSeconds = 0;
      final pageRes = await http
          .get(
            Uri.parse('https://www.youtube.com/watch?v=$videoId'),
            headers: {'User-Agent': 'Mozilla/5.0'},
          )
          .timeout(const Duration(seconds: 10));
      if (pageRes.statusCode == 200) {
        final match = RegExp(
          r'"lengthSeconds":"(\d+)"',
        ).firstMatch(pageRes.body);
        if (match != null) durationSeconds = int.tryParse(match.group(1)!) ?? 0;
      }

      return VideoInfo(
        title: title,
        thumbnailUrl: thumbnail,
        durationSeconds: durationSeconds,
      );
    } catch (_) {
      return null;
    }
  }

  /// Extract YouTube video ID from various URL formats
  static String? extractVideoId(String url) {
    final trimmed = url.trim();
    final uri = Uri.tryParse(trimmed);

    if (uri != null) {
      final host = uri.host.toLowerCase();
      final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();

      if (host.contains('youtu.be')) {
        if (segments.isNotEmpty && _isValidYouTubeId(segments.first)) {
          return segments.first;
        }
      }

      if (host.contains('youtube.com') ||
          host.contains('youtube-nocookie.com')) {
        final fromQuery = uri.queryParameters['v'];
        if (_isValidYouTubeId(fromQuery)) return fromQuery;

        for (var i = 0; i < segments.length - 1; i++) {
          final marker = segments[i].toLowerCase();
          if ((marker == 'embed' ||
                  marker == 'v' ||
                  marker == 'shorts' ||
                  marker == 'live') &&
              _isValidYouTubeId(segments[i + 1])) {
            return segments[i + 1];
          }
        }
      }
    }

    final patterns = [
      RegExp(r'(?:youtube\.com\/watch\?v=)([a-zA-Z0-9_-]{11})'),
      RegExp(r'(?:youtu\.be\/)([a-zA-Z0-9_-]{11})'),
      RegExp(r'(?:youtube\.com\/embed\/)([a-zA-Z0-9_-]{11})'),
      RegExp(r'(?:youtube\.com\/v\/)([a-zA-Z0-9_-]{11})'),
      RegExp(r'(?:youtube\.com\/shorts\/)([a-zA-Z0-9_-]{11})'),
      RegExp(r'(?:youtube\.com\/live\/)([a-zA-Z0-9_-]{11})'),
    ];
    for (final pattern in patterns) {
      final match = pattern.firstMatch(trimmed);
      if (match != null) return match.group(1);
    }
    // Check if the input itself is a video ID
    if (_isValidYouTubeId(trimmed)) return trimmed;
    return null;
  }

  static bool _isValidYouTubeId(String? value) {
    if (value == null) return false;
    return RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(value);
  }
}
