import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../assets.dart';
import '../game/game_config.dart';
import '../game/levels.dart';
import '../game/mosaic_engine.dart';
import '../theme.dart';
import '../widgets/accuracy_ring.dart';
import '../widgets/aurora_backdrop.dart';
import '../widgets/buttons.dart';
import '../widgets/mini_mosaic.dart';
import '../widgets/mosaic_board.dart';

/// Gameplay, archetype G3 split panel: board on top, reference strip, controls.
class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    required this.levelId,
    required this.onGameOver,
    required this.onExit,
  });

  final int levelId;
  final void Function(GameResult result) onGameOver;
  final VoidCallback onExit;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with TickerProviderStateMixin {
  late final MosaicEngine _engine = MosaicEngine(levelById(widget.levelId));
  late final List<int> _tokens = List<int>.filled(
    _engine.cols * _engine.cols,
    0,
  );

  late final AnimationController _bloom = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: GameConfig.winBloomMs),
  );
  late final AnimationController _loss = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: GameConfig.lossFadeMs),
  );

  GamePhase _phase = GamePhase.idle;
  int? _highlight;

  Timer? _resolve;
  Timer? _hintFade;
  Timer? _backstop;
  late final DateTime _mountedAt;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _mountedAt = DateTime.now();
    // Fully passive run: nothing is ever tapped, so the round still has to end.
    _armBackstop(GameConfig.idleBackstopMs);
  }

  @override
  void dispose() {
    _resolve?.cancel();
    _hintFade?.cancel();
    _backstop?.cancel();
    _bloom.dispose();
    _loss.dispose();
    super.dispose();
  }

  void _armBackstop(int milliseconds) {
    _backstop?.cancel();
    _backstop = Timer(Duration(milliseconds: milliseconds), _onBackstop);
  }

  /// After the first interaction a short window is enough — but never before
  /// the capture agent has had time to photograph the board.
  void _armEngagedBackstop() {
    final int sinceMount = DateTime.now().difference(_mountedAt).inMilliseconds;
    _armBackstop(
      math.max(
        GameConfig.engagedBackstopMs,
        GameConfig.minMsFromMount - sinceMount,
      ),
    );
  }

  void _onBackstop() {
    if (!mounted || _phase != GamePhase.idle) {
      return;
    }
    _lose();
  }

  void _finish(bool won) {
    if (_finished || !mounted) {
      return;
    }
    _finished = true;
    widget.onGameOver(_engine.buildResult(won: won));
  }

  void _win() {
    _backstop?.cancel();
    setState(() => _phase = GamePhase.won);
    _bloom.forward(from: 0).whenComplete(() => _finish(true));
  }

  void _lose() {
    _backstop?.cancel();
    setState(() => _phase = GamePhase.lost);
    _loss.forward(from: 0).whenComplete(() => _finish(false));
  }

  void _onTapNode(int r, int c) {
    if (_phase != GamePhase.idle || !_engine.canTap) {
      return;
    }
    setState(() {
      for (final int flat in _engine.tap(r, c)) {
        _tokens[flat] = _tokens[flat] + 1;
      }
      _highlight = null;
      _phase = GamePhase.resolving;
    });
    _armEngagedBackstop();

    _resolve?.cancel();
    _resolve = Timer(
      const Duration(milliseconds: GameConfig.resolveMs),
      () {
        if (!mounted) {
          return;
        }
        if (_engine.solved) {
          _win();
        } else if (_engine.movesLeft <= 0) {
          _lose();
        } else {
          setState(() => _phase = GamePhase.idle);
        }
      },
    );
  }

  void _onHint() {
    if (_phase != GamePhase.idle) {
      return;
    }
    final int? index = _engine.useHint();
    if (index == null) {
      return;
    }
    setState(() => _highlight = index);
    _armEngagedBackstop();
    _hintFade?.cancel();
    _hintFade = Timer(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() => _highlight = null);
      }
    });
  }

  void _onReset() {
    if (_phase != GamePhase.idle && _phase != GamePhase.resolving) {
      return;
    }
    _resolve?.cancel();
    _hintFade?.cancel();
    setState(() {
      _engine.reset();
      for (int i = 0; i < _tokens.length; i++) {
        _tokens[i] = _tokens[i] + 1;
      }
      _highlight = null;
      _phase = GamePhase.idle;
    });
    _armEngagedBackstop();
  }

  Widget _header(BuildContext context) {
    final bool urgent = _engine.movesLeft <= 2;
    return Container(
      height: 116,
      padding: const EdgeInsets.only(top: 44, left: 4, right: 12),
      decoration: BoxDecoration(
        color: PMColors.bgBase.withValues(alpha: 0.45),
        border: Border(
          bottom: BorderSide(color: PMColors.text(0.08), width: 1),
        ),
      ),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 48,
            height: 48,
            child: IconButton(
              onPressed: widget.onExit,
              icon: const Icon(
                Icons.arrow_back_rounded,
                size: 24,
                color: PMColors.textPrimary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'LEVEL ${widget.levelId.toString().padLeft(2, '0')}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                letterSpacing: 2.2,
                height: 18 / 15,
                color: PMColors.textPrimary,
                fontFeatures: kTabularFigures,
              ),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  height: 24 / 20,
                  color: urgent ? PMColors.rose : PMColors.gold,
                  fontFeatures: kTabularFigures,
                ),
                child: Text('${_engine.movesLeft}'),
              ),
              Text(
                'MOVES',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.6,
                  height: 12 / 9,
                  color: PMColors.text(0.55),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _targetStrip() {
    final int cols = _engine.cols;
    final double cell = math.max(
      6.0,
      ((56 - (cols - 1) * 3) / cols).floorToDouble(),
    );
    return Container(
      height: 96,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: PMColors.surface.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: PMColors.text(0.08), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'REFERENCE',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.8,
                  height: 12 / 9,
                  color: PMColors.text(0.55),
                ),
              ),
              const SizedBox(height: 3),
              MiniMosaic(matrix: _engine.target, cell: cell, gap: 3),
            ],
          ),
          AccuracyRing(value: _engine.accuracy),
        ],
      ),
    );
  }

  Widget _controls() {
    final bool interactive = _phase == GamePhase.idle;
    return Container(
      height: 150,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: PMColors.bgBase.withValues(alpha: 0.72),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        border: Border(
          top: BorderSide(color: PMColors.text(0.08), width: 1),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            'TAP A NODE · IT AND TWO NEIGHBOURS SHIFT',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.4,
              height: 13 / 10,
              color: PMColors.text(0.48),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: SecondaryButton(
                  label: 'HINT',
                  icon: Icons.lightbulb_outline_rounded,
                  borderColor: PMColors.gold,
                  onTap: interactive && _engine.canHint ? _onHint : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SecondaryButton(
                  label: 'RESET',
                  icon: Icons.refresh_rounded,
                  borderColor: PMColors.rose,
                  onTap: interactive ? _onReset : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuroraBackdrop(
      image: const DecorationImage(
        image: AssetImage(AppAssets.bgGame),
        fit: BoxFit.cover,
      ),
      overlay: <Color>[
        PMColors.bgBase.withValues(alpha: 0.86),
        PMColors.bgBase.withValues(alpha: 0.94),
      ],
      child: SafeArea(
        top: false,
        child: Column(
          children: <Widget>[
            _header(context),
            Expanded(
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final BoardMetrics metrics = BoardMetrics.forExtent(
                    math.min(constraints.maxWidth, constraints.maxHeight),
                    _engine.cols,
                  );
                  return Center(
                    child: AnimatedBuilder(
                      animation: Listenable.merge(<Listenable>[_bloom, _loss]),
                      builder: (BuildContext context, Widget? child) {
                        return MosaicBoard(
                          state: _engine.board,
                          target: _engine.target,
                          cols: _engine.cols,
                          metrics: metrics,
                          rippleTokens: _tokens,
                          highlightIndex: _highlight,
                          bloom: _bloom.value,
                          lossFade: _loss.value,
                          onTapNode:
                              _phase == GamePhase.idle ? _onTapNode : null,
                        );
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            _targetStrip(),
            const SizedBox(height: 12),
            _controls(),
          ],
        ),
      ),
    );
  }
}
