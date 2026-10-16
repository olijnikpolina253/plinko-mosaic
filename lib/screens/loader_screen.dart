import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../assets.dart';
import '../game/game_config.dart';
import '../theme.dart';
import '../widgets/aurora_painter.dart';

/// Branded splash. Deliberately much darker than the Menu and carrying no CTA.
///
/// The hand-off timer is armed on the FIRST RASTERISED FRAME, not in
/// `initState`: on a loaded emulator the raster thread can trail the UI thread
/// by tens of seconds, and a timer started at build time would expire before
/// the splash was ever presented.
class LoaderScreen extends StatefulWidget {
  const LoaderScreen({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<LoaderScreen> createState() => _LoaderScreenState();
}

class _LoaderScreenState extends State<LoaderScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entry;
  late final CurvedAnimation _badge;
  late final CurvedAnimation _fade;
  late final List<CurvedAnimation> _dotSteps;

  Timer? _handoff;
  Timer? _safety;
  bool _armed = false;
  bool _finished = false;
  bool _grain = false;

  @override
  void initState() {
    super.initState();
    _entry = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _badge = CurvedAnimation(
      parent: _entry,
      curve: const Interval(0, 0.67, curve: Curves.easeOutBack),
    );
    _fade = CurvedAnimation(
      parent: _entry,
      curve: const Interval(0, 0.67, curve: Curves.easeOut),
    );
    _dotSteps = <double>[0.33, 0.47, 0.60]
        .map((double start) => CurvedAnimation(
              parent: _entry,
              curve: Interval(start, 1.0, curve: Curves.easeOut),
            ))
        .toList();
    _entry.forward();

    WidgetsBinding.instance.addTimingsCallback(_onFrameTimings);

    // Backstop in case no frame timing ever arrives.
    _safety = Timer(
      const Duration(milliseconds: GameConfig.loaderDurationMs * 5),
      _finish,
    );

    // Grain is deliberately kept off the very first frame so the platform gets
    // its first rasterised frame as quickly as possible.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _grain = true);
    });
  }

  void _onFrameTimings(List<ui.FrameTiming> timings) {
    if (_armed) return;
    _armed = true;
    WidgetsBinding.instance.removeTimingsCallback(_onFrameTimings);
    _handoff = Timer(
      const Duration(milliseconds: GameConfig.loaderDurationMs),
      _finish,
    );
  }

  void _finish() {
    if (_finished) return;
    _finished = true;
    _handoff?.cancel();
    _safety?.cancel();
    if (!mounted) return;
    widget.onDone();
  }

  @override
  void dispose() {
    if (!_armed) {
      WidgetsBinding.instance.removeTimingsCallback(_onFrameTimings);
    }
    _handoff?.cancel();
    _safety?.cancel();
    _badge.dispose();
    _fade.dispose();
    for (final CurvedAnimation step in _dotSteps) {
      step.dispose();
    }
    _entry.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Image.asset(AppAssets.bgLoader, fit: BoxFit.cover),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  Color(0xD6070A18),
                  Color(0xC711162D),
                  Color(0xE00B1026),
                ],
              ),
            ),
            child: SizedBox.expand(),
          ),
          const CustomPaint(
            painter: AuroraPainter(<AuroraBlob>[
              AuroraBlob(
                dx: 0.22,
                dy: 0.30,
                radius: 180,
                color: Color(0x4D4B38A2),
              ),
              AuroraBlob(
                dx: 0.80,
                dy: 0.72,
                radius: 150,
                color: Color(0x2E2FC5CC),
              ),
            ]),
          ),
          if (_grain) const CustomPaint(painter: GrainPainter()),
          SafeArea(
            child: Center(
              child: FadeTransition(
                opacity: _fade,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    ScaleTransition(
                      scale: Tween<double>(begin: 0.82, end: 1.0)
                          .animate(_badge),
                      child: _brandBadge(),
                    ),
                    const SizedBox(height: 20),
                    _nodeRow(),
                    const SizedBox(height: 34),
                    Text(
                      AppTheme.brand,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.4,
                        color: AppColors.textPrimary,
                        shadows: <Shadow>[
                          Shadow(color: Color(0x732FC5CC), blurRadius: 18),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'LIGHT MOSAIC PUZZLE',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 3.0,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 40),
                    _progressBar(),
                    const SizedBox(height: 14),
                    const Text(
                      'LOADING...',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2.4,
                        color: AppColors.textCaption,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _brandBadge() {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        color: const Color(0xD91A2142),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: AppColors.cyan.withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.cyan.withValues(alpha: 0.22),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Center(
        child: Image.asset(AppAssets.icon, width: 72, height: 72),
      ),
    );
  }

  Widget _nodeRow() {
    const List<Color> dots = <Color>[
      AppColors.cyan,
      AppColors.gold,
      AppColors.rose,
    ];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List<Widget>.generate(dots.length, (int i) {
        final Animation<double> step = _dotSteps[i];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 7),
          child: AnimatedBuilder(
            animation: step,
            builder: (BuildContext context, Widget? child) {
              return Opacity(
                opacity: step.value,
                child: Transform.translate(
                  offset: Offset(0, 10 * (1 - step.value)),
                  child: child,
                ),
              );
            },
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: dots[i],
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: dots[i].withValues(alpha: 0.5),
                    blurRadius: 14,
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  /// One-shot 1200ms sweep. It must settle long before the hand-off so the
  /// window goes idle and uiautomator can dump the tree.
  Widget _progressBar() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: SizedBox(
        width: 180,
        height: 5,
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: ColoredBox(
                color: AppColors.textPrimary.withValues(alpha: 0.10),
              ),
            ),
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: 1),
              duration: const Duration(milliseconds: 1200),
              curve: Curves.easeOut,
              builder: (BuildContext context, double value, Widget? child) {
                return FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: value,
                  child: child,
                );
              },
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: <Color>[AppColors.cyan, AppColors.violet],
                  ),
                ),
                child: SizedBox.expand(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
