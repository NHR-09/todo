import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';
import '../providers/leetcode_provider.dart';
import '../models/leetcode_stats.dart';

class LeetCodeScreen extends StatelessWidget {
  const LeetCodeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LeetCodeProvider>();

    if (!provider.hasUsername) return _buildUsernamePrompt(context);
    if (provider.isLoading && provider.stats == null) return _buildLoading();
    if (provider.error != null && provider.stats == null) return _buildError(context, provider);

    final stats = provider.stats!;
    return RefreshIndicator(
      onRefresh: () => provider.fetchStats(),
      color: NHRColors.charcoal,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 16),

          // Header
          _buildHeader(context, provider, stats)
            .animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 24),

          // Solved Ring
          _buildSolvedRing(stats)
            .animate().fadeIn(delay: 100.ms, duration: 400.ms),
          const SizedBox(height: 24),

          // Difficulty Breakdown
          _buildDifficultyBars(stats)
            .animate().fadeIn(delay: 200.ms, duration: 400.ms),
          const SizedBox(height: 24),

          // Stats Grid
          _buildStatsGrid(stats)
            .animate().fadeIn(delay: 300.ms, duration: 400.ms),
          const SizedBox(height: 24),

          // Activity Heatmap
          _buildActivitySection(stats)
            .animate().fadeIn(delay: 400.ms, duration: 400.ms),
          const SizedBox(height: 80),
        ]),
      ),
    );
  }

  Widget _buildUsernamePrompt(BuildContext context) {
    String username = '';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.code_rounded, size: 48, color: NHRColors.fog),
          const SizedBox(height: 16),
          Text('Connect LeetCode', style: GoogleFonts.poppins(
            fontSize: 20, fontWeight: FontWeight.w700, color: NHRColors.charcoal)),
          const SizedBox(height: 8),
          Text('Enter your LeetCode username to see your stats',
            style: GoogleFonts.inter(fontSize: 13, color: NHRColors.dusty),
            textAlign: TextAlign.center),
          const SizedBox(height: 24),
          TextField(
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'leetcode_username',
              prefixIcon: const Icon(Icons.person_outline, size: 20),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onChanged: (v) => username = v,
            onSubmitted: (v) {
              if (v.trim().isNotEmpty) context.read<LeetCodeProvider>().setUsername(v.trim());
            },
          ),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: () {
              if (username.trim().isNotEmpty) context.read<LeetCodeProvider>().setUsername(username.trim());
            },
            child: const Text('Connect'),
          )),
        ]),
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const CircularProgressIndicator(strokeWidth: 2, color: NHRColors.charcoal),
        const SizedBox(height: 16),
        Text('Fetching LeetCode data...', style: GoogleFonts.inter(color: NHRColors.dusty)),
      ]),
    );
  }

  Widget _buildError(BuildContext context, LeetCodeProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.error_outline, size: 48, color: NHRColors.terracotta),
          const SizedBox(height: 16),
          Text(provider.error!, style: GoogleFonts.inter(color: NHRColors.dusty), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          OutlinedButton(onPressed: () => provider.fetchStats(), child: const Text('Retry')),
          TextButton(
            onPressed: () => provider.setUsername(''),
            child: const Text('Change Username', style: TextStyle(color: NHRColors.dusty)),
          ),
        ]),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, LeetCodeProvider provider, LeetCodeStats stats) {
    return Row(children: [
      // LC Icon
      Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFFFFA116).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(child: Text('LC', style: TextStyle(
          fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFFFFA116)))),
      ),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(stats.username, style: GoogleFonts.poppins(
          fontSize: 18, fontWeight: FontWeight.w700, color: NHRColors.charcoal)),
        if (stats.realName != null && stats.realName!.isNotEmpty)
          Text(stats.realName!, style: GoogleFonts.inter(fontSize: 12, color: NHRColors.dusty)),
      ])),
      // Change username
      IconButton(
        icon: const Icon(Icons.swap_horiz_rounded, size: 20, color: NHRColors.dusty),
        onPressed: () {
          String newName = '';
          showDialog(context: context, builder: (ctx) => AlertDialog(
            backgroundColor: NHRColors.milk,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text('Change Username', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: NHRColors.charcoal)),
            content: TextField(
              autofocus: true,
              decoration: const InputDecoration(hintText: 'leetcode_username'),
              onChanged: (v) => newName = v,
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: NHRColors.dusty))),
              TextButton(onPressed: () {
                if (newName.trim().isNotEmpty) provider.setUsername(newName.trim());
                Navigator.pop(ctx);
              }, child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold))),
            ],
          ));
        },
      ),
      // Refresh
      if (provider.isLoading)
        const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
      else
        IconButton(
          icon: const Icon(Icons.refresh_rounded, size: 20, color: NHRColors.dusty),
          onPressed: () => provider.fetchStats(),
        ),
    ]);
  }

  Widget _buildSolvedRing(LeetCodeStats stats) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: NHRColors.milkDeep,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: NHRColors.fog),
      ),
      child: Row(children: [
        // Donut chart
        SizedBox(
          width: 120, height: 120,
          child: Stack(alignment: Alignment.center, children: [
            PieChart(PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 42,
              startDegreeOffset: -90,
              sections: [
                if (stats.easySolved > 0) PieChartSectionData(
                  color: const Color(0xFF00B8A3), value: stats.easySolved.toDouble(), title: '', radius: 12),
                if (stats.mediumSolved > 0) PieChartSectionData(
                  color: const Color(0xFFFFC01E), value: stats.mediumSolved.toDouble(), title: '', radius: 12),
                if (stats.hardSolved > 0) PieChartSectionData(
                  color: const Color(0xFFEF4743), value: stats.hardSolved.toDouble(), title: '', radius: 12),
                if (stats.totalQuestions - stats.totalSolved > 0) PieChartSectionData(
                  color: NHRColors.fog, value: (stats.totalQuestions - stats.totalSolved).toDouble(), title: '', radius: 6),
              ],
            )),
            Column(mainAxisSize: MainAxisSize.min, children: [
              Text('${stats.totalSolved}', style: GoogleFonts.poppins(
                fontSize: 26, fontWeight: FontWeight.w800, color: NHRColors.charcoal, height: 1)),
              Text('/ ${stats.totalQuestions}', style: GoogleFonts.inter(
                fontSize: 11, color: NHRColors.dusty)),
              Text('Solved', style: GoogleFonts.inter(
                fontSize: 10, color: NHRColors.dusty, fontWeight: FontWeight.w600)),
            ]),
          ]),
        ),
        const SizedBox(width: 28),
        // Legend
        Expanded(child: Column(children: [
          _legendItem('Easy', stats.easySolved, stats.totalEasy, const Color(0xFF00B8A3)),
          const SizedBox(height: 14),
          _legendItem('Medium', stats.mediumSolved, stats.totalMedium, const Color(0xFFFFC01E)),
          const SizedBox(height: 14),
          _legendItem('Hard', stats.hardSolved, stats.totalHard, const Color(0xFFEF4743)),
        ])),
      ]),
    );
  }

  Widget _legendItem(String label, int solved, int total, Color color) {
    final progress = total > 0 ? solved / total : 0.0;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(label, style: GoogleFonts.inter(fontSize: 12, color: NHRColors.dusty)),
        const Spacer(),
        Text('$solved', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: NHRColors.charcoal)),
        Text(' / $total', style: GoogleFonts.inter(fontSize: 11, color: NHRColors.dusty)),
      ]),
      const SizedBox(height: 6),
      ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: LinearProgressIndicator(
          value: progress.clamp(0.0, 1.0), minHeight: 4,
          backgroundColor: NHRColors.fog, valueColor: AlwaysStoppedAnimation(color),
        ),
      ),
    ]);
  }

  Widget _buildDifficultyBars(LeetCodeStats stats) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: NHRColors.milkDeep,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: NHRColors.fog),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('ACCEPTANCE', style: GoogleFonts.inter(
          fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2.5, color: NHRColors.dusty)),
        const SizedBox(height: 16),
        Row(children: [
          _statBlock('${stats.acceptanceRate}%', 'Rate', NHRColors.sage),
          const SizedBox(width: 12),
          _statBlock('${stats.totalSubmissions}', 'Submissions', NHRColors.slate),
          const SizedBox(width: 12),
          _statBlock('#${stats.ranking}', 'Ranking', NHRColors.terracotta),
        ]),
      ]),
    );
  }

  Widget _statBlock(String value, String label, Color accent) {
    return Expanded(child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(children: [
        Text(value, style: GoogleFonts.poppins(
          fontSize: 16, fontWeight: FontWeight.w700, color: NHRColors.charcoal),
          maxLines: 1, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 2),
        Text(label, style: GoogleFonts.inter(fontSize: 10, color: NHRColors.dusty)),
      ]),
    ));
  }

  Widget _buildStatsGrid(LeetCodeStats stats) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: NHRColors.milkDeep,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: NHRColors.fog),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('STREAK', style: GoogleFonts.inter(
          fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2.5, color: NHRColors.dusty)),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: Row(children: [
            Icon(Icons.local_fire_department_rounded, color: const Color(0xFFFFA116), size: 28),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${stats.streak}', style: GoogleFonts.poppins(
                fontSize: 24, fontWeight: FontWeight.w800, color: NHRColors.charcoal)),
              Text('Current Streak', style: GoogleFonts.inter(fontSize: 11, color: NHRColors.dusty)),
            ]),
          ])),
          Container(width: 1, height: 40, color: NHRColors.fog),
          Expanded(child: Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${stats.totalSolved}', style: GoogleFonts.poppins(
                fontSize: 24, fontWeight: FontWeight.w800, color: NHRColors.charcoal)),
              Text('Total Solved', style: GoogleFonts.inter(fontSize: 11, color: NHRColors.dusty)),
            ]),
          )),
        ]),
      ]),
    );
  }

  Widget _buildActivitySection(LeetCodeStats stats) {
    final activity = stats.recentActivity(90);
    final now = DateTime.now();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: NHRColors.milkDeep,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: NHRColors.fog),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('ACTIVITY', style: GoogleFonts.inter(
            fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2.5, color: NHRColors.dusty)),
          Text('Last 90 days', style: GoogleFonts.inter(fontSize: 10, color: NHRColors.dusty)),
        ]),
        const SizedBox(height: 16),
        // Heatmap grid — 13 weeks x 7 days
        SizedBox(
          height: 100,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(13, (weekIdx) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: List.generate(7, (dayIdx) {
                  final daysAgo = (12 - weekIdx) * 7 + (6 - dayIdx);
                  final date = DateTime(now.year, now.month, now.day).subtract(Duration(days: daysAgo));
                  final dayKey = DateTime(date.year, date.month, date.day);
                  final count = activity[dayKey] ?? 0;

                  Color cellColor;
                  if (count == 0) {
                    cellColor = NHRColors.fog;
                  } else if (count <= 2) {
                    cellColor = const Color(0xFF00B8A3).withValues(alpha: 0.3);
                  } else if (count <= 5) {
                    cellColor = const Color(0xFF00B8A3).withValues(alpha: 0.6);
                  } else {
                    cellColor = const Color(0xFF00B8A3);
                  }

                  return Container(
                    width: 11, height: 11,
                    margin: const EdgeInsets.all(1),
                    decoration: BoxDecoration(
                      color: cellColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  );
                }),
              );
            }),
          ),
        ),
        const SizedBox(height: 10),
        // Legend
        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          Text('Less', style: GoogleFonts.inter(fontSize: 9, color: NHRColors.dusty)),
          const SizedBox(width: 4),
          ...List.generate(4, (i) {
            final colors = [
              NHRColors.fog,
              const Color(0xFF00B8A3).withValues(alpha: 0.3),
              const Color(0xFF00B8A3).withValues(alpha: 0.6),
              const Color(0xFF00B8A3),
            ];
            return Container(
              width: 11, height: 11, margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(color: colors[i], borderRadius: BorderRadius.circular(2)),
            );
          }),
          const SizedBox(width: 4),
          Text('More', style: GoogleFonts.inter(fontSize: 9, color: NHRColors.dusty)),
        ]),
      ]),
    );
  }
}
