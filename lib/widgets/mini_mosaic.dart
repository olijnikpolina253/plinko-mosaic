import 'package:flutter/material.dart';

import '../theme.dart';
import 'mosaic_node.dart';

/// Read-only miniature of a matrix — used by the reference strip, the gallery
/// thumbnails and the result card. Same sprites as the live board.
class MiniMosaic extends StatelessWidget {
  const MiniMosaic({
    super.key,
    required this.matrix,
    this.cell = 16,
    this.gap = 3,
  });

  final List<List<int>> matrix;
  final double cell;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final List<Widget> rows = <Widget>[];
    for (int r = 0; r < matrix.length; r++) {
      if (r > 0) {
        rows.add(SizedBox(height: gap));
      }
      final List<Widget> cells = <Widget>[];
      for (int c = 0; c < matrix[r].length; c++) {
        if (c > 0) {
          cells.add(SizedBox(width: gap));
        }
        final int value = matrix[r][c];
        final Color accent = nodeColorFor(value);
        cells.add(
          Container(
            width: cell,
            height: cell,
            decoration: BoxDecoration(
              color: PMColors.bgBase.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(cell * 0.28),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: accent.withValues(alpha: 0.35),
                  blurRadius: cell * 0.35,
                ),
              ],
            ),
            padding: EdgeInsets.all(cell * 0.14),
            child: Image.asset(
              nodeSpriteFor(value),
              fit: BoxFit.contain,
              errorBuilder:
                  (BuildContext context, Object error, StackTrace? stack) =>
                      DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: accent.withValues(alpha: 0.9),
                        ),
                      ),
            ),
          ),
        );
      }
      rows.add(Row(mainAxisSize: MainAxisSize.min, children: cells));
    }

    return Column(mainAxisSize: MainAxisSize.min, children: rows);
  }
}
