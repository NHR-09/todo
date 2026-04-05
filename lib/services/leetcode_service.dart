import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/leetcode_stats.dart';

class LeetCodeService {
  static const _endpoint = 'https://leetcode.com/graphql';

  static const _profileQuery = '''
    query getUserProfile(\$username: String!) {
      matchedUser(username: \$username) {
        username
        profile {
          realName
          ranking
          userAvatar
        }
        submitStatsGlobal {
          acSubmissionNum {
            difficulty
            count
          }
        }
        userCalendar {
          streak
          totalActiveDays
          submissionCalendar
        }
        submitStats {
          totalSubmissionNum {
            difficulty
            count
            submissions
          }
          acSubmissionNum {
            difficulty
            count
            submissions
          }
        }
      }
      allQuestionsCount {
        difficulty
        count
      }
    }
  ''';

  static Future<LeetCodeStats?> fetchStats(String username) async {
    try {
      final response = await http.post(
        Uri.parse(_endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Referer': 'https://leetcode.com/$username/',
        },
        body: jsonEncode({
          'query': _profileQuery,
          'variables': {'username': username},
        }),
      );

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body);
      final user = data['data']?['matchedUser'];
      if (user == null) return null;

      final allQuestions = data['data']?['allQuestionsCount'] as List? ?? [];
      final acSubmissions = user['submitStatsGlobal']?['acSubmissionNum'] as List? ?? [];
      final calendar = user['userCalendar'];

      // Parse total questions by difficulty
      int totalEasy = 0, totalMedium = 0, totalHard = 0;
      for (final q in allQuestions) {
        switch (q['difficulty']) {
          case 'Easy': totalEasy = q['count'] ?? 0;
          case 'Medium': totalMedium = q['count'] ?? 0;
          case 'Hard': totalHard = q['count'] ?? 0;
        }
      }

      // Parse solved by difficulty
      int easySolved = 0, mediumSolved = 0, hardSolved = 0, totalSolved = 0;
      for (final s in acSubmissions) {
        switch (s['difficulty']) {
          case 'Easy': easySolved = s['count'] ?? 0;
          case 'Medium': mediumSolved = s['count'] ?? 0;
          case 'Hard': hardSolved = s['count'] ?? 0;
          case 'All': totalSolved = s['count'] ?? 0;
        }
      }

      // Parse submission calendar
      Map<String, int> submissionCalendar = {};
      final calendarStr = calendar?['submissionCalendar'];
      if (calendarStr != null && calendarStr is String) {
        try {
          final parsed = jsonDecode(calendarStr) as Map<String, dynamic>;
          submissionCalendar = parsed.map((k, v) => MapEntry(k, v as int));
        } catch (_) {}
      }

      // Parse total submissions & acceptance
      int totalSubmissions = 0;
      int acceptedSubmissions = 0;
      final submitStats = user['submitStats'];
      if (submitStats != null) {
        final totalNums = submitStats['totalSubmissionNum'] as List? ?? [];
        final acNums = submitStats['acSubmissionNum'] as List? ?? [];
        for (final t in totalNums) {
          if (t['difficulty'] == 'All') totalSubmissions = t['submissions'] ?? 0;
        }
        for (final a in acNums) {
          if (a['difficulty'] == 'All') acceptedSubmissions = a['submissions'] ?? 0;
        }
      }
      final acceptanceRate = totalSubmissions > 0
          ? ((acceptedSubmissions / totalSubmissions) * 100).round()
          : 0;

      return LeetCodeStats(
        username: user['username'] ?? username,
        totalSolved: totalSolved,
        easySolved: easySolved,
        mediumSolved: mediumSolved,
        hardSolved: hardSolved,
        totalEasy: totalEasy,
        totalMedium: totalMedium,
        totalHard: totalHard,
        ranking: user['profile']?['ranking'] ?? 0,
        streak: calendar?['streak'] ?? 0,
        totalSubmissions: totalSubmissions,
        acceptanceRate: acceptanceRate,
        realName: user['profile']?['realName'],
        avatarUrl: user['profile']?['userAvatar'],
        submissionCalendar: submissionCalendar,
      );
    } catch (_) {
      return null;
    }
  }
}
