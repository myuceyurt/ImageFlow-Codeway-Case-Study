import 'package:flutter/material.dart';
import 'package:image_flow/core/theme/app_theme.dart';

class LoopingGradientProgressBar extends StatefulWidget {
  const LoopingGradientProgressBar({
    super.key,
    this.fillDuration = const Duration(milliseconds: 900),
    this.fullHoldDuration = const Duration(milliseconds: 140),
    this.blankDuration = const Duration(milliseconds: 220),
  });

  final Duration fillDuration;
  final Duration fullHoldDuration;
  final Duration blankDuration;

  @override
  State<LoopingGradientProgressBar> createState() =>
      _LoopingGradientProgressBarState();
}

class _LoopingGradientProgressBarState extends State<LoopingGradientProgressBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _value;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.fillDuration,
    );
    _value = CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic);
    _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant LoopingGradientProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fillDuration != widget.fillDuration) {
      _controller.duration = widget.fillDuration;
      if (_controller.isAnimating) {
        _controller
          ..stop()
          ..repeat(reverse: true);
      }
    }
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
        final value = _value.value;
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
                  widthFactor: value.clamp(0.0, 1.0),
                  heightFactor: 1,
                  child: const SizedBox.expand(
                    child: DecoratedBox(
                      decoration:
                          BoxDecoration(gradient: AppTheme.accentGradient),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
