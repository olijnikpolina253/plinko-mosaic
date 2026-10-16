// Smoke tests for PlinkoMosaic: the puzzle stays solvable and the shared
// StatCard renders its value and caption.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:plinko_mosaic/game/board_state.dart';
import 'package:plinko_mosaic/game/game_config.dart';
import 'package:plinko_mosaic/game/level_generator.dart';
import 'package:plinko_mosaic/game/round_result.dart';
import 'package:plinko_mosaic/theme.dart';
import 'package:plinko_mosaic/widgets/stat_card.dart';

void main() {
  test('a tap recolours exactly three nodes and the board stays mutable', () {
    final BoardState board = BoardState(
      cols: 4,
      rows: 4,
      colourCount: 3,
      cells: const <int>[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    );
    board.applyTap(1, 1);
    expect(board.cells.where((int c) => c != 0).length, 3);
    expect(board.colourAt(1, 1), 1);
    expect(board.colourAt(1, 2), 1);
    expect(board.colourAt(2, 1), 1);
  });

  test('taps wrap around both edges', () {
    final BoardState board = BoardState(
      cols: 4,
      rows: 4,
      colourCount: 3,
      cells: List<int>.filled(16, 0),
    );
    board.applyTap(3, 3);
    expect(board.colourAt(3, 3), 1);
    expect(board.colourAt(3, 0), 1);
    expect(board.colourAt(0, 3), 1);
  });

  test('every level is solvable inside its move limit', () {
    for (int level = 1; level <= GameConfig.totalLevels; level++) {
      final LevelSpec spec = LevelGenerator.build(level);
      expect(
        spec.start.equalsTarget(spec.target),
        isFalse,
        reason: 'level $level starts already solved',
      );
      expect(
        spec.moveLimit >= spec.parMoves,
        isTrue,
        reason: 'level $level cannot be finished',
      );

      // Replay the undo sequence and confirm it really lands on the target.
      final BoardState working = spec.start.copy();
      int moves = 0;
      for (int node = 0; node < spec.undoTaps.length; node++) {
        for (int k = 0; k < spec.undoTaps[node]; k++) {
          working.applyTapIndex(node);
          moves++;
        }
      }
      expect(
        working.equalsTarget(spec.target),
        isTrue,
        reason: 'level $level is not solvable by its own inverse',
      );
      expect(moves, spec.parMoves);
      expect(moves <= spec.moveLimit, isTrue,
          reason: 'level $level overshot its budget');
    }
  });

  test('stars follow the move budget', () {
    expect(RoundResult.starsFor(win: true, movesUsed: 5, parMoves: 5), 3);
    expect(RoundResult.starsFor(win: true, movesUsed: 7, parMoves: 5), 2);
    expect(RoundResult.starsFor(win: true, movesUsed: 9, parMoves: 5), 1);
    expect(RoundResult.starsFor(win: false, movesUsed: 1, parMoves: 5), 0);
  });

  testWidgets('StatCard shows its value and uppercase caption',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.build(),
        home: const Scaffold(
          body: Center(
            child: StatCard(
              value: '68%',
              label: 'accuracy',
              valueColor: AppColors.cyan,
            ),
          ),
        ),
      ),
    );

    expect(find.text('68%'), findsOneWidget);
    expect(find.text('ACCURACY'), findsOneWidget);
  });
}
