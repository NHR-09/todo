import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';
import '../providers/task_provider.dart';
import '../providers/lecture_provider.dart';
import '../providers/stats_provider.dart';
import '../providers/notification_provider.dart';
import '../services/smart_engine.dart';
import '../main.dart';
import 'notifications_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    final lectureProvider = context.watch<LectureProvider>();
    final statsProvider = context.watch<StatsProvider>();
    final stats = statsProvider.stats;

    final suggestions = SmartEngine.generateSuggestions(
      tasks: taskProvider.tasks,
      lectures: lectureProvider.lectures,
      stats: stats,
    );

    final pendingTasks = taskProvider.tasks.where((t) => !t.completed).length;
    final pendingLecs = lectureProvider.lectures.where((l) => !l.completed).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),

          // ── Hero Section ──
          _buildHero(context, stats)
            .animate().fadeIn(duration: 600.ms).slideY(begin: 0.03),
          const SizedBox(height: 32),

          // ── LeetCode Style Stats ──
          _buildLeetCodeStats(context, pendingTasks, pendingLecs, stats)
            .animate().fadeIn(delay: 200.ms, duration: 500.ms),

          const SizedBox(height: 32),

          // ── Suggestions ──
          if (suggestions.isNotEmpty) ...[
            Text('NEXT UP', style: GoogleFonts.inter(
              fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2.5,
              color: NHRColors.dusty)),
            const SizedBox(height: 14),
            ...suggestions.take(3).toList().asMap().entries.map((entry) =>
              _buildSuggestionRow(context, entry.value)
                .animate().fadeIn(delay: (400 + entry.key * 100).ms)),
            const SizedBox(height: 28),
          ],

          // ── Continue Learning ──
          if (lectureProvider.inProgressLectures.isNotEmpty) ...[
            Text('CONTINUE', style: GoogleFonts.inter(
              fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2.5,
              color: NHRColors.dusty)),
            const SizedBox(height: 14),
            ...lectureProvider.inProgressLectures.take(2).toList().asMap().entries.map((entry) =>
              _buildLectureRow(context, entry.value)
                .animate().fadeIn(delay: (500 + entry.key * 100).ms)),
          ],

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildHero(BuildContext context, dynamic stats) {
    final notificationProvider = context.watch<NotificationProvider>();
    final unreadCount = notificationProvider.unreadCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Rank label
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: NHRColors.fog),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                stats.heroTitle.toString().toUpperCase(),
                style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600,
                  letterSpacing: 2, color: NHRColors.dusty),
              ),
            ),
            // Notification bell
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                );
              },
              child: Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: NHRColors.milkDeep,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: NHRColors.fog),
                    ),
                    child: Icon(
                      Icons.notifications_outlined,
                      size: 20,
                      color: NHRColors.charcoal,
                    ),
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 4,
                      top: 4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: NHRColors.terracotta,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          unreadCount > 9 ? '9+' : '$unreadCount',
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Large greeting
        Builder(builder: (_) {
          final hour = DateTime.now().hour;
          final greeting = hour < 5 ? 'Late\nnight' : hour < 12 ? 'Good\nmorning' : hour < 17 ? 'Good\nafternoon' : hour < 21 ? 'Good\nevening' : 'Late\nnight';
          return Text(
            '$greeting,\n${stats.username}.',
            style: GoogleFonts.poppins(
              fontSize: 42, fontWeight: FontWeight.w800,
              color: NHRColors.charcoal, height: 1.05, letterSpacing: -2,
            ),
          );
        }),
        const SizedBox(height: 12),

        // Subtitle
        RichText(
          text: TextSpan(
            style: GoogleFonts.inter(fontSize: 14, color: NHRColors.dusty, height: 1.5),
            children: [
              TextSpan(text: 'Level ${stats.currentLevel}'),
              TextSpan(text: '  ·  ', style: TextStyle(color: NHRColors.fog)),
              TextSpan(text: '${stats.totalXP} XP'),
              TextSpan(text: '  ·  ', style: TextStyle(color: NHRColors.fog)),
              TextSpan(text: '${stats.streakDays}d streak'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLeetCodeStats(BuildContext context, int pendingTasks, int pendingLecs, dynamic stats) {
    int doneTasks = stats.totalTasksCompleted;
    int doneLecs = stats.totalLecturesCompleted;
    int totalDone = doneTasks + doneLecs;
    int totalPending = pendingTasks + pendingLecs;
    int totalItems = totalDone + totalPending;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: NHRColors.milkDeep,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: NHRColors.fog),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('PROGRESS', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2.5, color: NHRColors.dusty)),
          const SizedBox(height: 20),
          Row(
            children: [
              // Circular Chart
              SizedBox(
                width: 100, height: 100,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 36,
                        startDegreeOffset: -90,
                        sections: totalItems == 0 ? [
                            PieChartSectionData(color: NHRColors.fog, value: 1, title: '', radius: 8)
                          ] : [
                          if (doneTasks > 0) PieChartSectionData(color: NHRColors.sage, value: doneTasks.toDouble(), title: '', radius: 10),
                          if (doneLecs > 0) PieChartSectionData(color: NHRColors.slate, value: doneLecs.toDouble(), title: '', radius: 10),
                          if (totalPending > 0) PieChartSectionData(color: NHRColors.fog, value: totalPending.toDouble(), title: '', radius: 6),
                        ],
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('$totalDone', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: NHRColors.charcoal, height: 1.1)),
                        Text('Done', style: GoogleFonts.inter(fontSize: 10, color: NHRColors.dusty)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 30),
              // Legend
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLegendRow('Tasks Done', doneTasks, NHRColors.sage),
                    const SizedBox(height: 12),
                    _buildLegendRow('Lectures Done', doneLecs, NHRColors.slate),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          // XP Progress
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Level ${stats.currentLevel}', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: NHRColors.charcoal)),
            Text('${stats.xpInCurrentLevel} / ${stats.xpForNextLevel} XP', style: GoogleFonts.inter(fontSize: 11, color: NHRColors.dusty)),
          ]),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: (stats.levelProgress as double).clamp(0.0, 1.0),
              minHeight: 4,
              backgroundColor: NHRColors.fog,
              valueColor: const AlwaysStoppedAnimation(NHRColors.terracotta),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendRow(String label, int value, Color color) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: GoogleFonts.inter(fontSize: 12, color: NHRColors.dusty))),
        Text('$value', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: NHRColors.charcoal)),
      ],
    );
  }

  void _onSuggestionTap(SmartSuggestion suggestion) {
    switch (suggestion.actionType) {
      case 'task': AppShell.navigateToTab(1); break;
      case 'lecture': AppShell.navigateToTab(2); break;
      case 'streak': AppShell.navigateToTab(3); break;
    }
  }

  Widget _buildSuggestionRow(BuildContext context, SmartSuggestion suggestion) {
    IconData icon = Icons.arrow_forward_rounded;
    Color accent = NHRColors.dusty;

    if (suggestion.actionType == 'task') {
      icon = Icons.check_circle_outline;
      accent = NHRColors.terracotta;
    } else if (suggestion.actionType == 'lecture') {
      icon = Icons.play_circle_outline;
      accent = NHRColors.slate;
    } else if (suggestion.actionType == 'streak') {
      icon = Icons.local_fire_department_outlined;
      accent = NHRColors.sand;
    }

    return GestureDetector(
      onTap: () => _onSuggestionTap(suggestion),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: accent, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(suggestion.title, style: GoogleFonts.inter(
              fontSize: 13, fontWeight: FontWeight.w600, color: NHRColors.charcoal)),
            Text(suggestion.subtitle, style: GoogleFonts.inter(
              fontSize: 12, color: NHRColors.dusty)),
          ])),
          Icon(Icons.chevron_right_rounded, color: NHRColors.fog, size: 20),
        ]),
      ),
    );
  }

  Widget _buildLectureRow(BuildContext context, dynamic lecture) {
    return GestureDetector(
      onTap: () => AppShell.navigateToTab(2),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              'https://img.youtube.com/vi/${lecture.videoId}/hqdefault.jpg',
              width: 56, height: 38, fit: BoxFit.cover,
              errorBuilder: (_, e, s) => Container(
                width: 56, height: 38,
                decoration: BoxDecoration(
                  color: NHRColors.fog,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.play_circle_outline, size: 20, color: NHRColors.dusty),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(lecture.title, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: NHRColors.charcoal)),
            const SizedBox(height: 4),
            Row(children: [
              Expanded(child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: (lecture.progressPercent as double).clamp(0.0, 1.0),
                  minHeight: 3,
                  backgroundColor: NHRColors.fog,
                  valueColor: AlwaysStoppedAnimation(NHRColors.sage),
                ),
              )),
              const SizedBox(width: 8),
              Text(lecture.progressText, style: GoogleFonts.inter(
                fontSize: 11, fontWeight: FontWeight.w600, color: NHRColors.sage)),
            ]),
          ])),
        ]),
      ),
    );
  }
}
