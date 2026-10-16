import 'dart:typed_data';
import 'dart:ui' show PointMode;

import 'package:flutter/material.dart';

import '../theme.dart';

/// A single soft aurora blob, positioned in fractions of the canvas.
class AuroraBlob {
  const AuroraBlob({
    required this.dx,
    required this.dy,
    required this.radius,
    required this.color,
  });

  final double dx;
  final double dy;
  final double radius;
  final Color color;
}

/// Static blurred background blobs. Painted once — `shouldRepaint` is false so
/// the window goes idle and uiautomator can dump the tree.
class AuroraPainter extends CustomPainter {
  const AuroraPainter(this.blobs);

  final List<AuroraBlob> blobs;

  @override
  void paint(Canvas canvas, Size size) {
    for (final AuroraBlob blob in blobs) {
      final Paint paint = Paint()
        ..color = blob.color
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 60);
      canvas.drawCircle(
        Offset(size.width * blob.dx, size.height * blob.dy),
        blob.radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(AuroraPainter oldDelegate) => false;
}

/// Deterministic full-canvas light grain used on the splash only.
///
/// Four tinted `drawRawPoints` passes = four GPU calls, painted once. It gives
/// the loader frame enough entropy to stay clearly distinct from the menu.
class GrainPainter extends CustomPainter {
  const GrainPainter({this.pointsPerPass = 24000});

  final int pointsPerPass;

  static const List<Color> _tints = <Color>[
    AppColors.textPrimary,
    AppColors.cyan,
    AppColors.gold,
    AppColors.textMuted,
  ];

  static const List<double> _alphas = <double>[0.26, 0.18, 0.12, 0.22];
  static const List<double> _widths = <double>[1.5, 1.3, 1.2, 1.4];

  @override
  void paint(Canvas canvas, Size size) {
    int state = 0x1F2E3D4C;
    int next() {
      state ^= (state << 13) & 0xFFFFFFFF;
      state ^= state >> 17;
      state ^= (state << 5) & 0xFFFFFFFF;
      return state & 0xFFFFFFFF;
    }

    for (int pass = 0; pass < _tints.length; pass++) {
      final Float32List points = Float32List(pointsPerPass * 2);
      for (int i = 0; i < pointsPerPass; i++) {
        points[i * 2] = (next() % 100000) / 100000 * size.width;
        points[i * 2 + 1] = (next() % 100000) / 100000 * size.height;
      }
      final Paint paint = Paint()
        ..color = _tints[pass].withValues(alpha: _alphas[pass])
        ..strokeWidth = _widths[pass]
        ..strokeCap = StrokeCap.round;
      canvas.drawRawPoints(PointMode.points, points, paint);
    }
  }

  @override
  bool shouldRepaint(GrainPainter oldDelegate) =>
      oldDelegate.pointsPerPass != pointsPerPass;
}
