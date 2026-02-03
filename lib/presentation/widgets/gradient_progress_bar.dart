import 'package:flutter/material.dart';
import 'package:image_flow/core/theme/app_theme.dart';

class GradientProgressBar extends StatelessWidget {
  const GradientProgressBar({required this.value, super.key});

  final double value;

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: 8,
        width: double.infinity,
        child: ColoredBox(
          color: AppTheme.bgSecondary,
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: clamped,
              heightFactor: 1,
              child: const SizedBox.expand(
                child: DecoratedBox(
                  decoration: BoxDecoration(gradient: AppTheme.accentGradient),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
