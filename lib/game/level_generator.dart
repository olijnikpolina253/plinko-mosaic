import 'board_state.dart';
import 'game_config.dart';

/// Everything a round needs, derived deterministically from the level number.
class LevelSpec {
  const LevelSpec({
    required this.level,
    required this.cols,
    required this.rows,
    required this.colourCount,
    required this.parMoves,
    required this.moveLimit,
    required this.target,
    required this.start,
    required this.undoTaps,
  });

  final int level;
  final int cols;
  final int rows;
  final int colourCount;

  /// Cost of undoing the scramble — a guaranteed solution length.
  final int parMoves;
  final int moveLimit;

  final BoardState target;
  final BoardState start;

  /// How many extra taps each node needs to undo the scramble. Applying them
  /// all turns [start] back into [target] in exactly [parMoves] moves.
  final List<int> undoTaps;
}

/// Seeded, reproducible and always solvable: `start` is produced from `target`
/// by legal taps, so replaying the inverse taps is always a legal solution.
class LevelGenerator {
  const LevelGenerator._();

  static const int _mask = 0x7FFFFFFF;

  static LevelSpec build(int rawLevel) {
    final int level = GameConfig.clampLevel(rawLevel);
    final int cols = GameConfig.colsFor(level);
    final int rows = GameConfig.rowsFor(level);
    final int colourCount = GameConfig.coloursFor(level);
    final int scrambleTaps = GameConfig.scrambleTapsFor(level);
    final int slack = GameConfig.slackFor(level);
    final int cellCount = cols * rows;

    int seed = (0x9E3779B9 ^ (level * 2654435761)) & _mask;
    int nextInt() {
      seed = (seed * 1103515245 + 12345) & _mask;
      return seed;
    }

    final BoardState target = BoardState.filled(
      cols: cols,
      rows: rows,
      colourCount: colourCount,
    );
    for (int i = 0; i < cellCount; i++) {
      target.cells[i] = nextInt() % colourCount;
    }

    BoardState start = target.copy();
    List<int> counts = List<int>.filled(cellCount, 0, growable: true);

    // Degenerate scrambles (start == target) are re-rolled with the next seed.
    for (int attempt = 0; attempt < 8; attempt++) {
      start = target.copy();
      counts = List<int>.filled(cellCount, 0, growable: true);
      for (int t = 0; t < scrambleTaps; t++) {
        final int node = nextInt() % cellCount;
        counts[node]++;
        start.applyTapIndex(node);
      }
      if (!start.equalsTarget(target)) break;
    }

    final List<int> undoTaps = List<int>.filled(cellCount, 0, growable: true);
    int parMoves = 0;
    for (int i = 0; i < cellCount; i++) {
      undoTaps[i] = (colourCount - counts[i]) % colourCount;
      parMoves += undoTaps[i];
    }

    int moveLimit = parMoves + slack;
    if (moveLimit < 6) moveLimit = 6;

    return LevelSpec(
      level: level,
      cols: cols,
      rows: rows,
      colourCount: colourCount,
      parMoves: parMoves,
      moveLimit: moveLimit,
      target: target,
      start: start,
      undoTaps: undoTaps,
    );
  }
}
