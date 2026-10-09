import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';

class _RingPainter extends CustomPainter {
  const _RingPainter({required this.value});

  final double value;

  @override
  void paint(Canvas canvas, Size size) {
    const double stroke = 5;
    final Rect rect = Rect.fromLTWH(
      stroke / 2,
      stroke / 2,
      size.width - stroke,
      size.height - stroke,
    );

    canvas.drawArc(
      rect,
      0,
      math.pi * 2,
      false,
      Paint()
        ..color = PMColors.text(0.10)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );

    if (value <= 0) {
      return;
    }

    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * value.clamp(0.0, 1.0),
      false,
      Paint()
        ..shader = const LinearGradient(
          colors: <Color>[PMColors.cyan, PMColors.gold],
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = stroke,
    );
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) => oldDelegate.value != value;
}

/// Accuracy arc with the percentage in the centre. The value animates once
/// per move and settles — no perpetual ticker.
class AccuracyRing extends StatelessWidget {
  const AccuracyRing({super.key, required this.value, this.size = 56});

  /// 0.0 .. 1.0
  final double value;
  final double size;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value.clamp(0.0, 1.0)),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      builder: (BuildContext context, double animated, Widget? child) {
        return SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _RingPainter(value: animated),
            child: Center(
              child: Text(
                '${(animated * 100).round()}%',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  height: 18 / 16,
                  color: PMColors.textPrimary,
                  fontFeatures: kTabularFigures,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
