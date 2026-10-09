import 'game_config.dart';
import 'level_generator.dart';
import 'levels.dart';

enum GamePhase { idle, resolving, won, lost }

/// Immutable snapshot handed to the result screen.
class GameResult {
  const GameResult({
    required this.levelId,
    required this.cols,
    required this.won,
    required this.accuracy,
    required this.movesUsed,
    required this.movesAllowed,
    required this.minMoves,
    required this.stars,
    required this.board,
    required this.target,
  });

  final int levelId;
  final int cols;
  final bool won;

  /// 0..100, already rounded.
  final int accuracy;
  final int movesUsed;
  final int movesAllowed;
  final int minMoves;
  final int stars;
  final List<List<int>> board;
  final List<List<int>> target;
}

/// Live state of one level. Pure logic — no widgets, no timers.
class MosaicEngine {
  MosaicEngine(this.level) : _generated = generateLevel(level) {
    _restore();
  }

  final LevelDef level;
  final GeneratedLevel _generated;

  late List<List<int>> board;
  late List<int> residual;
  late int movesLeft;
  late int hintsLeft;
  int movesUsed = 0;

  int get cols => _generated.cols;
  List<List<int>> get target => _generated.target;
  int get minMoves => _generated.minMoves;
  int get movesAllowed => _generated.minMoves + level.slack;

  void _restore() {
    board = cloneMatrix(_generated.start);
    residual = List<int>.from(_generated.residual);
    movesLeft = movesAllowed;
    hintsLeft = level.hints;
    movesUsed = 0;
  }

  /// Restores the level's start state and the full move budget.
  void reset() => _restore();

  bool matchedAt(int r, int c) => board[r][c] == target[r][c];

  int get matchedCells {
    int count = 0;
    for (int r = 0; r < cols; r++) {
      for (int c = 0; c < cols; c++) {
        if (board[r][c] == target[r][c]) {
          count++;
        }
      }
    }
    return count;
  }

  int get totalCells => cols * cols;

  bool get solved => matchedCells == totalCells;

  /// 0.0 .. 1.0
  double get accuracy => matchedCells / totalCells;

  int get accuracyPercent => (accuracy * 100).round();

  /// Flat indices of the three cells a tap at `(r, c)` affects.
  List<int> affectedBy(int r, int c) => <int>[
    r * cols + c,
    r * cols + (c + 1) % cols,
    ((r + 1) % cols) * cols + c,
  ];

  /// Next node the stored solution still wants tapped, or null when the
  /// residual vector is already clear.
  int? get hintIndex {
    for (int i = 0; i < residual.length; i++) {
      if (residual[i] != 0) {
        return i;
      }
    }
    return null;
  }

  bool get canTap => movesLeft > 0;

  bool get canHint =>
      hintsLeft > 0 && movesLeft > 1 && hintIndex != null;

  /// Applies one player tap. Returns the flat indices that changed.
  List<int> tap(int r, int c) {
    cycleTriple(board, cols, r, c, 1);
    final int flat = r * cols + c;
    residual[flat] =
        (residual[flat] + GameConfig.colorCount - 1) % GameConfig.colorCount;
    movesLeft--;
    movesUsed++;
    return affectedBy(r, c);
  }

  /// Spends a hint (and one move) and returns the node to highlight.
  int? useHint() {
    final int? index = hintIndex;
    if (index == null || hintsLeft <= 0 || movesLeft <= 1) {
      return null;
    }
    hintsLeft--;
    movesLeft--;
    movesUsed++;
    return index;
  }

  int get stars {
    if (!solved) {
      return 0;
    }
    if (movesUsed <= minMoves) {
      return 3;
    }
    if (movesUsed <= minMoves + (level.slack / 2).floor()) {
      return 2;
    }
    return 1;
  }

  GameResult buildResult({required bool won}) => GameResult(
    levelId: level.id,
    cols: cols,
    won: won,
    accuracy: accuracyPercent,
    movesUsed: movesUsed,
    movesAllowed: movesAllowed,
    minMoves: minMoves,
    stars: won ? stars : 0,
    board: cloneMatrix(board),
    target: cloneMatrix(target),
  );
}
