import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../theme.dart';

/// Standard translucent surface: blurred backdrop, dark glass fill, hairline
/// border. Used for the menu sheet, the board plate and every card.
class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.radius = 24,
    this.padding = const EdgeInsets.all(16),
    this.fillAlpha = 0.62,
    this.borderAlpha = 0.10,
    this.blur = 14,
    this.borderRadius,
  });

  final Widget child;
  final double radius;
  final EdgeInsets padding;
  final double fillAlpha;
  final double borderAlpha;
  final double blur;

  /// Overrides [radius] when a non-uniform shape is needed (the menu sheet).
  final BorderRadiusGeometry? borderRadius;

  @override
  Widget build(BuildContext context) {
    final BorderRadiusGeometry shape =
        borderRadius ?? BorderRadius.circular(radius);
    return ClipRRect(
      borderRadius: shape,
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: PMColors.surface.withValues(alpha: fillAlpha),
            borderRadius: shape,
            border: Border.all(
              color: PMColors.text(borderAlpha),
              width: 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
