import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../game/game_config.dart';
import '../theme.dart';
import 'mosaic_node.dart';

/// Geometry of the board, derived with the frame formula so the tiles can
/// never overflow their parent: the container's width does NOT include the
/// padding and border the children live inside.
class BoardMetrics {
  const BoardMetrics({required this.tile, required this.boardSize});

  final double tile;
  final double boardSize;

  factory BoardMetrics.forExtent(double maxExtent, int cols) {
    final double usable = math.min(
      maxExtent - GameConfig.boardSideMargin,
      GameConfig.boardMaxWidth,
    );
    final double inner =
        usable - 2 * GameConfig.boardFrame - (cols - 1) * GameConfig.tileGap;
    final double tile = math.max(28.0, (inner / cols).floorToDouble());
    final double boardSize =
        tile * cols +
        (cols - 1) * GameConfig.tileGap +
        2 * GameConfig.boardFrame;
    return BoardMetrics(tile: tile, boardSize: boardSize);
  }
}

/// The playable mosaic field. Plain Column/Row nesting — never a GridView with
/// unbounded height.
class MosaicBoard extends StatelessWidget {
  const MosaicBoard({
    super.key,
    required this.state,
    required this.target,
    required this.cols,
    required this.metrics,
    required this.rippleTokens,
    required this.highlightIndex,
    required this.bloom,
    required this.lossFade,
    required this.onTapNode,
  });

  final List<List<int>> state;
  final List<List<int>> target;
  final int cols;
  final BoardMetrics metrics;

  /// Per-cell ripple counters, flat `r * cols + c`.
  final List<int> rippleTokens;

  /// Flat index highlighted by HINT, or null.
  final int? highlightIndex;

  /// 0..1 win bloom.
  final double bloom;

  /// 0..1 loss fade.
  final double lossFade;

  final void Function(int r, int c)? onTapNode;

  double _cellBloom(int index) {
    if (bloom <= 0) {
      return 0;
    }
    final double start = math.min(
      0.7,
      index * 24 / GameConfig.winBloomMs.toDouble(),
    );
    final double t = ((bloom - start) / (1 - start)).clamp(0.0, 1.0);
    return t <= 0.5 ? t * 2 : (1 - t) * 2;
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> rows = <Widget>[];
    for (int r = 0; r < cols; r++) {
      if (r > 0) {
        rows.add(const SizedBox(height: GameConfig.tileGap));
      }
      final List<Widget> cells = <Widget>[];
      for (int c = 0; c < cols; c++) {
        if (c > 0) {
          cells.add(const SizedBox(width: GameConfig.tileGap));
        }
        final int flat = r * cols + c;
        final bool matched = state[r][c] == target[r][c];
        cells.add(
          MosaicNode(
            colorIndex: state[r][c],
            size: metrics.tile,
            matched: matched,
            flipped: (r + c).isOdd,
            rippleToken: rippleTokens[flat],
            highlighted: highlightIndex == flat,
            glowBoost: _cellBloom(flat),
            dim: matched ? 0 : lossFade,
            onTap: onTapNode == null ? null : () => onTapNode!(r, c),
          ),
        );
      }
      rows.add(
        Row(mainAxisAlignment: MainAxisAlignment.center, children: cells),
      );
    }

    return Container(
      width: metrics.boardSize,
      height: metrics.boardSize,
      padding: const EdgeInsets.all(GameConfig.boardPad),
      decoration: BoxDecoration(
        color: PMColors.surface.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: PMColors.text(0.10),
          width: GameConfig.boardBorder,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: rows,
      ),
    );
  }
}
