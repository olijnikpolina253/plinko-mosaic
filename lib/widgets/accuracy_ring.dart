import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';

/// Arc gauge, 0..1. The centre label carries the same number as the arc so the
/// value stays readable at thumbnail sizes.
class AccuracyRing extends StatelessWidget {
  const AccuracyRing({
    super.key,
    required this.value,
    this.size = 46,
    this.stroke = 5,
  });

  final double value;
  final double size;
  final double stroke;

  @override
  Widget build(BuildContext context) {
    final int percent = (value.clamp(0.0, 1.0) * 100).round();
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(value: value.clamp(0.0, 1.0), stroke: stroke),
        child: Center(
          child: Text(
            '$percent%',
            style: TextStyle(
              fontSize: size * 0.28,
              height: 1.1,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
              fontFeatures: AppTheme.tabular,
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({required this.value, required this.stroke});

  final double value;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset(stroke / 2, stroke / 2) &
        Size(size.width - stroke, size.height - stroke);

    final Paint track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = AppColors.textPrimary.withValues(alpha: 0.10);
    canvas.drawArc(rect, 0, math.pi * 2, false, track);

    if (value <= 0) return;

    final Paint progress = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..shader = const LinearGradient(
        colors: <Color>[AppColors.cyan, AppColors.gold],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(rect);
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * value, false, progress);
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.value != value || oldDelegate.stroke != stroke;
}
