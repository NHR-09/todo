import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ImmersiveBackground extends StatefulWidget {
  final Widget child;
  const ImmersiveBackground({super.key, required this.child});

  @override
  State<ImmersiveBackground> createState() => _ImmersiveBackgroundState();
}

class _ImmersiveBackgroundState extends State<ImmersiveBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
       vsync: this, 
       duration: const Duration(seconds: 20)
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base dark plum color
        Container(color: MarvelColors.plum),
        
        // Animated subtle orbs
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final t = _controller.value * 2 * pi;
            return Stack(
              children: [
                _buildOrb(
                  color: MarvelColors.accentPeach.withValues(alpha: 0.15),
                  size: 300,
                  x: cos(t) * 50 - 50,
                  y: sin(t) * 100 - 100,
                ),
                _buildOrb(
                  color: MarvelColors.accentLavender.withValues(alpha: 0.15),
                  size: 400,
                  x: sin(t * 1.5) * 80 + MediaQuery.of(context).size.width - 200,
                  y: cos(t * 1.5) * 60 + MediaQuery.of(context).size.height - 300,
                ),
                _buildOrb(
                  color: MarvelColors.accentMint.withValues(alpha: 0.1),
                  size: 250,
                  x: cos(t * 0.8) * 100 + 100,
                  y: sin(t * 0.8) * 120 + 300,
                ),
              ],
            );
          },
        ),

        // Heavy glassmorphism blur across the entire background
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
            child: Container(color: Colors.transparent),
          ),
        ),

        // The foreground content (app screens)
        SafeArea(child: widget.child),
      ],
    );
  }

  Widget _buildOrb({required Color color, required double size, required double x, required double y}) {
    return Positioned(
      left: x,
      top: y,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
      ),
    );
  }
}
