import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../providers/stats_provider.dart';
import '../providers/task_provider.dart';
import '../providers/lecture_provider.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final stats = context.watch<StatsProvider>();
    final tasks = context.watch<TaskProvider>();
    final lectures = context.watch<LectureProvider>();
    final dailyStats = stats.dailyStats;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Summary row
        Row(children: [
          _statItem(context, '${stats.stats.totalXP}', 'Total XP', NHRColors.terracotta),
          _statItem(context, '${stats.stats.totalTasksCompleted}', 'Tasks Done', NHRColors.slate),
          _statItem(context, (stats.stats.totalStudyMinutes / 60).toStringAsFixed(1), 'Study Hrs', NHRColors.sage),
        ]).animate().fadeIn(duration: 400.ms),
        const SizedBox(height: 32),

        // Weekly chart
        _sectionLabel(context, 'THIS WEEK'),
        const SizedBox(height: 14),
        Container(
          height: 180,
          padding: const EdgeInsets.fromLTRB(12, 20, 12, 12),
          decoration: BoxDecoration(
            color: NHRColors.milkDeep,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: NHRColors.fog),
          ),
          child: _buildBarChart(dailyStats),
        ).animate().fadeIn(delay: 200.ms),
        const SizedBox(height: 32),

        // Category breakdown
        _sectionLabel(context, 'CATEGORIES'),
        const SizedBox(height: 14),
        _buildCategoryBreakdown(context, tasks).animate().fadeIn(delay: 400.ms),
        const SizedBox(height: 32),

        // Lectures overview
        _sectionLabel(context, 'LECTURES'),
        const SizedBox(height: 14),
        Row(children: [
          _statItem(context, '${lectures.completedLectures.length}', 'Done', NHRColors.sage),
          _statItem(context, '${lectures.inProgressLectures.length}', 'In Progress', NHRColors.slate),
          _statItem(context, '${lectures.lectures.where((l) => l.watchedSeconds == 0 && !l.completed).length}', 'Not Started', NHRColors.dusty),
        ]).animate().fadeIn(delay: 600.ms),
        const SizedBox(height: 40),
      ]),
    );
  }

  Widget _sectionLabel(BuildContext context, String text) {
    return Text(text, style: GoogleFonts.inter(
      fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2.5, color: NHRColors.dusty));
  }

  Widget _statItem(BuildContext context, String value, String label, Color accent) {
    return Expanded(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value, style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700, color: NHRColors.charcoal)),
        const SizedBox(height: 2),
        Row(children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: accent)),
          const SizedBox(width: 6),
          Text(label, style: GoogleFonts.inter(fontSize: 11, color: NHRColors.dusty)),
        ]),
      ]),
    );
  }

  Widget _buildBarChart(List<Map<String, dynamic>> daily) {
    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return BarChart(BarChartData(
      barTouchData: BarTouchData(enabled: false),
      titlesData: FlTitlesData(
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 24,
          getTitlesWidget: (v, _) => Padding(padding: const EdgeInsets.only(top: 8),
            child: Text(days[v.toInt() % 7], style: GoogleFonts.inter(fontSize: 11, color: NHRColors.dusty))))),
      ),
      borderData: FlBorderData(show: false),
      gridData: const FlGridData(show: false),
      barGroups: List.generate(daily.length.clamp(0, 7), (i) {
        final val = (daily.length > i ? (daily[i]['tasksCompleted'] ?? 0) as int : 0).toDouble();
        return BarChartGroupData(x: i, barRods: [
          BarChartRodData(
            toY: val, width: 12,
            color: NHRColors.sage,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ]);
      }),
    ));
  }

  Widget _buildCategoryBreakdown(BuildContext context, TaskProvider tasks) {
    final categories = <String, int>{};
    for (final t in tasks.tasks) {
      final name = t.category.name;
      categories[name] = (categories[name] ?? 0) + 1;
    }
    if (categories.isEmpty) {
      return Text('No tasks to analyze', style: GoogleFonts.inter(fontSize: 12, color: NHRColors.dusty));
    }
    final colors = [NHRColors.terracotta, NHRColors.sage, NHRColors.slate, NHRColors.sand, NHRColors.dusty];
    final entries = categories.entries.toList();
    final total = entries.fold<int>(0, (a, b) => a + b.value);
    return Column(children: entries.asMap().entries.map((e) {
      final frac = e.value.value / total;
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(
            shape: BoxShape.circle, color: colors[e.key % colors.length])),
          const SizedBox(width: 12),
          SizedBox(width: 80, child: Text(e.value.key, style: GoogleFonts.inter(fontSize: 13, color: NHRColors.charcoal))),
          Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(value: frac, minHeight: 4,
              backgroundColor: NHRColors.fog,
              valueColor: AlwaysStoppedAnimation(colors[e.key % colors.length])))),
          const SizedBox(width: 10),
          Text('${e.value.value}', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: NHRColors.dusty)),
        ]),
      );
    }).toList());
  }
}
