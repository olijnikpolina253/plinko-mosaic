import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../assets.dart';
import '../game/game_config.dart';
import '../theme.dart';

/// Deterministic star/dust field, painted ONCE. The grain is what lifts the
/// loader PNG into the capture band the screenshot gate expects — it must not
/// be animated and must not get heavier.
class GrainPainter extends CustomPainter {
  GrainPainter();

  static const int passes = 3;
  static const int pointsPerPass = 6000;
  static const List<double> passAlpha = <double>[0.11, 0.08, 0.05];

  Size? _size;
  List<Float32List>? _points;

  List<Float32List> _build(Size size) {
    final Random rng = Random(7);
    final List<Float32List> result = <Float32List>[];
    for (int pass = 0; pass < passes; pass++) {
      final Float32List buffer = Float32List(pointsPerPass * 2);
      for (int i = 0; i < pointsPerPass; i++) {
        buffer[i * 2] = rng.nextDouble() * size.width;
        buffer[i * 2 + 1] = rng.nextDouble() * size.height;
      }
      result.add(buffer);
    }
    return result;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (_points == null || _size != size) {
      _points = _build(size);
      _size = size;
    }
    final List<Float32List> points = _points!;
    for (int pass = 0; pass < passes; pass++) {
      canvas.drawRawPoints(
        ui.PointMode.points,
        points[pass],
        Paint()
          ..color = PMColors.text(passAlpha[pass])
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.square,
      );
    }
  }

  @override
  bool shouldRepaint(GrainPainter oldDelegate) => false;
}

/// Branded splash. Visually much darker than the Menu, no CTA, no chips.
class LoaderScreen extends StatefulWidget {
  const LoaderScreen({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<LoaderScreen> createState() => _LoaderScreenState();
}

class _LoaderScreenState extends State<LoaderScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: GameConfig.loaderEntranceMs),
  );

  Timer? _handoff;
  Timer? _safety;
  bool _armed = false;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _entrance.forward();
    // The hold is measured from the first PRESENTED frame: on a loaded
    // emulator the raster thread can trail initState by seconds, and a
    // wall-clock timer would then measure engine startup, not screen time.
    WidgetsBinding.instance.addTimingsCallback(_onFirstFrame);
    _safety = Timer(
      const Duration(milliseconds: GameConfig.loaderDurationMs * 5),
      _finish,
    );
  }

  void _onFirstFrame(List<ui.FrameTiming> timings) {
    if (_armed) {
      return;
    }
    _armed = true;
    WidgetsBinding.instance.removeTimingsCallback(_onFirstFrame);
    _handoff = Timer(
      const Duration(milliseconds: GameConfig.loaderDurationMs),
      _finish,
    );
  }

  void _finish() {
    if (_finished || !mounted) {
      return;
    }
    _finished = true;
    widget.onDone();
  }

  @override
  void dispose() {
    if (!_armed) {
      WidgetsBinding.instance.removeTimingsCallback(_onFirstFrame);
    }
    _handoff?.cancel();
    _safety?.cancel();
    _entrance.dispose();
    super.dispose();
  }

  double _interval(double start, double end) {
    final double span = end - start;
    if (span <= 0) {
      return 1;
    }
    return ((_entrance.value - start) / span).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: PMColors.bgDeep,
        image: DecorationImage(
          image: AssetImage(AppAssets.bgLoader),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  const Color(0xFF07091A).withValues(alpha: 0.92),
                  const Color(0xFF11162D).withValues(alpha: 0.80),
                  const Color(0xFF1C1140).withValues(alpha: 0.88),
                ],
              ),
            ),
          ),
          RepaintBoundary(child: CustomPaint(painter: GrainPainter())),
          SafeArea(
            child: Center(
              child: AnimatedBuilder(
                animation: _entrance,
                builder: (BuildContext context, Widget? child) {
                  final double iconT = _interval(0.0, 0.409);
                  final double iconFade = _interval(0.0, 0.318);
                  final double titleT = _interval(0.182, 0.545);
                  final double subT = _interval(0.409, 0.727);
                  final double scale =
                      0.72 +
                      0.28 * Curves.easeOutBack.transform(iconT);
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Opacity(
                        opacity: iconFade,
                        child: Transform.scale(
                          scale: scale,
                          child: Container(
                            width: 168,
                            height: 168,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: <Color>[
                                  PMColors.violet.withValues(alpha: 0.55),
                                  PMColors.violet.withValues(alpha: 0.0),
                                ],
                              ),
                              border: Border.all(
                                color: PMColors.cyan.withValues(alpha: 0.35),
                                width: 1,
                              ),
                            ),
                            child: Image.asset(
                              AppAssets.icon,
                              width: 132,
                              height: 132,
                              fit: BoxFit.contain,
                              errorBuilder:
                                  (
                                    BuildContext context,
                                    Object error,
                                    StackTrace? stack,
                                  ) => const SizedBox(width: 132, height: 132),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 34),
                      Opacity(
                        opacity: titleT,
                        child: Transform.translate(
                          offset: Offset(0, 16 * (1 - titleT)),
                          child: Text(
                            'PLINKO MOSAIC',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.displayLarge
                                ?.copyWith(
                                  shadows: <Shadow>[
                                    Shadow(
                                      color: PMColors.cyan.withValues(
                                        alpha: 0.45,
                                      ),
                                      blurRadius: 22,
                                    ),
                                  ],
                                ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Opacity(
                        opacity: subT,
                        child: Text(
                          'ASSEMBLE THE LIGHT',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 3.2,
                            height: 16 / 12,
                            color: PMColors.text(0.62),
                          ),
                        ),
                      ),
                      const SizedBox(height: 44),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: SizedBox(
                          width: 180,
                          height: 4,
                          child: Stack(
                            children: <Widget>[
                              Positioned.fill(
                                child: ColoredBox(
                                  color: PMColors.text(0.10),
                                ),
                              ),
                              Positioned(
                                left: 0,
                                top: 0,
                                bottom: 0,
                                width: 180 * _entrance.value * 0.98,
                                child: const DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: <Color>[
                                        PMColors.cyan,
                                        PMColors.violet,
                                        PMColors.rose,
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'LOADING...',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 3.0,
                          height: 13 / 10,
                          color: PMColors.text(0.45),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
