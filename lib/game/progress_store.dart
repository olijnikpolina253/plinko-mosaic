import 'game_config.dart';
import 'round_result.dart';

/// In-memory progress. No persistence package — progress resets on a cold
/// start, which keeps the dependency set at flutter + cupertino_icons.
class ProgressStore {
  ProgressStore._();

  static final ProgressStore instance = ProgressStore._();

  final Map<int, int> stars = <int, int>{};

  int currentLevel = 1;
  int bestAccuracy = 0;

  int starsFor(int level) => stars[level] ?? 0;

  int get solvedCount => stars.values.where((int s) => s > 0).length;

  bool isUnlocked(int level) => level <= 1 || starsFor(level - 1) > 0;

  void record(RoundResult result) {
    if (result.accuracy > bestAccuracy) {
      bestAccuracy = result.accuracy;
    }
    if (result.win && result.stars > starsFor(result.level)) {
      stars[result.level] = result.stars;
    }
  }

  int nextLevelAfter(int level) =>
      GameConfig.clampLevel(level >= GameConfig.totalLevels ? level : level + 1);

  void reset() {
    stars.clear();
    currentLevel = 1;
    bestAccuracy = 0;
  }
}
