import 'package:flutter/material.dart';

import '../theme.dart';

/// Shared stat pill — identical widget and styling on Menu and Result.
///
/// Deliberately raster-free: an accent dot carries the semantics so three
/// pills in a row can never render at visually different sizes the way three
/// AI sprites with different bounding boxes would.
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.value,
    required this.label,
    required this.valueColor,
  });

  final String value;
  final String label;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: PMColors.surface.withValues(alpha: 0.70),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: valueColor.withValues(alpha: 0.33),
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: valueColor,
              shape: BoxShape.circle,
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: valueColor.withValues(alpha: 0.6),
                  blurRadius: 10,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              height: 26 / 22,
              color: valueColor,
              fontFeatures: kTabularFigures,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              height: 13 / 10,
              color: PMColors.text(0.55),
            ),
          ),
        ],
      ),
    );
  }
}

/// Three stars; earned ones are gold, the rest sit at low opacity.
class StarRow extends StatelessWidget {
  const StarRow({super.key, required this.earned, this.size = 14});

  final int earned;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: List<Widget>.generate(3, (int i) {
        return Icon(
          Icons.star_rounded,
          size: size,
          color: i < earned ? PMColors.gold : PMColors.text(0.18),
        );
      }),
    );
  }
}
