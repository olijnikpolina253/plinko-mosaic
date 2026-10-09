import 'package:flutter/material.dart';

import '../assets.dart';
import '../theme.dart';

/// Sprite for a colour index. The three PNGs share identical prompt wording
/// except the colour word, so their bounding boxes match and they always
/// render at the same visual size inside a fixed square box.
String nodeSpriteFor(int colorIndex) {
  switch (colorIndex % 3) {
    case 0:
      return AppAssets.nodeCyan;
    case 1:
      return AppAssets.nodeGold;
    default:
      return AppAssets.nodeRose;
  }
}

Color nodeColorFor(int colorIndex) =>
    PMColors.nodeColors[colorIndex % PMColors.nodeColors.length];

/// Triangular glass fragment behind the node sprite.
class ShardPainter extends CustomPainter {
  const ShardPainter({required this.color, required this.flipped});

  final Color color;
  final bool flipped;

  @override
  void paint(Canvas canvas, Size size) {
    final double inset = size.width * 0.12;
    final Path path = Path();
    if (flipped) {
      path.moveTo(size.width - inset, inset);
      path.lineTo(size.width - inset, size.height - inset);
      path.lineTo(inset, size.height - inset);
    } else {
      path.moveTo(inset, inset);
      path.lineTo(size.width - inset, inset);
      path.lineTo(inset, size.height - inset);
    }
    path.close();

    canvas.drawPath(path, Paint()..color = color.withValues(alpha: 0.22));
    canvas.drawPath(
      path,
      Paint()
        ..color = color.withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(ShardPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.flipped != flipped;
}

/// Expanding ring drawn on the tapped node and its two neighbours.
class RipplePainter extends CustomPainter {
  const RipplePainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) {
      return;
    }
    final double radius = size.width * (0.24 + 0.34 * progress);
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      radius,
      Paint()
        ..color = color.withValues(alpha: 0.7 * (1 - progress))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(RipplePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

/// One board cell: plate, shard, sprite, glow and one-shot tap feedback.
class MosaicNode extends StatefulWidget {
  const MosaicNode({
    super.key,
    required this.colorIndex,
    required this.size,
    required this.matched,
    required this.flipped,
    required this.rippleToken,
    required this.highlighted,
    required this.glowBoost,
    required this.dim,
    required this.onTap,
  });

  final int colorIndex;
  final double size;
  final bool matched;
  final bool flipped;

  /// Incremented by the board whenever this cell is part of a resolved tap.
  final int rippleToken;

  /// Hint target marker.
  final bool highlighted;

  /// 0..1 win-bloom contribution, staggered by the board.
  final double glowBoost;

  /// 0..1 loss fade applied to an unmatched cell.
  final double dim;

  final VoidCallback? onTap;

  @override
  State<MosaicNode> createState() => _MosaicNodeState();
}

class _MosaicNodeState extends State<MosaicNode>
    with TickerProviderStateMixin {
  late final AnimationController _ripple = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  );
  late final AnimationController _dip = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 160),
  );

  @override
  void didUpdateWidget(covariant MosaicNode oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rippleToken != widget.rippleToken) {
      _ripple.forward(from: 0);
      _dip.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ripple.dispose();
    _dip.dispose();
    super.dispose();
  }

  double _plateOpacity() {
    final double base = widget.matched ? 1.0 : 0.82;
    final double value = widget.dim.clamp(0.0, 1.0);
    return (base + (0.45 - base) * value).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final Color accent = nodeColorFor(widget.colorIndex);
    final double radius = widget.size * 0.26;
    final double spriteBox = widget.size * 0.62;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: Listenable.merge(<Listenable>[_ripple, _dip]),
        builder: (BuildContext context, Widget? child) {
          final double dip = _dip.value <= 0.5
              ? _dip.value * 2
              : (1 - _dip.value) * 2;
          return Transform.scale(
            scale: 1 - 0.08 * dip,
            child: Opacity(
              opacity: _plateOpacity(),
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  color: PMColors.bgBase.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(radius),
                  border: widget.matched
                      ? Border.all(
                          color: PMColors.cyan.withValues(alpha: 0.70),
                          width: 2,
                        )
                      : (widget.highlighted
                            ? Border.all(
                                color: PMColors.gold.withValues(alpha: 0.85),
                                width: 2,
                              )
                            : Border.all(
                                color: PMColors.text(0.06),
                                width: 2,
                              )),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: accent.withValues(
                        alpha: 0.42 + 0.30 * widget.glowBoost,
                      ),
                      blurRadius:
                          widget.size * (0.28 + 0.32 * widget.glowBoost),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    Positioned.fill(
                      child: CustomPaint(
                        painter: ShardPainter(
                          color: accent,
                          flipped: widget.flipped,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: spriteBox,
                      height: spriteBox,
                      child: Image.asset(
                        nodeSpriteFor(widget.colorIndex),
                        fit: BoxFit.contain,
                        errorBuilder:
                            (
                              BuildContext context,
                              Object error,
                              StackTrace? stack,
                            ) => DecoratedBox(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: accent.withValues(alpha: 0.9),
                              ),
                            ),
                      ),
                    ),
                    Positioned.fill(
                      child: CustomPaint(
                        painter: RipplePainter(
                          progress: _ripple.value,
                          color: accent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
