import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../providers/stats_provider.dart';
import '../services/database_service.dart';

class HeroModeScreen extends StatefulWidget {
  const HeroModeScreen({super.key});
  @override
  State<HeroModeScreen> createState() => _HeroModeScreenState();
}

class _HeroModeScreenState extends State<HeroModeScreen> with TickerProviderStateMixin {
  int _totalSeconds = 25 * 60;
  int _remaining = 25 * 60;
  bool _running = false;
  bool _finished = false;
  Timer? _timer;
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))..repeat(reverse: true);
  }

  @override
  void dispose() { _timer?.cancel(); _pulseCtrl.dispose(); super.dispose(); }

  void _start() {
    setState(() { _running = true; _finished = false; });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remaining <= 0) { _timer?.cancel(); setState(() { _running = false; _finished = true; }); _onComplete(); return; }
      setState(() => _remaining--);
    });
  }

  void _pause() { _timer?.cancel(); setState(() => _running = false); }
  void _reset() { _timer?.cancel(); setState(() { _remaining = _totalSeconds; _running = false; _finished = false; }); }

  Future<void> _onComplete() async {
    final stats = context.read<StatsProvider>();
    const xp = 75;
    final leveledUp = await stats.addXP(xp);
    await DatabaseService.recordDailyStats(tasksCompleted: 0, lectureMinutes: _totalSeconds ~/ 60, xpEarned: xp);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Focus complete! +$xp XP${leveledUp ? " — Level Up!" : ""}',
          style: GoogleFonts.inter(color: NHRColors.milk, fontWeight: FontWeight.w600)),
        backgroundColor: NHRColors.charcoal,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

  String get _timeStr {
    final m = _remaining ~/ 60; final s = _remaining % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  double get _progress => 1.0 - (_remaining / _totalSeconds);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NHRColors.milk,
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Label
          Text('FOCUS', style: GoogleFonts.inter(
            fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 4,
            color: _running ? NHRColors.terracotta : NHRColors.dusty,
          )).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 6),
          Text(_running ? 'Stay present.' : (_finished ? 'Well done.' : 'Choose a duration below'),
            style: GoogleFonts.inter(fontSize: 13, color: NHRColors.dusty)),
          const SizedBox(height: 48),

          // Timer circle — clean, minimal
          SizedBox(
            width: 240, height: 240,
            child: Stack(alignment: Alignment.center, children: [
              SizedBox(width: 240, height: 240,
                child: CircularProgressIndicator(
                  value: _progress.clamp(0.0, 1.0),
                  strokeWidth: 3,
                  backgroundColor: NHRColors.fog,
                  valueColor: AlwaysStoppedAnimation(
                    _finished ? NHRColors.sage : (_running ? NHRColors.terracotta : NHRColors.dusty)),
                ),
              ),
              Column(mainAxisSize: MainAxisSize.min, children: [
                Text(_timeStr, style: GoogleFonts.poppins(
                  fontSize: 56, fontWeight: FontWeight.w700,
                  color: NHRColors.charcoal, letterSpacing: -2,
                )),
                if (_finished)
                  Text('COMPLETE', style: GoogleFonts.inter(
                    fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2, color: NHRColors.sage)),
              ]),
            ]),
          ).animate().scale(delay: 200.ms, duration: 500.ms, curve: Curves.easeOut),
          const SizedBox(height: 40),

          // Duration selector
          if (!_running && !_finished) ...[
            Row(mainAxisAlignment: MainAxisAlignment.center,
              children: [15, 25, 45, 60].map((m) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: GestureDetector(
                  onTap: () => setState(() { _totalSeconds = m * 60; _remaining = m * 60; }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: _totalSeconds == m * 60 ? NHRColors.charcoal : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _totalSeconds == m * 60 ? NHRColors.charcoal : NHRColors.fog),
                    ),
                    child: Text('${m}m', style: GoogleFonts.inter(
                      fontSize: 13, fontWeight: FontWeight.w600,
                      color: _totalSeconds == m * 60 ? NHRColors.milk : NHRColors.dusty)),
                  ),
                ),
              )).toList()),
            const SizedBox(height: 36),
          ],

          // Controls
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            if (_running || _remaining < _totalSeconds)
              IconButton(onPressed: _reset,
                icon: Icon(Icons.refresh_rounded, color: NHRColors.dusty, size: 28)),
            const SizedBox(width: 16),
            GestureDetector(
              onTap: _running ? _pause : (_finished ? _reset : _start),
              child: Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _finished ? NHRColors.sage : NHRColors.charcoal,
                ),
                child: Icon(
                  _running ? Icons.pause_rounded : (_finished ? Icons.check_rounded : Icons.play_arrow_rounded),
                  color: NHRColors.milk, size: 32,
                ),
              ),
            ),
          ]).animate().fadeIn(delay: 500.ms),
          const SizedBox(height: 24),
          Text('+75 XP on completion', style: GoogleFonts.inter(
            fontSize: 11, color: NHRColors.dusty)),
        ]),
      ),
    );
  }
}
