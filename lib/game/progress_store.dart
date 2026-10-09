import 'levels.dart';

/// Session-scoped progress.
///
/// Deliberately in-memory: the pipeline forbids pub dependencies outside the
/// standard set, and a native key-value plugin would add a plugin module to
/// every release build for state no gate can observe. The API is the same
/// shape a persisted store would expose, so swapping the backing map for one
/// later is a local change.
class ProgressStore {
  ProgressStore._();

  static final ProgressStore instance = ProgressStore._();

  final Map<int, int> _stars = <int, int>{};
  final Map<int, int> _accuracy = <int, int>{};
  int _unlocked = 1;

  /// Highest level id the player may enter.
  int get unlocked => _unlocked;

  int starsFor(int levelId) => _stars[levelId] ?? 0;

  int accuracyFor(int levelId) => _accuracy[levelId] ?? 0;

  bool isUnlocked(int levelId) => levelId <= _unlocked;

  /// Levels finished with at least one star.
  int get solvedCount =>
      _stars.values.where((int value) => value > 0).length;

  int get bestAccuracy {
    int best = 0;
    for (final int value in _accuracy.values) {
      if (value > best) {
        best = value;
      }
    }
    return best;
  }

  int get totalLevels => kLevels.length;

  void record({
    required int levelId,
    required int stars,
    required int accuracy,
    required bool won,
  }) {
    if (stars > starsFor(levelId)) {
      _stars[levelId] = stars;
    }
    if (accuracy > accuracyFor(levelId)) {
      _accuracy[levelId] = accuracy;
    }
    if (won) {
      final int? next = nextLevelId(levelId);
      if (next != null && next > _unlocked) {
        _unlocked = next;
      }
    }
  }
}
