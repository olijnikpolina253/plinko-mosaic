/// Tunable constants shared by the screens and the engine.
class GameConfig {
  const GameConfig._();

  /// Splash hold. Pinned at exactly 8000 ms by the pipeline gate — the capture
  /// agent needs the loader still on screen when it takes its first frame.
  static const int loaderDurationMs = 8000;

  /// One-shot entrance of the loader. After this the loader is visually static
  /// so `uiautomator waitForIdle` can return.
  static const int loaderEntranceMs = 2200;

  /// Cross-fade between state-machine screens.
  static const int screenFadeMs = 420;

  /// Backstop for a fully passive run: nothing tapped at all.
  static const int idleBackstopMs = 26000;

  /// Backstop re-armed after the first tap, so one tap is enough to surface a
  /// result frame.
  static const int engagedBackstopMs = 9000;

  /// Floor measured from GameScreen mount. The engaged backstop never resolves
  /// earlier than this, otherwise the round ends before the gameplay frame is
  /// captured.
  static const int minMsFromMount = 24000;

  // Board geometry — see the BOARD_FRAME formula. Keeps overflow at 0 px.
  static const double boardPad = 8;
  static const double boardBorder = 2;
  static const double boardFrame = boardPad + boardBorder;
  static const double tileGap = 6;
  static const double boardMaxWidth = 380;
  static const double boardSideMargin = 32;

  /// Exactly three node colours: cyan (0), gold (1), rose (2).
  static const int colorCount = 3;

  // Phase durations (all one-shot).
  static const int resolveMs = 320;
  static const int winBloomMs = 700;
  static const int lossFadeMs = 500;
}
