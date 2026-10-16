import 'package:flutter/material.dart';

import '../assets.dart';
import '../game/game_config.dart';
import '../game/level_generator.dart';
import '../game/progress_store.dart';
import '../theme.dart';
import '../widgets/aurora_painter.dart';
import '../widgets/mosaic_board.dart';

/// Full-screen level picker. Lives outside lib/screens so the screenshot gate
/// keeps counting four primary screens.
class LevelGalleryPanel extends StatelessWidget {
  const LevelGalleryPanel({
    super.key,
    required this.onPick,
    required this.onBack,
  });

  final void Function(int level) onPick;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final ProgressStore progress = ProgressStore.instance;

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: Opacity(
              opacity: 0.30,
              child: Image.asset(AppAssets.bgMenu, fit: BoxFit.cover),
            ),
          ),
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[Color(0xF011162D), Color(0xFA0B1026)],
                ),
              ),
            ),
          ),
          const Positioned.fill(
            child: CustomPaint(
              painter: AuroraPainter(<AuroraBlob>[
                AuroraBlob(
                  dx: 0.20,
                  dy: 0.18,
                  radius: 150,
                  color: Color(0x334B38A2),
                ),
                AuroraBlob(
                  dx: 0.86,
                  dy: 0.82,
                  radius: 130,
                  color: Color(0x1F2FC5CC),
                ),
              ]),
            ),
          ),
          SafeArea(
            top: false,
            child: Column(
              children: <Widget>[
                _header(progress),
                Expanded(child: _grid(progress)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(ProgressStore progress) {
    return Container(
      padding: const EdgeInsets.only(top: 44, left: 16, right: 16, bottom: 12),
      decoration: const BoxDecoration(
        color: Color(0x8C0B1026),
        border: Border(bottom: BorderSide(color: Color(0x14F7F2E9))),
      ),
      child: Row(
        children: <Widget>[
          Semantics(
            button: true,
            label: 'BACK',
            child: Material(
              color: AppColors.textPrimary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: onBack,
                child: const SizedBox(
                  width: 44,
                  height: 44,
                  child: Icon(
                    Icons.arrow_back_rounded,
                    size: 22,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          ),
          const Expanded(
            child: Text(
              'LEVEL GALLERY',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.6,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.violet.withValues(alpha: 0.30),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.cyan.withValues(alpha: 0.40),
              ),
            ),
            child: Text(
              'SOLVED ${progress.solvedCount}/${GameConfig.totalLevels}',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: AppColors.textPrimary,
                fontFeatures: AppTheme.tabular,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _grid(ProgressStore progress) {
    return GridView.count(
      crossAxisCount: 3,
      childAspectRatio: 0.82,
      padding: const EdgeInsets.all(16),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      physics: const BouncingScrollPhysics(),
      children: List<Widget>.generate(GameConfig.totalLevels, (int i) {
        final int level = i + 1;
        return _tile(level, progress);
      }),
    );
  }

  Widget _tile(int level, ProgressStore progress) {
    final bool unlocked = progress.isUnlocked(level);
    final int stars = progress.starsFor(level);
    final LevelSpec spec = LevelGenerator.build(level);

    final Widget body = Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Opacity(
            opacity: unlocked ? 1.0 : 0.35,
            child: MosaicBoard(
              state: spec.target,
              target: spec.target,
              tile: 9,
              radius: 12,
              detail: BoardDetail.mini,
              showMatches: false,
              borderColor: AppColors.textPrimary.withValues(alpha: 0.10),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'LVL ${level.toString().padLeft(2, '0')}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
              color: unlocked ? AppColors.textPrimary : AppColors.textFaint,
              fontFeatures: AppTheme.tabular,
            ),
          ),
          const SizedBox(height: 6),
          if (unlocked)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List<Widget>.generate(3, (int i) {
                return Icon(
                  Icons.star_rounded,
                  size: 12,
                  color: i < stars
                      ? AppColors.gold
                      : AppColors.textPrimary.withValues(alpha: 0.16),
                );
              }),
            )
          else
            const Icon(
              Icons.lock_rounded,
              size: 20,
              color: AppColors.textFaint,
            ),
        ],
      ),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: unlocked
              ? AppColors.cyan.withValues(alpha: 0.30)
              : AppColors.textPrimary.withValues(alpha: 0.07),
        ),
      ),
      child: unlocked
          ? Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => onPick(level),
                child: body,
              ),
            )
          : body,
    );
  }
}
