import 'board_state.dart';

/// Immutable outcome of one round, handed from GameScreen to ResultScreen.
class RoundResult {
  const RoundResult({
    required this.level,
    required this.win,
    required this.accuracy,
    required this.matched,
    required this.cellCount,
    required this.movesUsed,
    required this.moveLimit,
    required this.parMoves,
    required this.stars,
    required this.finalBoard,
    required this.target,
  });

  final int level;
  final bool win;

  /// Whole percent, 0..100.
  final int accuracy;
  final int matched;
  final int cellCount;

  final int movesUsed;
  final int moveLimit;
  final int parMoves;

  /// 0..3. A loss always scores 0.
  final int stars;

  final BoardState finalBoard;
  final BoardState target;

  static int starsFor({
    required bool win,
    required int movesUsed,
    required int parMoves,
  }) {
    if (!win) return 0;
    if (movesUsed <= parMoves) return 3;
    if (movesUsed <= parMoves + 2) return 2;
    return 1;
  }
}
