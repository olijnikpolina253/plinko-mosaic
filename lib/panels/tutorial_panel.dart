import 'dart:async';

import 'package:flutter/material.dart';

import '../game/game_config.dart';
import '../game/level_generator.dart';
import '../theme.dart';
import '../widgets/buttons.dart';
import '../widgets/glass_panel.dart';
import '../widgets/mosaic_board.dart';

/// Full-screen overlay, NOT a member of the screen state machine.
Future<void> showTutorialPanel(BuildContext context) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'HOW IT WORKS',
    barrierColor: PMColors.bgDeep.withValues(alpha: 0.86),
    transitionDuration: const Duration(milliseconds: 260),
    pageBuilder:
        (
          BuildContext context,
          Animation<double> animation,
          Animation<double> secondary,
        ) => const _TutorialPanel(),
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

class _TutorialPanel extends StatefulWidget {
  const _TutorialPanel();

  @override
  State<_TutorialPanel> createState() => _TutorialPanelState();
}

class _TutorialPanelState extends State<_TutorialPanel> {
  static const List<String> _lines = <String>[
    'TAP A NODE TO CYCLE ITS COLOUR.',
    'ITS RIGHT AND LOWER NEIGHBOURS CYCLE TOO.',
    'MATCH THE REFERENCE BEFORE MOVES RUN OUT.',
  ];

  static const List<List<int>> _demoTarget = <List<int>>[
    <int>[0, 1, 2],
    <int>[2, 0, 1],
    <int>[1, 2, 0],
  ];

  final List<List<int>> _demo = <List<int>>[
    <int>[2, 1, 0],
    <int>[2, 0, 1],
    <int>[0, 2, 1],
  ];

  final List<int> _tokens = List<int>.filled(9, 0);
  int? _highlight;
  Timer? _fade;

  @override
  void dispose() {
    _fade?.cancel();
    super.dispose();
  }

  void _tap(int r, int c) {
    setState(() {
      cycleTriple(_demo, 3, r, c, 1);
      for (final int flat in <int>[
        r * 3 + c,
        r * 3 + (c + 1) % 3,
        ((r + 1) % 3) * 3 + c,
      ]) {
        _tokens[flat] = _tokens[flat] + 1;
      }
      _highlight = r * 3 + c;
    });
    _fade?.cancel();
    _fade = Timer(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() => _highlight = null);
      }
    });
  }

  Widget _copyLine(int index, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: PMColors.violet,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                height: 14 / 11,
                color: PMColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.6,
                height: 18 / 13,
                color: PMColors.text(0.78),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const double tile = 72;
    const double boardSize =
        tile * 3 + 2 * GameConfig.tileGap + 2 * GameConfig.boardFrame;

    return Material(
      type: MaterialType.transparency,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 44, 16, 20),
          child: GlassPanel(
            radius: 26,
            fillAlpha: 0.80,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        'HOW IT WORKS',
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
                Expanded(
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: MosaicBoard(
                        state: _demo,
                        target: _demoTarget,
                        cols: 3,
                        metrics: const BoardMetrics(
                          tile: tile,
                          boardSize: boardSize,
                        ),
                        rippleTokens: _tokens,
                        highlightIndex: _highlight,
                        bloom: 0,
                        lossFade: 0,
                        onTapNode: _tap,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                for (int i = 0; i < _lines.length; i++)
                  _copyLine(i, _lines[i]),
                const SizedBox(height: 2),
                SecondaryButton(
                  label: 'GOT IT',
                  icon: Icons.check_rounded,
                  height: 48,
                  onTap: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
