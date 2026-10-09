import 'dart:math';

import 'game_config.dart';
import 'levels.dart';

/// A level materialised from its seed: target pattern, scrambled start state
/// and the exact tap list that restores the target.
class GeneratedLevel {
  const GeneratedLevel({
    required this.cols,
    required this.target,
    required this.start,
    required this.residual,
    required this.minMoves,
  });

  final int cols;

  /// Pattern the player must reproduce.
  final List<List<int>> target;

  /// Board the player starts from.
  final List<List<int>> start;

  /// Per-node count of single taps still required, flat index `r * cols + c`.
  /// Doubles as the hint source — no brute-force solver is needed.
  final List<int> residual;

  /// Length of the stored solution.
  final int minMoves;
}

/// Applies one tap at `(r, c)`: the node plus its right and lower neighbours
/// advance by `delta` (mod 3). The modulo wrap makes every node uniform, so
/// edge cells need no special case.
void cycleTriple(List<List<int>> matrix, int cols, int r, int c, int delta) {
  final int d = delta % GameConfig.colorCount;
  matrix[r][c] = (matrix[r][c] + d) % GameConfig.colorCount;
  final int rc = (c + 1) % cols;
  matrix[r][rc] = (matrix[r][rc] + d) % GameConfig.colorCount;
  final int dr = (r + 1) % cols;
  matrix[dr][c] = (matrix[dr][c] + d) % GameConfig.colorCount;
}

List<List<int>> cloneMatrix(List<List<int>> source) =>
    source.map((List<int> row) => List<int>.from(row)).toList();

/// Invertible scramble stack.
///
/// The target is random; the start state is produced by applying the tap
/// operation TWICE at `targetM` randomly chosen nodes. Taps commute under
/// mod-3 addition, so if a node was double-applied `d` times its net delta is
/// `2d`, and the single taps that undo it are `t` with `2d + t == 0 (mod 3)`,
/// i.e. `t == d (mod 3)`. Solvability is therefore proven by construction and
/// the resulting tap vector is the hint source.
GeneratedLevel generateLevel(LevelDef level) {
  final int cols = level.cols;
  final int nodeCount = cols * cols;

  GeneratedLevel? best;
  int bestDistance = 1 << 20;

  for (int attempt = 0; attempt < 20; attempt++) {
    final Random rng = Random(level.seed + attempt * 977);

    final List<List<int>> target = List<List<int>>.generate(
      cols,
      (_) => List<int>.generate(
        cols,
        (_) => rng.nextInt(GameConfig.colorCount),
      ),
    );

    final List<int> picks = List<int>.generate(
      level.targetM,
      (_) => rng.nextInt(nodeCount),
    );

    final List<int> doubles = List<int>.filled(nodeCount, 0);
    final List<List<int>> start = cloneMatrix(target);
    for (final int index in picks) {
      doubles[index] = (doubles[index] + 1) % GameConfig.colorCount;
      cycleTriple(start, cols, index ~/ cols, index % cols, 2);
    }

    final List<int> residual = doubles
        .map((int d) => d % GameConfig.colorCount)
        .toList();
    final int minMoves = residual.fold<int>(0, (int a, int b) => a + b);

    if (minMoves == 0) {
      continue;
    }

    final GeneratedLevel candidate = GeneratedLevel(
      cols: cols,
      target: target,
      start: start,
      residual: residual,
      minMoves: minMoves,
    );

    if (minMoves == level.targetM) {
      return candidate;
    }

    final int distance = (minMoves - level.targetM).abs();
    if (distance < bestDistance) {
      bestDistance = distance;
      best = candidate;
    }
  }

  return best ?? _fallbackLevel(level);
}

/// Degenerate safety net: a single-tap scramble always solvable in one move.
GeneratedLevel _fallbackLevel(LevelDef level) {
  final int cols = level.cols;
  final List<List<int>> target = List<List<int>>.generate(
    cols,
    (_) => List<int>.filled(cols, 0),
  );
  final List<List<int>> start = cloneMatrix(target);
  cycleTriple(start, cols, 0, 0, 2);
  final List<int> residual = List<int>.filled(cols * cols, 0);
  residual[0] = 1;
  return GeneratedLevel(
    cols: cols,
    target: target,
    start: start,
    residual: residual,
    minMoves: 1,
  );
}
