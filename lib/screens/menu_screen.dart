import 'package:flutter/material.dart';

import '../assets.dart';
import '../game/levels.dart';
import '../game/progress_store.dart';
import '../panels/level_gallery_panel.dart';
import '../panels/tutorial_panel.dart';
import '../theme.dart';
import '../widgets/buttons.dart';
import '../widgets/glass_panel.dart';
import '../widgets/mini_mosaic.dart';
import '../widgets/stat_card.dart';

/// Home screen, archetype M2 bottom-sheet: full-bleed art on top, frosted
/// sheet with the single call to action at the bottom.
class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key, required this.onStart});

  /// Enters the game at the given level.
  final void Function(int levelId) onStart;

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );

  /// Static preview pattern shown in the art block.
  static const List<List<int>> _preview = <List<int>>[
    <int>[0, 1, 2],
    <int>[1, 2, 0],
    <int>[2, 0, 1],
  ];

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

  Future<void> _openGallery() async {
    final int? picked = await showLevelGalleryPanel(context);
    if (picked != null && mounted) {
      widget.onStart(picked);
    }
  }

  Future<void> _openTutorial() => showTutorialPanel(context);

  Widget _artBlock(double sheetFade) {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        Image.asset(
          AppAssets.bgMenu,
          fit: BoxFit.cover,
          errorBuilder:
              (BuildContext context, Object error, StackTrace? stack) =>
                  const ColoredBox(color: PMColors.bgBase),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[
                PMColors.bgDeep.withValues(alpha: 0.55),
                PMColors.bgBase.withValues(alpha: 0.25),
                PMColors.bgBase,
              ],
              stops: const <double>[0.0, 0.55, 1.0],
            ),
          ),
        ),
        Positioned(
          left: 18,
          top: 54,
          child: Opacity(
            opacity: 0.55 * sheetFade,
            child: Transform.rotate(
              angle: -0.38,
              child: Image.asset(
                AppAssets.spriteShard,
                width: 86,
                height: 86,
                fit: BoxFit.contain,
                errorBuilder:
                    (BuildContext context, Object error, StackTrace? stack) =>
                        const SizedBox(width: 86, height: 86),
              ),
            ),
          ),
        ),
        Positioned(
          right: 16,
          top: 196,
          child: Opacity(
            opacity: 0.55 * sheetFade,
            child: Transform.rotate(
              angle: 0.52,
              child: Image.asset(
                AppAssets.spriteShard,
                width: 58,
                height: 58,
                fit: BoxFit.contain,
                errorBuilder:
                    (BuildContext context, Object error, StackTrace? stack) =>
                        const SizedBox(width: 58, height: 58),
              ),
            ),
          ),
        ),
        Center(
          child: Opacity(
            opacity: sheetFade,
            child: const MiniMosaic(matrix: _preview, cell: 44, gap: 10),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final ProgressStore progress = ProgressStore.instance;
    final int solved = progress.solvedCount;
    final int bestAcc = progress.bestAccuracy;
    final int unlocked = progress.unlocked;

    return AnimatedBuilder(
      animation: _entrance,
      builder: (BuildContext context, Widget? child) {
        final double t = Curves.easeOutCubic.transform(
          _entrance.value.clamp(0.0, 1.0),
        );
        return SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(
                child: ClipRect(
                  child: Transform.scale(
                    scale: 1.04 - 0.04 * t,
                    child: _artBlock(t),
                  ),
                ),
              ),
              Transform.translate(
                offset: Offset(0, 28 * (1 - t)),
                child: Opacity(
                  opacity: t,
                  child: GlassPanel(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                    fillAlpha: 0.72,
                    blur: 18,
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
                    child: SafeArea(
                      top: false,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Center(
                            child: Container(
                              width: 44,
                              height: 4,
                              decoration: BoxDecoration(
                                color: PMColors.text(0.18),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'PLINKO MOSAIC',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'CYCLE THE NODES · MATCH THE PATTERN',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.8,
                              height: 15 / 11,
                              color: PMColors.text(0.60),
                            ),
                          ),
                          const SizedBox(height: 16),
                          PrimaryButton(
                            label: 'PLAY',
                            icon: Icons.play_arrow_rounded,
                            onTap: () => widget.onStart(unlocked),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Flexible(
                                child: ChipButton(
                                  label: 'LEVELS $unlocked/${kLevels.length}',
                                  onTap: _openGallery,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Flexible(
                                child: ChipButton(
                                  label: 'HOW IT WORKS',
                                  borderColor: PMColors.gold,
                                  onTap: _openTutorial,
                                ),
                              ),
                            ],
                          ),
                          if (solved > 0 && bestAcc > 0) ...<Widget>[
                            const SizedBox(height: 12),
                            Row(
                              children: <Widget>[
                                Expanded(
                                  child: StatCard(
                                    value: '$solved',
                                    label: 'SOLVED',
                                    valueColor: PMColors.cyan,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: StatCard(
                                    value: '$bestAcc%',
                                    label: 'BEST ACC',
                                    valueColor: PMColors.gold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
