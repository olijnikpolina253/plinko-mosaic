import 'package:flutter/material.dart';

import '../theme.dart';

/// Static tuning for PlinkoMosaic. No physics, no countdown — a pure
/// colour-cycling logic puzzle.
class GameConfig {
  const GameConfig._();

  /// Splash hold before the Menu takes over. Wall-clock only, never an
  /// animation duration.
  static const int loaderDurationMs = 8000;

  /// Armed once when the board mounts; resolves an untouched round so the
  /// capture harness always reaches a result frame.
  static const int idleBackstopMs = 40000;

  /// Armed once on the very first board tap; never re-armed.
  static const int engagedBackstopMs = 9000;

  static const int totalLevels = 12;

  /// Colour ramp, index 0..3. Index 3 only exists at four-colour levels.
  static const List<Color> colourRamp = <Color>[
    AppColors.cyan,
    AppColors.gold,
    AppColors.rose,
    AppColors.violetLit,
  ];

  static int clampLevel(int level) {
    if (level < 1) return 1;
    if (level > totalLevels) return totalLevels;
    return level;
  }

  static int colsFor(int level) => clampLevel(level) <= 4 ? 4 : 5;

  static int rowsFor(int level) => colsFor(level);

  static int coloursFor(int level) => clampLevel(level) <= 8 ? 3 : 4;

  static int scrambleTapsFor(int level) => clampLevel(level) + 2;

  static int slackFor(int level) => clampLevel(level) <= 4 ? 4 : 3;

  /// Board frame = inner padding (8) + border (2). Flutter insets a Container's
  /// child by both, so the child area is exactly `width - 2 * boardFrame`.
  static const double boardPadding = 8;
  static const double boardBorder = 2;
  static const double boardFrame = boardPadding + boardBorder;

  static const double boardRadius = 24;

  /// Widest the board may ever be: screen minus gutters, hard-capped at 380.
  static double boardMaxWidth(double screenWidth) {
    final double available = screenWidth - 32;
    return available < 380 ? available : 380;
  }

  /// Floor the tile so `tile * n + 2 * frame` can never exceed the budget.
  static double tileFor(double boardMaxSide, int n) {
    final double raw = (boardMaxSide - 2 * boardFrame) / n;
    final double tile = raw.floorToDouble();
    return tile < 8 ? 8 : tile;
  }

  static double boardSideFor(double tile, int n) => tile * n + 2 * boardFrame;
}
