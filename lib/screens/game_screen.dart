import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../assets.dart';
import '../game/board_state.dart';
import '../game/game_config.dart';
import '../game/level_generator.dart';
import '../game/round_result.dart';
import '../theme.dart';
import '../widgets/accuracy_ring.dart';
import '../widgets/mosaic_board.dart';

enum RoundState { idle, playing, resolved }

/// Archetype G2: the board owns the whole area, the controls float above it.
class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    required this.level,
    required this.onRoundOver,
    required this.onBack,
  });

  final int level;
  final void Function(RoundResult result) onRoundOver;
  final VoidCallback onBack;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late LevelSpec _spec;
  late BoardState _board;

  RoundState _state = RoundState.idle;
  int _movesUsed = 0;

  Timer? _idleBackstop;
  Timer? _engagedBackstop;
  Timer? _exit;

  @override
  void initState() {
    super.initState();
    _spec = LevelGenerator.build(widget.level);
    _board = _spec.start.copy();

    // Armed exactly once. A puzzle has no clock of its own, so an untouched
    // round must still reach a result.
    _idleBackstop = Timer(
      const Duration(milliseconds: GameConfig.idleBackstopMs),
      () => _resolve(false),
    );
  }

  @override
  void dispose() {
    _idleBackstop?.cancel();
    _engagedBackstop?.cancel();
    _exit?.cancel();
    super.dispose();
  }

  int get _movesLeft => math.max(0, _spec.moveLimit - _movesUsed);

  int get _matched => _board.matchedCount(_spec.target);

  double get _accuracy => _matched / _board.cellCount;

  void _onCellTap(int r, int c) {
    if (_state == RoundState.resolved) return;

    final bool firstTap = _state == RoundState.idle;
    setState(() {
      _board.applyTap(r, c);
      _movesUsed++;
      _state = RoundState.playing;
    });

    if (firstTap) {
      // Armed exactly once, never re-armed, cancelled by a natural finish.
      _engagedBackstop = Timer(
        const Duration(milliseconds: GameConfig.engagedBackstopMs),
        () => _resolve(_board.equalsTarget(_spec.target)),
      );
    }

    if (_board.equalsTarget(_spec.target)) {
      _resolve(true);
    } else if (_movesLeft <= 0) {
      _resolve(false);
    }
  }

  void _reset() {
    if (_state == RoundState.resolved) return;
    setState(() {
      _board = _spec.start.copy();
      _movesUsed = 0;
      _state = RoundState.idle;
    });
  }

  void _resolve(bool win) {
    if (!mounted || _state == RoundState.resolved) return;
    _idleBackstop?.cancel();
    _engagedBackstop?.cancel();
    setState(() => _state = RoundState.resolved);

    final RoundResult result = RoundResult(
      level: _spec.level,
      win: win,
      accuracy: (_accuracy * 100).round(),
      matched: _matched,
      cellCount: _board.cellCount,
      movesUsed: _movesUsed,
      moveLimit: _spec.moveLimit,
      parMoves: _spec.parMoves,
      stars: RoundResult.starsFor(
        win: win,
        movesUsed: _movesUsed,
        parMoves: _spec.parMoves,
      ),
      finalBoard: _board.copy(),
      target: _spec.target.copy(),
    );

    _exit = Timer(const Duration(milliseconds: 420), () {
      if (!mounted) return;
      widget.onRoundOver(result);
    });
  }

  @override
  Widget build(BuildContext context) {
    final MediaQueryData media = MediaQuery.of(context);
    final double safeBottom = media.padding.bottom;
    final double controlReserve = 84 + 24 + safeBottom + 12;

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: Image.asset(AppAssets.bgGame, fit: BoxFit.cover),
          ),
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[Color(0xD111162D), Color(0xE60B1026)],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: AnimatedOpacity(
              opacity: _state == RoundState.resolved ? 0.35 : 1.0,
              duration: const Duration(milliseconds: 420),
              child: SafeArea(
                top: false,
                bottom: false,
                child: Column(
                  children: <Widget>[
                    _header(),
                    _targetStrip(),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          left: 16,
                          right: 16,
                          top: 10,
                          bottom: controlReserve,
                        ),
                        child: _boardArea(media.size.width),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 24 + safeBottom,
            child: _controlBar(),
          ),
        ],
      ),
    );
  }

  Widget _header() {
    final bool low = _movesLeft <= 2;
    return Container(
      padding: const EdgeInsets.only(top: 44, left: 16, right: 16, bottom: 12),
      decoration: const BoxDecoration(
        color: Color(0x8C0B1026),
        border: Border(bottom: BorderSide(color: Color(0x14F7F2E9))),
      ),
      child: Row(
        children: <Widget>[
          _iconButton(
            icon: Icons.arrow_back_rounded,
            onTap: widget.onBack,
            semantic: 'BACK',
          ),
          Expanded(
            child: Column(
              children: <Widget>[
                Text(
                  'LEVEL ${_spec.level}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.6,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'GRID ${_spec.cols}x${_spec.rows} · '
                  '${_spec.colourCount} COLOURS',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.0,
                    color: AppColors.textCaption,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 76,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.violet.withValues(alpha: 0.30),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.cyan.withValues(alpha: 0.40),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Icon(
                  Icons.touch_app_rounded,
                  size: 16,
                  color: AppColors.cyan,
                ),
                const SizedBox(width: 6),
                _animatedNumber(
                  '$_movesLeft',
                  TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: low ? AppColors.rose : AppColors.textPrimary,
                    fontFeatures: AppTheme.tabular,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconButton({
    required IconData icon,
    required VoidCallback onTap,
    required String semantic,
  }) {
    return Semantics(
      button: true,
      label: semantic,
      child: Material(
        color: AppColors.textPrimary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.textPrimary.withValues(alpha: 0.12),
              ),
            ),
            child: Icon(icon, size: 22, color: AppColors.textPrimary),
          ),
        ),
      ),
    );
  }

  Widget _targetStrip() {
    // The strip is a fixed 112px band; the miniature has to fit the 94px that
    // remain after its own padding, frame included.
    const double stripInner = 112 - 9 * 2;
    final int n = math.max(_spec.cols, _spec.rows);
    final double miniTile = GameConfig.tileFor(stripInner, n);

    return Container(
      height: 112,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      child: Row(
        children: <Widget>[
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  'TARGET',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.4,
                    color: AppColors.textCaption,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'MATCH IT',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: AppColors.gold,
                  ),
                ),
              ],
            ),
          ),
          MosaicBoard(
            state: _spec.target,
            target: _spec.target,
            tile: miniTile,
            radius: 16,
            showMatches: false,
            borderColor: AppColors.cyan.withValues(alpha: 0.22),
          ),
          const SizedBox(width: 14),
          AccuracyRing(value: _accuracy),
        ],
      ),
    );
  }

  Widget _boardArea(double screenWidth) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final int n = math.max(_spec.cols, _spec.rows);
        final double widthBudget = GameConfig.boardMaxWidth(screenWidth);
        final double budget = math.min(
          widthBudget,
          math.min(constraints.maxWidth, constraints.maxHeight),
        );
        final double tile = GameConfig.tileFor(budget, n);
        return Center(
          child: MosaicBoard(
            state: _board,
            target: _spec.target,
            tile: tile,
            detail: BoardDetail.rich,
            onTapCell: _state == RoundState.resolved ? null : _onCellTap,
          ),
        );
      },
    );
  }

  Widget _controlBar() {
    return Container(
      height: 84,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: AppColors.textPrimary.withValues(alpha: 0.10),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.bgDeep.withValues(alpha: 0.55),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: _barStat(
              'MOVES LEFT',
              '$_movesLeft',
              AppColors.cyan,
            ),
          ),
          Expanded(
            child: _barStat(
              'MATCHED',
              '$_matched/${_board.cellCount}',
              AppColors.gold,
            ),
          ),
          _resetButton(),
        ],
      ),
    );
  }

  Widget _barStat(String label, String value, Color colour) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: AppColors.textCaption,
          ),
        ),
        const SizedBox(height: 4),
        _animatedNumber(
          value,
          TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: colour,
            fontFeatures: AppTheme.tabular,
          ),
        ),
      ],
    );
  }

  Widget _animatedNumber(String value, TextStyle style) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.35),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: Text(
        value,
        key: ValueKey<String>('${style.color}-$value'),
        style: style,
      ),
    );
  }

  Widget _resetButton() {
    return Semantics(
      button: true,
      label: 'RESET',
      child: Material(
        color: AppColors.rose.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: _reset,
          child: Container(
            width: 100,
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppColors.rose.withValues(alpha: 0.55),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(Icons.refresh_rounded, size: 24, color: AppColors.rose),
                SizedBox(width: 6),
                Text(
                  'RESET',
                  style: TextStyle(
                    fontSize: 13,
                    height: 24 / 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
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
