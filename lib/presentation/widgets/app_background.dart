import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:image_flow/core/theme/app_theme.dart';

class AppBackground extends StatelessWidget {
  const AppBackground({
    required this.child,
    this.animated = false,
    super.key,
  });

  final Widget child;
  final bool animated;

  @override
  Widget build(BuildContext context) {
    if (animated) {
      return _AnimatedBackground(child: child);
    }
    return _StaticBackground(child: child);
  }
}

class _StaticBackground extends StatelessWidget {
  const _StaticBackground({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(gradient: AppTheme.backgroundGradient),
          ),
        ),
        Positioned(
          top: -220,
          left: -140,
          child: _Glow(
            color: AppTheme.greatHornedOwl.withValues(alpha: 0.18),
            size: 420,
          ),
        ),
        Positioned(
          top: 120,
          right: -200,
          child: _Glow(
            color: AppTheme.tawnyOwl.withValues(alpha: 0.12),
            size: 520,
          ),
        ),
        Positioned(
          bottom: -260,
          left: -180,
          child: _Glow(
            color: AppTheme.burrowingOwl.withValues(alpha: 0.10),
            size: 560,
          ),
        ),
        Positioned.fill(child: child),
      ],
    );
  }
}

class _AnimatedBackground extends StatefulWidget {
  const _AnimatedBackground({required this.child});

  final Widget child;

  @override
  State<_AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<_AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
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
      builder: (context, _) {
        final t = _controller.value * 2 * math.pi;
        final glow1 = const Offset(-140, -220);
        final glow2 = const Offset(320, 120);
        final glow3 = const Offset(-180, 520);

        return Stack(
          children: [
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(gradient: AppTheme.backgroundGradient),
              ),
            ),
            _AnimatedGlow(
              center: glow1,
              size: 420,
              color: AppTheme.greatHornedOwl.withValues(alpha: 0.2),
              scale: 1 + math.sin(t * 0.6) * 0.05,
            ),
            _AnimatedGlow(
              center: glow2,
              size: 520,
              color: AppTheme.tawnyOwl.withValues(alpha: 0.16),
              scale: 1 + math.cos(t * 0.7) * 0.06,
            ),
            _AnimatedGlow(
              center: glow3,
              size: 560,
              color: AppTheme.burrowingOwl.withValues(alpha: 0.14),
              scale: 1 + math.sin(t * 0.55) * 0.05,
            ),
            Positioned.fill(child: widget.child),
          ],
        );
      },
    );
  }
}

class _AnimatedGlow extends StatelessWidget {
  const _AnimatedGlow({
    required this.center,
    required this.size,
    required this.color,
    required this.scale,
  });

  final Offset center;
  final double size;
  final Color color;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: center.dx - size / 2,
      top: center.dy - size / 2,
      child: RepaintBoundary(
        child: Transform.scale(
          scale: scale,
          child: _Glow(color: color, size: size),
        ),
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, Colors.transparent],
            stops: const [0.0, 1.0],
          ),
        ),
      ),
    );
  }
}
