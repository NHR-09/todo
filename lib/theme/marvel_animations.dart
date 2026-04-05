import 'dart:math';
import 'package:flutter/material.dart';
import 'app_theme.dart';

/// Particle burst animation overlay for task completions
class ParticleBurstOverlay extends StatefulWidget {
  final Offset position;
  final VoidCallback onComplete;
  final Color color;

  const ParticleBurstOverlay({
    super.key,
    required this.position,
    required this.onComplete,
    this.color = MarvelColors.ironGold,
  });

  @override
  State<ParticleBurstOverlay> createState() => _ParticleBurstOverlayState();
}

class _ParticleBurstOverlayState extends State<ParticleBurstOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    final random = Random();
    _particles = List.generate(20, (_) {
      final angle = random.nextDouble() * 2 * pi;
      final speed = 100 + random.nextDouble() * 200;
      return _Particle(
        dx: cos(angle) * speed,
        dy: sin(angle) * speed,
        size: 3 + random.nextDouble() * 5,
        color: [
          MarvelColors.ironGold,
          MarvelColors.ironRed,
          Colors.orange,
          Colors.yellow,
        ][random.nextInt(4)],
      );
    });
    _controller.forward().then((_) => widget.onComplete());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          painter: _ParticlePainter(
            particles: _particles,
            progress: _controller.value,
            center: widget.position,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class _Particle {
  final double dx, dy, size;
  final Color color;
  _Particle(
      {required this.dx, required this.dy, required this.size, required this.color});
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;
  final Offset center;

  _ParticlePainter(
      {required this.particles, required this.progress, required this.center});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final paint = Paint()
        ..color = p.color.withValues(alpha: 1.0 - progress)
        ..style = PaintingStyle.fill;
      final offset = Offset(
        center.dx + p.dx * progress,
        center.dy + p.dy * progress - 50 * progress * progress,
      );
      canvas.drawCircle(offset, p.size * (1.0 - progress * 0.5), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) => true;
}

/// Animated XP popup that floats up and fades
class XPPopup extends StatefulWidget {
  final int xpAmount;
  final Offset position;
  final VoidCallback onComplete;

  const XPPopup({
    super.key,
    required this.xpAmount,
    required this.position,
    required this.onComplete,
  });

  @override
  State<XPPopup> createState() => _XPPopupState();
}

class _XPPopupState extends State<XPPopup> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _controller.forward().then((_) => widget.onComplete());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned(
          left: widget.position.dx - 30,
          top: widget.position.dy - 80 * _controller.value,
          child: Opacity(
            opacity: (1.0 - _controller.value).clamp(0.0, 1.0),
            child: Text(
              '+${widget.xpAmount} XP',
              style: TextStyle(
                fontSize: 20 + 8 * _controller.value,
                fontWeight: FontWeight.w900,
                color: MarvelColors.milk,
                // Removed shadows for minimalistic design
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Glowing pulsing border for Hero Mode
class GlowingBorder extends StatefulWidget {
  final Widget child;
  final Color color;
  final double borderRadius;

  const GlowingBorder({
    super.key,
    required this.child,
    this.color = MarvelColors.ironRed,
    this.borderRadius = 16,
  });

  @override
  State<GlowingBorder> createState() => _GlowingBorderState();
}

class _GlowingBorderState extends State<GlowingBorder>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            boxShadow: [
              BoxShadow(
                color: widget.color
                    .withValues(alpha: 0.3 + 0.4 * _controller.value),
                blurRadius: 16 + 12 * _controller.value,
                spreadRadius: 2 + 4 * _controller.value,
              ),
            ],
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Shimmer loading effect
class ShimmerEffect extends StatefulWidget {
  final Widget child;
  const ShimmerEffect({super.key, required this.child});

  @override
  State<ShimmerEffect> createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<ShimmerEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: const [
                Colors.transparent,
                Colors.white24,
                Colors.transparent,
              ],
              stops: [
                _controller.value - 0.3,
                _controller.value,
                _controller.value + 0.3,
              ].map((s) => s.clamp(0.0, 1.0)).toList(),
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcATop,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Marvel-style page transition
class MarvelPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  MarvelPageRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved =
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
            return FadeTransition(
              opacity: curved,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.05, 0),
                  end: Offset.zero,
                ).animate(curved),
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 400),
        );
}

/// Level-up full screen animation
class LevelUpAnimation extends StatefulWidget {
  final int newLevel;
  final String title;
  final VoidCallback onComplete;

  const LevelUpAnimation({
    super.key,
    required this.newLevel,
    required this.title,
    required this.onComplete,
  });

  @override
  State<LevelUpAnimation> createState() => _LevelUpAnimationState();
}

class _LevelUpAnimationState extends State<LevelUpAnimation>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _scaleController.forward().then((_) {
      Future.delayed(const Duration(seconds: 2), () {
        _fadeController.forward().then((_) => widget.onComplete());
      });
    });
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_scaleController, _fadeController]),
      builder: (context, _) {
        return Opacity(
          opacity: 1.0 - _fadeController.value,
          child: Container(
            color: Colors.black.withValues(alpha: 0.85),
            child: Center(
              child: Transform.scale(
                scale: Curves.elasticOut.transform(_scaleController.value),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) =>
                          MarvelColors.goldGradient.createShader(bounds),
                      child: const Icon(Icons.stars_rounded,
                          size: 80, color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    ShaderMask(
                      shaderCallback: (bounds) =>
                          MarvelColors.goldGradient.createShader(bounds),
                      child: Text(
                        'LEVEL ${widget.newLevel}',
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: 20,
                        color: MarvelColors.ironGold.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Streak fire animation widget
class StreakFireWidget extends StatefulWidget {
  final int streakCount;
  const StreakFireWidget({super.key, required this.streakCount});

  @override
  State<StreakFireWidget> createState() => _StreakFireWidgetState();
}

class _StreakFireWidgetState extends State<StreakFireWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Transform.scale(
              scale: 1.0 + 0.15 * _controller.value,
              child: Icon(
                Icons.local_fire_department_rounded,
                size: 28,
                color: MarvelColors.milk.withValues(alpha: 0.8 + 0.2 * _controller.value),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${widget.streakCount} day streak',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: MarvelColors.milk,
              ),
            ),
          ],
        );
      },
    );
  }
}
