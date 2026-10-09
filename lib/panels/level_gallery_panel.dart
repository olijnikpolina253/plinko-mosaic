import 'package:flutter/material.dart';

import '../game/level_generator.dart';
import '../game/levels.dart';
import '../game/progress_store.dart';
import '../theme.dart';
import '../widgets/glass_panel.dart';
import '../widgets/mini_mosaic.dart';
import '../widgets/stat_card.dart';

/// Full-screen overlay, NOT a member of the screen state machine — the
/// screenshot gate derives its required frame count from `lib/screens`.
Future<int?> showLevelGalleryPanel(BuildContext context) {
  return showGeneralDialog<int>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'LEVEL GALLERY',
    barrierColor: PMColors.bgDeep.withValues(alpha: 0.86),
    transitionDuration: const Duration(milliseconds: 260),
    pageBuilder: (BuildContext context, Animation<double> a, Animation<double> b) =>
        const _LevelGalleryPanel(),
    transitionBuilder:
        (
          BuildContext context,
          Animation<double> animation,
          Animation<double> secondary,
          Widget child,
        ) {
          final CurvedAnimation curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.94, end: 1.0).animate(curved),
              child: child,
            ),
          );
        },
  );
}

class _LevelGalleryPanel extends StatelessWidget {
  const _LevelGalleryPanel();

  @override
  Widget build(BuildContext context) {
    final ProgressStore progress = ProgressStore.instance;

    return Material(
      type: MaterialType.transparency,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 44, 16, 20),
          child: GlassPanel(
            radius: 26,
            fillAlpha: 0.78,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        'LEVEL GALLERY',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2.4,
                          height: 24 / 20,
                          color: PMColors.textPrimary,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 48,
                      height: 48,
                      child: IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.close_rounded,
                          size: 24,
                          color: PMColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: GridView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 8),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          mainAxisExtent: 128,
                        ),
                    itemCount: kLevels.length,
                    itemBuilder: (BuildContext context, int index) {
                      final LevelDef level = kLevels[index];
                      return _LevelThumb(
                        level: level,
                        unlocked: progress.isUnlocked(level.id),
                        stars: progress.starsFor(level.id),
                        onTap: () => Navigator.of(context).pop(level.id),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LevelThumb extends StatelessWidget {
  const _LevelThumb({
    required this.level,
    required this.unlocked,
    required this.stars,
    required this.onTap,
  });

  final LevelDef level;
  final bool unlocked;
  final int stars;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final GeneratedLevel generated = generateLevel(level);
    final double cell =
        ((62 - (level.cols - 1) * 2) / level.cols).floorToDouble();

    final Widget body = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        MiniMosaic(matrix: generated.target, cell: cell, gap: 2),
        const SizedBox(height: 7),
        Text(
          '${level.id}',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            height: 16 / 13,
            color: PMColors.textPrimary,
            fontFeatures: kTabularFigures,
          ),
        ),
        const SizedBox(height: 3),
        StarRow(earned: stars, size: 13),
      ],
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      // Tapping a locked level does nothing — no snackbar, no dialog.
      onTap: unlocked ? onTap : null,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          decoration: BoxDecoration(
            color: PMColors.surfaceHi.withValues(alpha: 0.80),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: PMColors.text(0.08), width: 1),
          ),
          child: unlocked
              ? body
              : Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    ColorFiltered(
                      colorFilter: ColorFilter.mode(
                        PMColors.bgBase.withValues(alpha: 0.72),
                        BlendMode.srcATop,
                      ),
                      child: body,
                    ),
                    Icon(
                      Icons.lock_rounded,
                      size: 20,
                      color: PMColors.text(0.45),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
