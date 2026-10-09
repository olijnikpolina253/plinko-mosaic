/// One entry of the 12-level table.
class LevelDef {
  const LevelDef({
    required this.id,
    required this.seed,
    required this.cols,
    required this.targetM,
    required this.slack,
    required this.hints,
  });

  /// 1-based level number.
  final int id;

  /// Deterministic seed for the scramble stack.
  final int seed;

  /// Grid is always square: `cols` x `cols`.
  final int cols;

  /// Desired minimal solution length.
  final int targetM;

  /// Extra moves granted on top of the minimal solution.
  final int slack;

  /// Hint budget. A hint also costs one move.
  final int hints;
}

/// 12 levels: 3x3 warm-up, 4x4 middle, 5x5 finale.
const List<LevelDef> kLevels = <LevelDef>[
  LevelDef(id: 1, seed: 1061, cols: 3, targetM: 3, slack: 3, hints: 3),
  LevelDef(id: 2, seed: 2273, cols: 3, targetM: 3, slack: 3, hints: 3),
  LevelDef(id: 3, seed: 3391, cols: 3, targetM: 4, slack: 3, hints: 3),
  LevelDef(id: 4, seed: 4517, cols: 3, targetM: 4, slack: 3, hints: 3),
  LevelDef(id: 5, seed: 5639, cols: 4, targetM: 5, slack: 3, hints: 2),
  LevelDef(id: 6, seed: 6761, cols: 4, targetM: 5, slack: 3, hints: 2),
  LevelDef(id: 7, seed: 7883, cols: 4, targetM: 6, slack: 3, hints: 2),
  LevelDef(id: 8, seed: 8017, cols: 4, targetM: 6, slack: 3, hints: 2),
  LevelDef(id: 9, seed: 9133, cols: 4, targetM: 7, slack: 3, hints: 2),
  LevelDef(id: 10, seed: 10259, cols: 5, targetM: 8, slack: 4, hints: 2),
  LevelDef(id: 11, seed: 11383, cols: 5, targetM: 9, slack: 4, hints: 2),
  LevelDef(id: 12, seed: 12497, cols: 5, targetM: 10, slack: 4, hints: 2),
];

LevelDef levelById(int id) {
  for (final LevelDef level in kLevels) {
    if (level.id == id) {
      return level;
    }
  }
  return kLevels.first;
}

/// Next level id, or null when the table is exhausted.
int? nextLevelId(int id) => id < kLevels.length ? id + 1 : null;
