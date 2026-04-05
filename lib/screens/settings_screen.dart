import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../providers/stats_provider.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final stats = context.watch<StatsProvider>();
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Profile
        Row(children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: NHRColors.milkDeep,
              border: Border.all(color: NHRColors.fog, width: 2),
            ),
            child: Center(child: Text('${stats.stats.currentLevel}',
              style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: NHRColors.charcoal))),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(
                children: [
                  Expanded(
                    child: Text(stats.stats.username, 
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: NHRColors.charcoal)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_rounded, size: 18, color: NHRColors.dusty),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      String newName = stats.stats.username;
                      showDialog(context: context, builder: (ctx) => AlertDialog(
                        backgroundColor: NHRColors.milk,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        title: Text('Set Username', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: NHRColors.charcoal)),
                        content: TextField(
                          autofocus: true,
                          decoration: const InputDecoration(hintText: 'Enter username'),
                          onChanged: (v) => newName = v,
                        ),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: NHRColors.dusty))),
                          TextButton(onPressed: () {
                            if (newName.trim().isNotEmpty) {
                              final newStats = stats.stats;
                              newStats.username = newName.trim();
                              stats.updateStats(newStats);
                            }
                            Navigator.pop(ctx);
                          }, child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold, color: NHRColors.terracotta))),
                        ],
                      ));
                    },
                  ),
                ],
              ),
              Text('${stats.stats.heroTitle} • ${stats.stats.totalXP} XP total', style: GoogleFonts.inter(fontSize: 13, color: NHRColors.dusty)),
            ]),
          ),
        ]).animate().fadeIn(duration: 400.ms),
        const Divider(height: 40),

        // Account Section
        _buildAccountSection(context),
        const Divider(height: 40),

        // Achievements
        Text('ACHIEVEMENTS', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2.5, color: NHRColors.dusty)),
        const SizedBox(height: 16),
        _achievement(context, 'First Task', 'Complete your first task', stats.stats.totalTasksCompleted >= 1, Icons.check_circle_outline, NHRColors.sage),
        _achievement(context, 'Task Master', 'Complete 10 tasks', stats.stats.totalTasksCompleted >= 10, Icons.verified_outlined, NHRColors.terracotta),
        _achievement(context, 'Streak Starter', '3-day streak', stats.stats.streakDays >= 3, Icons.local_fire_department_outlined, NHRColors.terracotta),
        _achievement(context, 'Scholar', 'Complete 5 lectures', stats.stats.totalLecturesCompleted >= 5, Icons.school_outlined, NHRColors.slate),
        _achievement(context, 'Level 5', 'Reach Level 5', stats.stats.currentLevel >= 5, Icons.star_outline_rounded, NHRColors.sand),
        _achievement(context, 'Legend', 'Reach Level 20', stats.stats.currentLevel >= 20, Icons.diamond_outlined, NHRColors.terracotta),
        const Divider(height: 40),

        // App info
        Text('APP', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2.5, color: NHRColors.dusty)),
        const SizedBox(height: 16),
        _infoRow(context, 'App', 'NHR'),
        _infoRow(context, 'Version', '1.0.0'),
        _infoRow(context, 'Data', context.watch<AuthProvider>().isSignedIn ? 'Synced to cloud' : 'Stored locally'),
        const SizedBox(height: 60),

        // Footer
        Center(
          child: SizedBox(
            height: 120,
            width: double.infinity,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Bottom layer (Z-index 0): marquee
                Positioned.fill(
                  child: Center(
                    child: Opacity(
                      opacity: 0.3,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const NeverScrollableScrollPhysics(),
                        child: Row(
                          children: List.generate(10, (index) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Text(
                              'MADE BY NIHAR',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 4,
                                color: NHRColors.charcoal,
                              ),
                            ),
                          )),
                        ).animate(onPlay: (controller) => controller.repeat())
                         .moveX(begin: 0, end: -300, duration: 6000.ms, curve: Curves.linear),
                      ),
                    ),
                  ),
                ),
                // Top layer (Z-index 1): NHR (bold, elevated opacity)
                Positioned.fill(
                  child: Center(
                    child: Text(
                      'NHR',
                      style: GoogleFonts.poppins(
                        fontSize: 56,
                        height: 1.0,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -2,
                        color: NHRColors.charcoal.withValues(alpha: 0.15),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 40),
      ]),
    );
  }

  Widget _achievement(BuildContext context, String title, String subtitle, bool unlocked, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: unlocked ? color.withValues(alpha: 0.12) : NHRColors.fog.withValues(alpha: 0.5),
          ),
          child: Icon(icon, size: 18, color: unlocked ? color : NHRColors.textMuted),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600,
            color: unlocked ? NHRColors.charcoal : NHRColors.dusty)),
          Text(subtitle, style: GoogleFonts.inter(fontSize: 11, color: NHRColors.dusty)),
        ])),
        if (unlocked)
          Icon(Icons.check_rounded, size: 18, color: color),
      ]),
    );
  }

  Widget _infoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: GoogleFonts.inter(fontSize: 13, color: NHRColors.dusty)),
        Text(value, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: NHRColors.charcoal)),
      ]),
    );
  }

  Widget _buildAccountSection(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('ACCOUNT', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2.5, color: NHRColors.dusty)),
      const SizedBox(height: 16),
      if (auth.isSignedIn) ...[
        // Signed in state
        Row(children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: NHRColors.milkDeep,
            backgroundImage: auth.photoUrl != null ? NetworkImage(auth.photoUrl!) : null,
            child: auth.photoUrl == null
                ? Text(auth.displayName[0].toUpperCase(), style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: NHRColors.charcoal))
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(auth.displayName, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: NHRColors.charcoal)),
            if (auth.email != null)
              Text(auth.email!, style: GoogleFonts.inter(fontSize: 12, color: NHRColors.dusty)),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: NHRColors.sage.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.cloud_done_outlined, size: 14, color: NHRColors.sage),
              const SizedBox(width: 4),
              Text('Synced', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: NHRColors.sage)),
            ]),
          ),
        ]),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: auth.isLoading ? null : () => auth.syncNow().then((_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Sync complete', style: GoogleFonts.inter()),
                      backgroundColor: NHRColors.charcoal, duration: const Duration(seconds: 2)),
                  );
                  // Reload data after sync
                  context.read<StatsProvider>().refreshStats();
                }
              }),
              icon: auth.isLoading
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.sync_rounded, size: 16),
              label: Text(auth.isLoading ? 'Syncing...' : 'Sync Now', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                foregroundColor: NHRColors.charcoal,
                side: const BorderSide(color: NHRColors.fog),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: auth.isLoading ? null : () async {
                await auth.signOut();
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('login_skipped', false);
              },
              icon: const Icon(Icons.logout_rounded, size: 16),
              label: Text('Sign Out', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                foregroundColor: NHRColors.dusty,
                side: const BorderSide(color: NHRColors.fog),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ]),
      ] else ...[
        // Not signed in
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: NHRColors.milkDeep,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: NHRColors.fog),
          ),
          child: Column(children: [
            const Icon(Icons.cloud_off_outlined, size: 28, color: NHRColors.dusty),
            const SizedBox(height: 8),
            Text('Not signed in', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: NHRColors.charcoal)),
            const SizedBox(height: 4),
            Text('Sign in to sync your data across devices', style: GoogleFonts.inter(fontSize: 12, color: NHRColors.dusty), textAlign: TextAlign.center),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: auth.isLoading ? null : () async {
                  final success = await auth.signInWithGoogle();
                  if (success && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Signed in! Syncing...', style: GoogleFonts.inter()),
                        backgroundColor: NHRColors.charcoal, duration: const Duration(seconds: 2)),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: NHRColors.charcoal,
                  foregroundColor: NHRColors.milk,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: auth.isLoading
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: NHRColors.milk))
                    : Text('Sign in with Google', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            ),
          ]),
        ),
      ],
    ]);
  }
}
