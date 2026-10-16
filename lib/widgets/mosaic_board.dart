import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../assets.dart';
import '../game/board_state.dart';
import '../game/game_config.dart';
import '../theme.dart';

/// How much machinery a board instance deserves.
///
/// * [rich] — the playable board and the tutorial demo: generated sprites,
///   colour cross-fades and the tap pulse.
/// * [flat] — target strip and result previews: painted shards only.
/// * [mini] — gallery thumbnails: the whole grid in one painter.
enum BoardDetail { rich, flat, mini }

/// The single board widget, reused at every size in the app.
class MosaicBoard extends StatelessWidget {
  const MosaicBoard({
    super.key,
    required this.state,
    required this.target,
    required this.tile,
    this.detail = BoardDetail.flat,
    this.onTapCell,
    this.radius = GameConfig.boardRadius,
    this.borderColor,
    this.showMatches = true,
    this.highlightIndex,
  });

  final BoardState state;
  final BoardState target;
  final double tile;
  final BoardDetail detail;
  final void Function(int r, int c)? onTapCell;
  final double radius;
  final Color? borderColor;
  final bool showMatches;

  /// Index of a cell to outline (the tutorial points at one node).
  final int? highlightIndex;

  double get _width => GameConfig.boardSideFor(tile, state.cols);

  double get _height => GameConfig.boardSideFor(tile, state.rows);

  @override
  Widget build(BuildContext context) {
    final double innerRadius = math.max(2, radius - GameConfig.boardFrame);
    return Container(
      width: _width,
      height: _height,
      padding: const EdgeInsets.all(GameConfig.boardPadding),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: borderColor ?? AppColors.cyan.withValues(alpha: 0.28),
          width: GameConfig.boardBorder,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.violet.withValues(alpha: 0.40),
            blurRadius: 34,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(innerRadius),
        child: detail == BoardDetail.mini ? _buildMini() : _buildGrid(),
      ),
    );
  }

  Widget _buildMini() {
    return CustomPaint(
      size: Size(tile * state.cols, tile * state.rows),
      painter: _MiniBoardPainter(
        cells: List<int>.of(state.cells),
        cols: state.cols,
        rows: state.rows,
        tile: tile,
      ),
    );
  }

  Widget _buildGrid() {
    final List<Widget> rowWidgets = <Widget>[];
    for (int r = 0; r < state.rows; r++) {
      final List<Widget> cells = <Widget>[];
      for (int c = 0; c < state.cols; c++) {
        final int index = state.indexOf(r, c);
        final bool matched = showMatches && state.matchesAt(target, r, c);
        final Widget cell = detail == BoardDetail.rich
            ? MosaicCell(
                key: ValueKey<int>(index),
                colourIndex: state.cells[index],
                matched: matched,
                size: tile,
                highlighted: highlightIndex == index,
              )
            : _FlatCell(
                colourIndex: state.cells[index],
                matched: matched,
                size: tile,
              );
        cells.add(
          onTapCell == null
              ? cell
              : SizedBox(
                  width: tile,
                  height: tile,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => onTapCell!(r, c),
                    child: cell,
                  ),
                ),
        );
      }
      rowWidgets.add(Row(mainAxisSize: MainAxisSize.min, children: cells));
    }

    final Widget grid = Column(
      mainAxisSize: MainAxisSize.min,
      children: rowWidgets,
    );

    return onTapCell == null
        ? grid
        : Material(color: Colors.transparent, child: grid);
  }
}

/// Cheap cell: painted shards plus the node dot. No images, no animation.
class _FlatCell extends StatelessWidget {
  const _FlatCell({
    required this.colourIndex,
    required this.matched,
    required this.size,
  });

  final int colourIndex;
  final bool matched;
  final double size;

  @override
  Widget build(BuildContext context) {
    final Color colour = GameConfig.colourRamp[colourIndex];
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: <Widget>[
          Positioned.fill(child: CustomPaint(painter: ShardPainter(colour))),
          Center(child: _NodeDot(colour: colour, diameter: size * 0.46)),
          if (matched && size >= 26)
            Positioned(
              top: 6,
              right: 6,
              child: _MatchDiamond(size: math.min(10, size * 0.18)),
            ),
        ],
      ),
    );
  }
}

/// Playable cell: generated shard texture, glow sprite, node dot, match marker.
/// A colour change cross-fades over 220ms and pulses the cell over 260ms.
class MosaicCell extends StatefulWidget {
  const MosaicCell({
    super.key,
    required this.colourIndex,
    required this.matched,
    required this.size,
    this.highlighted = false,
  });

  final int colourIndex;
  final bool matched;
  final double size;
  final bool highlighted;

  @override
  State<MosaicCell> createState() => _MosaicCellState();
}

class _MosaicCellState extends State<MosaicCell>
    with SingleTickerProviderStateMixin {
  static const double _colourPhase = 220 / 260;

  late final AnimationController _controller;
  late Color _from;
  late Color _to;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _from = GameConfig.colourRamp[widget.colourIndex];
    _to = _from;
  }

  @override
  void didUpdateWidget(MosaicCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.colourIndex != widget.colourIndex) {
      _from = GameConfig.colourRamp[oldWidget.colourIndex];
      _to = GameConfig.colourRamp[widget.colourIndex];
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        final double t = _controller.value;
        final double mix = (t / _colourPhase).clamp(0.0, 1.0);
        final Color colour = Color.lerp(_from, _to, mix) ?? _to;
        final double scale = 1 + 0.08 * math.sin(t * math.pi);
        return Transform.scale(
          scale: scale,
          child: _cell(colour),
        );
      },
    );
  }

  Widget _cell(Color colour) {
    final double size = widget.size;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: <Widget>[
          Positioned.fill(child: CustomPaint(painter: ShardPainter(colour))),
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Opacity(
                opacity: 0.22,
                child: ColorFiltered(
                  colorFilter: ColorFilter.mode(colour, BlendMode.modulate),
                  child: Image.asset(
                    AppAssets.spriteShardTriangle,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
          Center(
            child: AnimatedOpacity(
              opacity: widget.matched ? 0.55 : 0.18,
              duration: const Duration(milliseconds: 260),
              child: ColorFiltered(
                colorFilter: ColorFilter.mode(colour, BlendMode.srcATop),
                child: Image.asset(
                  AppAssets.spriteNodeGlow,
                  width: size * 0.92,
                  height: size * 0.92,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          Center(child: _NodeDot(colour: colour, diameter: size * 0.46)),
          if (widget.highlighted)
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(3),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.gold, width: 2),
                  ),
                ),
              ),
            ),
          Positioned(
            top: 6,
            right: 6,
            child: AnimatedScale(
              scale: widget.matched ? 1 : 0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutBack,
              child: const _MatchDiamond(size: 10),
            ),
          ),
        ],
      ),
    );
  }
}

class _NodeDot extends StatelessWidget {
  const _NodeDot({required this.colour, required this.diameter});

  final Color colour;
  final double diameter;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.bgDeep.withValues(alpha: 0.35),
          width: diameter > 18 ? 1.5 : 0.8,
        ),
        gradient: RadialGradient(
          colors: <Color>[
            AppColors.textPrimary.withValues(alpha: 0.95),
            colour,
          ],
          stops: const <double>[0.0, 1.0],
        ),
      ),
    );
  }
}

class _MatchDiamond extends StatelessWidget {
  const _MatchDiamond({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: math.pi / 4,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.textPrimary.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(1.5),
        ),
      ),
    );
  }
}

/// Splits a cell on the main diagonal: the upper-left triangle carries the raw
/// colour, the lower-right a lightened copy, with a dark seam between them.
class ShardPainter extends CustomPainter {
  const ShardPainter(this.colour);

  final Color colour;

  @override
  void paint(Canvas canvas, Size size) {
    const double inset = 2;
    final double w = size.width - inset * 2;
    final double h = size.height - inset * 2;
    if (w <= 0 || h <= 0) return;

    final Offset tl = const Offset(inset, inset);
    final Offset tr = Offset(inset + w, inset);
    final Offset br = Offset(inset + w, inset + h);
    final Offset bl = Offset(inset, inset + h);

    final Path upper = Path()
      ..moveTo(tl.dx, tl.dy)
      ..lineTo(tr.dx, tr.dy)
      ..lineTo(bl.dx, bl.dy)
      ..close();
    final Path lower = Path()
      ..moveTo(tr.dx, tr.dy)
      ..lineTo(br.dx, br.dy)
      ..lineTo(bl.dx, bl.dy)
      ..close();

    canvas.drawPath(
      upper,
      Paint()..color = colour.withValues(alpha: 0.92),
    );
    canvas.drawPath(
      lower,
      Paint()
        ..color = Color.lerp(colour, AppColors.textPrimary, 0.18) ?? colour,
    );
    canvas.drawLine(
      tr,
      bl,
      Paint()
        ..color = AppColors.bgDeep.withValues(alpha: 0.55)
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(ShardPainter oldDelegate) => oldDelegate.colour != colour;
}

/// Whole-grid thumbnail in a single painter — used for the 12 gallery tiles.
class _MiniBoardPainter extends CustomPainter {
  const _MiniBoardPainter({
    required this.cells,
    required this.cols,
    required this.rows,
    required this.tile,
  });

  final List<int> cells;
  final int cols;
  final int rows;
  final double tile;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint();
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final Color colour = GameConfig.colourRamp[cells[r * cols + c]];
        final Rect rect = Rect.fromLTWH(
          c * tile + 0.5,
          r * tile + 0.5,
          tile - 1,
          tile - 1,
        );
        paint.color = colour.withValues(alpha: 0.92);
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(2)),
          paint,
        );
        paint.color = AppColors.textPrimary.withValues(alpha: 0.55);
        canvas.drawCircle(rect.center, tile * 0.18, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_MiniBoardPainter oldDelegate) =>
      oldDelegate.tile != tile ||
      !_sameCells(oldDelegate.cells, cells);

  static bool _sameCells(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
