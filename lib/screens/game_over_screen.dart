import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../assets.dart';
import '../game/levels.dart';
import '../game/mosaic_engine.dart';
import '../theme.dart';
import '../widgets/aurora_backdrop.dart';
import '../widgets/buttons.dart';
import '../widgets/mini_mosaic.dart';
import '../widgets/stat_card.dart';

/// Result screen. The class name is mandatory for the screenshot gate.
class GameOverScreen extends StatefulWidget {
  const GameOverScreen({
    super.key,
    required this.result,
    required this.onPlayAgain,
    required this.onNextLevel,
    required this.onMenu,
  });

  final GameResult result;
  final VoidCallback onPlayAgain;
  final void Function(int levelId) onNextLevel;
  final VoidCallback onMenu;

  @override
  State<GameOverScreen> createState() => _GameOverScreenState();
}

class _GameOverScreenState extends State<GameOverScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 660),
  );

  @override
  void initState() {
    super.initState();
    _entrance.forward();
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  double _stage(double start, double end) {
    final double span = end - start;
    if (span <= 0) {
      return 1;
    }
    return ((_entrance.value - start) / span).clamp(0.0, 1.0);
  }

  Widget _shard(double size) {
    return Image.asset(
      AppAssets.spriteShard,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (BuildContext context, Object error, StackTrace? stack) =>
          SizedBox(width: size, height: size),
    );
  }

  Widget _boardColumn(String caption, List<List<int>> matrix, double cell) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          caption,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.8,
            height: 12 / 9,
            color: PMColors.text(0.55),
          ),
        ),
        const SizedBox(height: 8),
        MiniMosaic(matrix: matrix, cell: cell, gap: 3),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final GameResult result = widget.result;
    final bool won = result.won;
    final int? next = won ? nextLevelId(result.levelId) : null;
    final double cell = math.max(
      10.0,
      math.min(26.0, ((120 - (result.cols - 1) * 3) / result.cols).floorToDouble()),
    );

    return AuroraBackdrop(
      image: const DecorationImage(
        image: AssetImage(AppAssets.bgResult),
        fit: BoxFit.cover,
      ),
      overlay: won
          ? <Color>[
              PMColors.bgBase.withValues(alpha: 0.80),
              const Color(0xFF0E3A3E).withValues(alpha: 0.88),
            ]
          : <Color>[
              PMColors.bgBase.withValues(alpha: 0.86),
              const Color(0xFF2A1030).withValues(alpha: 0.90),
            ],
      topBlob: won ? PMColors.cyan : PMColors.rose,
      bottomBlob: won ? PMColors.gold : PMColors.violet,
      child: Stack(
        children: <Widget>[
          // Decor sits strictly below the headline band so nothing ever
          // crosses the letters.
          Positioned(left: 12, top: 132, child: Opacity(opacity: 0.5, child: Transform.rotate(angle: -0.34, child: _shard(92)))),
          Positioned(right: 14, bottom: 236, child: Opacity(opacity: 0.5, child: Transform.rotate(angle: 0.46, child: _shard(64)))),
          SafeArea(
            top: false,
            child: AnimatedBuilder(
              animation: _entrance,
              builder: (BuildContext context, Widget? child) {
                final double headT = _stage(0.0, 0.64);
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 44, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Transform.scale(
                        scale:
                            0.86 +
                            0.14 * Curves.easeOutBack.transform(headT),
                        child: Opacity(
                          opacity: headT,
                          child: Text(
                            won ? 'MOSAIC COMPLETE' : 'OUT OF MOVES',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 3.2,
                              height: 36 / 30,
                              color: PMColors.textPrimary,
                              shadows: <Shadow>[
                                Shadow(
                                  color: (won ? PMColors.cyan : PMColors.rose)
                                      .withValues(alpha: 0.55),
                                  blurRadius: 24,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      StarRow(earned: result.stars, size: 22),
                      Expanded(
                        child: Center(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(22),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: PMColors.surface.withValues(
                                    alpha: 0.70,
                                  ),
                                  borderRadius: BorderRadius.circular(22),
                                  border: Border.all(
                                    color: PMColors.text(0.10),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: <Widget>[
                                    _boardColumn('YOURS', result.board, cell),
                                    const SizedBox(width: 20),
                                    _boardColumn(
                                      'TARGET',
                                      result.target,
                                      cell,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Opacity(
                        opacity: _stage(0.30, 0.78),
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: StatCard(
                                value: '${result.accuracy}%',
                                label: 'ACCURACY',
                                valueColor: PMColors.cyan,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: StatCard(
                                value:
                                    '${result.movesUsed}/${result.movesAllowed}',
                                label: 'MOVES USED',
                                valueColor: PMColors.gold,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: StatCard(
                                value: '${result.stars}/3',
                                label: 'STARS',
                                valueColor: PMColors.rose,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      if (next != null) ...<Widget>[
                        PrimaryButton(
                          label: 'NEXT LEVEL',
                          icon: Icons.arrow_forward_rounded,
                          height: 56,
                          radius: 18,
                          fontSize: 16,
                          onTap: () => widget.onNextLevel(next),
                        ),
                        const SizedBox(height: 12),
                      ],
                      PrimaryButton(
                        label: 'PLAY AGAIN',
                        icon: Icons.replay_rounded,
                        height: 56,
                        radius: 18,
                        fontSize: 16,
                        gradient: const <Color>[PMColors.rose, PMColors.gold],
                        glow: PMColors.rose,
                        onTap: widget.onPlayAgain,
                      ),
                      const SizedBox(height: 12),
                      SecondaryButton(
                        label: 'MAIN MENU',
                        icon: Icons.home_rounded,
                        height: 48,
                        borderColor: PMColors.textPrimary,
                        onTap: widget.onMenu,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
