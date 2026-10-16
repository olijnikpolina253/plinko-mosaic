import 'package:flutter/material.dart';

import '../assets.dart';
import '../game/board_state.dart';
import '../theme.dart';
import '../widgets/aurora_painter.dart';
import '../widgets/cta_buttons.dart';
import '../widgets/mosaic_board.dart';
import '../widgets/stat_card.dart';

/// Full-screen rules panel with a live three-by-three demonstration of how one
/// tap recolours three nodes. No PLAY/START literal lives on this panel.
class TutorialPanel extends StatefulWidget {
  const TutorialPanel({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  State<TutorialPanel> createState() => _TutorialPanelState();
}

class _TutorialPanelState extends State<TutorialPanel> {
  static const int _demoSize = 3;
  static const List<int> _demoSeed = <int>[0, 1, 2, 2, 0, 1, 1, 2, 0];

  late BoardState _demo;

  @override
  void initState() {
    super.initState();
    _demo = _freshDemo();
  }

  BoardState _freshDemo() => BoardState(
        cols: _demoSize,
        rows: _demoSize,
        colourCount: 3,
        cells: _demoSeed,
      );

  void _tapDemo(int r, int c) {
    setState(() => _demo.applyTap(r, c));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: Opacity(
              opacity: 0.30,
              child: Image.asset(AppAssets.bgGame, fit: BoxFit.cover),
            ),
          ),
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[Color(0xEE1A2142), Color(0xFA0B1026)],
                ),
              ),
            ),
          ),
          const Positioned.fill(
            child: CustomPaint(
              painter: AuroraPainter(<AuroraBlob>[
                AuroraBlob(
                  dx: 0.80,
                  dy: 0.22,
                  radius: 140,
                  color: Color(0x2E4B38A2),
                ),
                AuroraBlob(
                  dx: 0.16,
                  dy: 0.80,
                  radius: 130,
                  color: Color(0x1FF2C94C),
                ),
              ]),
            ),
          ),
          SafeArea(
            top: false,
            child: Column(
              children: <Widget>[
                _header(),
                Expanded(child: _body()),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                  child: PrimaryCta(
                    label: 'BACK TO MENU',
                    icon: Icons.home_rounded,
                    height: 56,
                    onTap: widget.onBack,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _header() {
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
                onTap: widget.onBack,
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
              'GAME RULES',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.6,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 44),
        ],
      ),
    );
  }

  Widget _body() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
      physics: const BouncingScrollPhysics(),
      children: <Widget>[
        Center(
          child: MosaicBoard(
            state: _demo,
            target: _demo,
            tile: 64,
            detail: BoardDetail.rich,
            showMatches: false,
            highlightIndex: 4,
            onTapCell: _tapDemo,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'TAP THE MARKED NODE',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.0,
            color: AppColors.gold,
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: SizedBox(
            width: 180,
            child: SecondaryCta(
              label: 'RESET DEMO',
              icon: Icons.refresh_rounded,
              accent: AppColors.rose,
              onTap: () => setState(() => _demo = _freshDemo()),
            ),
          ),
        ),
        const SizedBox(height: 18),
        _ruleCard(
          Icons.touch_app_rounded,
          'ONE TAP, THREE NODES',
          'The node you press and its right and lower neighbours all step to '
              'the next colour. Edges wrap around to the opposite side.',
        ),
        const SizedBox(height: 12),
        _ruleCard(
          Icons.grid_view_rounded,
          'MATCH THE TARGET',
          'The small pattern above the board is the goal. Every cell must '
              'match it before the moves run out.',
        ),
        const SizedBox(height: 12),
        _ruleCard(
          Icons.bolt_rounded,
          'MOVES ARE LIMITED',
          'Run out of moves and the round ends. Finishing under par earns '
              'three stars.',
        ),
      ],
    );
  }

  Widget _ruleCard(IconData icon, String title, String body) {
    return GlassPanel(
      radius: 18,
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.cyan.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 22, color: AppColors.cyan),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  body,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
