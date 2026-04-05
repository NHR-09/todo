class UserStats {
  int totalXP;
  int currentLevel;
  int streakDays;
  DateTime? lastActiveDate;
  int totalTasksCompleted;
  int totalLecturesCompleted;
  int totalStudyMinutes;
  List<String> unlockedThemes;
  String currentTheme;
  String username;

  UserStats({
    this.totalXP = 0,
    this.currentLevel = 1,
    this.streakDays = 0,
    this.lastActiveDate,
    this.totalTasksCompleted = 0,
    this.totalLecturesCompleted = 0,
    this.totalStudyMinutes = 0,
    this.unlockedThemes = const ['iron_man'],
    this.currentTheme = 'iron_man',
    this.username = 'Super Hero',
  });

  String get heroTitle {
    if (currentLevel >= 20) return 'LEGEND';
    if (currentLevel >= 15) return 'CHAMPION';
    if (currentLevel >= 10) return 'AVENGER';
    if (currentLevel >= 5) return 'AGENT';
    return 'RECRUIT';
  }

  int get xpForNextLevel => currentLevel * 100 + 50;
  int get xpInCurrentLevel => totalXP - _xpForLevel(currentLevel);
  double get levelProgress =>
      (xpInCurrentLevel / xpForNextLevel).clamp(0.0, 1.0);

  int _xpForLevel(int level) {
    int total = 0;
    for (int i = 1; i < level; i++) {
      total += i * 100 + 50;
    }
    return total;
  }

  void addXP(int xp) {
    totalXP += xp;
    while (xpInCurrentLevel >= xpForNextLevel) {
      currentLevel++;
    }
  }

  void updateStreak() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (lastActiveDate == null) {
      streakDays = 1;
    } else {
      final lastDate = DateTime(
        lastActiveDate!.year,
        lastActiveDate!.month,
        lastActiveDate!.day,
      );
      final diff = today.difference(lastDate).inDays;
      if (diff == 1) {
        streakDays++;
      } else if (diff > 1) {
        streakDays = 1; // reset
      }
      // diff == 0 means same day, no change
    }
    lastActiveDate = now;
  }

  Map<String, dynamic> toMap() => {
        'totalXP': totalXP,
        'currentLevel': currentLevel,
        'streakDays': streakDays,
        'lastActiveDate': lastActiveDate?.toIso8601String(),
        'totalTasksCompleted': totalTasksCompleted,
        'totalLecturesCompleted': totalLecturesCompleted,
        'totalStudyMinutes': totalStudyMinutes,
        'unlockedThemes': unlockedThemes.join(','),
        'currentTheme': currentTheme,
        'username': username,
      };

  factory UserStats.fromMap(Map<String, dynamic> map) => UserStats(
        totalXP: (map['totalXP'] as int?) ?? 0,
        currentLevel: (map['currentLevel'] as int?) ?? 1,
        streakDays: (map['streakDays'] as int?) ?? 0,
        lastActiveDate: map['lastActiveDate'] != null
            ? DateTime.parse(map['lastActiveDate'] as String)
            : null,
        totalTasksCompleted: (map['totalTasksCompleted'] as int?) ?? 0,
        totalLecturesCompleted: (map['totalLecturesCompleted'] as int?) ?? 0,
        totalStudyMinutes: (map['totalStudyMinutes'] as int?) ?? 0,
        unlockedThemes: map['unlockedThemes'] != null
            ? (map['unlockedThemes'] as String).split(',')
            : ['iron_man'],
        currentTheme: (map['currentTheme'] as String?) ?? 'iron_man',
        username: (map['username'] as String?) ?? 'Super Hero',
      );
}
