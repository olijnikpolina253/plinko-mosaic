import 'package:flutter/material.dart';

import '../assets.dart';
import '../theme.dart';
import '../widgets/aurora_painter.dart';
import '../widgets/cta_buttons.dart';
import '../widgets/stat_card.dart';

/// Home screen, archetype M2: full-bleed art on top, frosted sheet below.
///
/// Exactly one string on this screen contains PLAY or START — the primary CTA
/// 'START PUZZLE', which goes straight into a round with no picker in between.
class MenuScreen extends StatefulWidget {
  const MenuScreen({
    super.key,
    required this.onStart,
    required this.onGallery,
    required this.onRules,
    required this.solvedCount,
    required this.bestAccuracy,
  });

  final VoidCallback onStart;
  final VoidCallback onGallery;
  final VoidCallback onRules;
  final int solvedCount;
  final int bestAccuracy;

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entry;
  late final CurvedAnimation _curve;

  @override
  void initState() {
    super.initState();
    _entry = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 620),
    );
    _curve = CurvedAnimation(parent: _entry, curve: Curves.easeOutCubic);
    _entry.forward();
  }

  @override
  void dispose() {
    _curve.dispose();
    _entry.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final MediaQueryData media = MediaQuery.of(context);
    final double sheetMinHeight = media.size.height * 0.40;

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: Column(
        children: <Widget>[
          Expanded(child: _artBlock(media.size.width)),
          _sheet(sheetMinHeight, media.padding.bottom),
        ],
      ),
    );
  }

  Widget _artBlock(double screenWidth) {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        Image.asset(AppAssets.bgMenu, fit: BoxFit.cover),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[Color(0x5C070A18), Color(0x1A11162D)],
            ),
          ),
          child: SizedBox.expand(),
        ),
        Align(
          alignment: const Alignment(0, 0.08),
          child: AnimatedBuilder(
            animation: _curve,
            builder: (BuildContext context, Widget? child) {
              return Transform.scale(
                scale: 1.04 - 0.04 * _curve.value,
                child: child,
              );
            },
            child: Image.asset(
              AppAssets.spriteMosaicHero,
              width: screenWidth * 0.62,
              fit: BoxFit.contain,
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 120,
          child: const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[Color(0x0011162D), Color(0xFF11162D)],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _sheet(double minHeight, double safeBottom) {
    final bool showPills = widget.solvedCount > 0 && widget.bestAccuracy > 0;

    return AnimatedBuilder(
      animation: _curve,
      builder: (BuildContext context, Widget? child) {
        return Transform.translate(
          offset: Offset(0, 40 * (1 - _curve.value)),
          child: Opacity(opacity: _curve.value, child: child),
        );
      },
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        child: Container(
          constraints: BoxConstraints(minHeight: minHeight),
          decoration: const BoxDecoration(
            color: Color(0xF0141A33),
            border: Border(top: BorderSide(color: Color(0x14F7F2E9))),
          ),
          child: Stack(
            children: <Widget>[
              const Positioned.fill(
                child: CustomPaint(
                  painter: AuroraPainter(<AuroraBlob>[
                    AuroraBlob(
                      dx: 0.18,
                      dy: 0.30,
                      radius: 150,
                      color: Color(0x384B38A2),
                    ),
                    AuroraBlob(
                      dx: 0.88,
                      dy: 0.86,
                      radius: 120,
                      color: Color(0x1F2FC5CC),
                    ),
                  ]),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(20, 12, 20, 10 + safeBottom),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color:
                              AppColors.textPrimary.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      AppTheme.brand,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'CYCLE THE NODES · MATCH THE PATTERN',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2.0,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (showPills)
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: StatCard(
                              value: '${widget.solvedCount}/12',
                              label: 'solved',
                              valueColor: AppColors.cyan,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: StatCard(
                              value: '${widget.bestAccuracy}%',
                              label: 'best',
                              valueColor: AppColors.gold,
                            ),
                          ),
                        ],
                      )
                    else
                      const Text(
                        'ONE TAP RECOLOURS THREE NODES',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.4,
                          color: AppColors.textCaption,
                        ),
                      ),
                    const SizedBox(height: 18),
                    PrimaryCta(
                      label: 'START PUZZLE',
                      icon: Icons.auto_awesome,
                      onTap: widget.onStart,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: SecondaryCta(
                            label: 'LEVEL GALLERY',
                            icon: Icons.grid_view_rounded,
                            onTap: widget.onGallery,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SecondaryCta(
                            label: 'GAME RULES',
                            icon: Icons.menu_book_rounded,
                            accent: AppColors.gold,
                            onTap: widget.onRules,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'FOR ENTERTAINMENT ONLY · NO WAGERS',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                        color: AppColors.textFaint,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
