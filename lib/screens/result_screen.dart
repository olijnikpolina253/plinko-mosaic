import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../assets.dart';
import '../game/board_state.dart';
import '../game/game_config.dart';
import '../game/round_result.dart';
import '../theme.dart';
import '../widgets/aurora_painter.dart';
import '../widgets/cta_buttons.dart';
import '../widgets/mosaic_board.dart';
import '../widgets/stat_card.dart';

/// Round verdict. The replay CTA always carries the word AGAIN, in the primary
/// slot on a loss and in the secondary slot on a win.
class ResultScreen extends StatefulWidget {
  const ResultScreen({
    super.key,
    required this.result,
    required this.onPlayAgain,
    required this.onNextLevel,
    required this.onGallery,
    required this.onMenu,
  });

  final RoundResult result;
  final VoidCallback onPlayAgain;
  final VoidCallback onNextLevel;
  final VoidCallback onGallery;
  final VoidCallback onMenu;

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entry;
  late final CurvedAnimation _curve;
  late final List<CurvedAnimation> _starPops;

  @override
  void initState() {
    super.initState();
    _entry = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _curve = CurvedAnimation(
      parent: _entry,
      curve: const Interval(0, 0.8, curve: Curves.easeOutCubic),
    );
    _starPops = List<CurvedAnimation>.generate(
      3,
      (int i) => CurvedAnimation(
        parent: _entry,
        curve: Interval(
          i * 0.17,
          math.min(1.0, 0.55 + i * 0.17),
          curve: Curves.easeOutBack,
        ),
      ),
    );
    _entry.forward();
  }

  @override
  void dispose() {
    _curve.dispose();
    for (final CurvedAnimation pop in _starPops) {
      pop.dispose();
    }
    _entry.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final RoundResult r = widget.result;
    final MediaQueryData media = MediaQuery.of(context);

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: Opacity(
              opacity: 0.35,
              child: Image.asset(AppAssets.bgGame, fit: BoxFit.cover),
            ),
          ),
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[
                    Color(0xE81A2142),
                    Color(0xF211162D),
                    Color(0xFA0B1026),
                  ],
                ),
              ),
            ),
          ),
          const Positioned.fill(
            child: CustomPaint(
              painter: AuroraPainter(<AuroraBlob>[
                AuroraBlob(
                  dx: 0.84,
                  dy: 0.16,
                  radius: 160,
                  color: Color(0x382FC5CC),
                ),
                AuroraBlob(
                  dx: 0.14,
                  dy: 0.88,
                  radius: 140,
                  color: Color(0x29EA5C82),
                ),
              ]),
            ),
          ),
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _curve,
              builder: (BuildContext context, Widget? child) {
                return Opacity(
                  opacity: _curve.value,
                  child: Transform.translate(
                    offset: Offset(0, 28 * (1 - _curve.value)),
                    child: child,
                  ),
                );
              },
              child: _content(r, media.padding.bottom, media.size.height),
            ),
          ),
        ],
      ),
    );
  }

  Widget _content(RoundResult r, double safeBottom, double screenHeight) {
    // The decoration shrinks on short screens so the verdict, stats and CTAs
    // always keep their room (rule 17 — it never sits over the letters).
    final double heroSize = math.min(112, screenHeight * 0.13);

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 44, 20, 24 + safeBottom),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Center(
            child: Image.asset(
              AppAssets.spriteMosaicHero,
              width: heroSize,
              height: heroSize,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            r.win ? 'MOSAIC COMPLETE' : 'OUT OF MOVES',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
              color: AppColors.textPrimary,
              shadows: <Shadow>[
                Shadow(
                  color: (r.win ? AppColors.cyan : AppColors.rose)
                      .withValues(alpha: 0.5),
                  blurRadius: 20,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _stars(r.stars),
          const SizedBox(height: 18),
          Row(
            children: <Widget>[
              Expanded(
                child: StatCard(
                  value: '${r.accuracy}%',
                  label: 'accuracy',
                  valueColor: AppColors.cyan,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatCard(
                  value: '${r.movesUsed}/${r.moveLimit}',
                  label: 'moves',
                  valueColor: AppColors.gold,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatCard(
                  value: '${r.level}',
                  label: 'level',
                  valueColor: AppColors.rose,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(child: _preview(r)),
          const SizedBox(height: 16),
          ..._ctas(r),
        ],
      ),
    );
  }

  Widget _stars(int earned) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List<Widget>.generate(3, (int i) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.6, end: 1.0).animate(_starPops[i]),
            child: Icon(
              Icons.star_rounded,
              size: 32,
              color: i < earned
                  ? AppColors.gold
                  : AppColors.textPrimary.withValues(alpha: 0.16),
            ),
          ),
        );
      }),
    );
  }

  Widget _preview(RoundResult r) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final int n = math.max(r.finalBoard.cols, r.finalBoard.rows);
        final double byHeight = constraints.maxHeight - 26;
        final double byWidth = (constraints.maxWidth - 16) / 2;
        final double budget = math.min(byHeight, byWidth);
        if (budget < 40) return const SizedBox.shrink();
        final double tile = GameConfig.tileFor(budget, n);

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _previewColumn('YOURS', r.finalBoard, r.target, tile, true),
            const SizedBox(width: 16),
            _previewColumn('TARGET', r.target, r.target, tile, false),
          ],
        );
      },
    );
  }

  Widget _previewColumn(
    String caption,
    BoardState board,
    BoardState target,
    double tile,
    bool showMatches,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          caption,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.0,
            color: AppColors.textCaption,
          ),
        ),
        const SizedBox(height: 8),
        MosaicBoard(
          state: board,
          target: target,
          tile: tile,
          radius: 20,
          showMatches: showMatches,
        ),
      ],
    );
  }

  List<Widget> _ctas(RoundResult r) {
    final bool last = r.level >= GameConfig.totalLevels;
    if (r.win && !last) {
      return <Widget>[
        PrimaryCta(
          label: 'NEXT LEVEL',
          icon: Icons.arrow_forward_rounded,
          onTap: widget.onNextLevel,
        ),
        const SizedBox(height: 12),
        SecondaryCta(
          label: 'PLAY AGAIN',
          icon: Icons.replay_rounded,
          onTap: widget.onPlayAgain,
        ),
        const SizedBox(height: 12),
        SecondaryCta(
          label: 'MENU',
          icon: Icons.home_rounded,
          accent: AppColors.gold,
          onTap: widget.onMenu,
        ),
      ];
    }

    return <Widget>[
      PrimaryCta(
        label: 'PLAY AGAIN',
        icon: Icons.replay_rounded,
        onTap: widget.onPlayAgain,
      ),
      const SizedBox(height: 12),
      SecondaryCta(
        label: 'LEVEL GALLERY',
        icon: Icons.grid_view_rounded,
        onTap: widget.onGallery,
      ),
      const SizedBox(height: 12),
      SecondaryCta(
        label: 'MENU',
        icon: Icons.home_rounded,
        accent: AppColors.gold,
        onTap: widget.onMenu,
      ),
    ];
  }
}
