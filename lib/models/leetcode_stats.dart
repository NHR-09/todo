class LeetCodeStats {
  final String username;
  final int totalSolved;
  final int easySolved;
  final int mediumSolved;
  final int hardSolved;
  final int totalEasy;
  final int totalMedium;
  final int totalHard;
  final int ranking;
  final int streak;
  final int totalSubmissions;
  final int acceptanceRate;
  final String? realName;
  final String? avatarUrl;
  final Map<String, int> submissionCalendar; // unix timestamp -> count

  LeetCodeStats({
    required this.username,
    this.totalSolved = 0,
    this.easySolved = 0,
    this.mediumSolved = 0,
    this.hardSolved = 0,
    this.totalEasy = 0,
    this.totalMedium = 0,
    this.totalHard = 0,
    this.ranking = 0,
    this.streak = 0,
    this.totalSubmissions = 0,
    this.acceptanceRate = 0,
    this.realName,
    this.avatarUrl,
    this.submissionCalendar = const {},
  });

  int get totalQuestions => totalEasy + totalMedium + totalHard;
  double get overallProgress => totalQuestions > 0 ? totalSolved / totalQuestions : 0;
  double get easyProgress => totalEasy > 0 ? easySolved / totalEasy : 0;
  double get mediumProgress => totalMedium > 0 ? mediumSolved / totalMedium : 0;
  double get hardProgress => totalHard > 0 ? hardSolved / totalHard : 0;

  /// Get submissions for last N days
  Map<DateTime, int> recentActivity(int days) {
    final now = DateTime.now();
    final result = <DateTime, int>{};
    for (final entry in submissionCalendar.entries) {
      final date = DateTime.fromMillisecondsSinceEpoch(int.parse(entry.key) * 1000);
      if (now.difference(date).inDays <= days) {
        final dayKey = DateTime(date.year, date.month, date.day);
        result[dayKey] = (result[dayKey] ?? 0) + entry.value;
      }
    }
    return result;
  }
}
