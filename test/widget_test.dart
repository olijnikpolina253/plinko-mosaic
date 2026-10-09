import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:plinko_mosaic/game/levels.dart';
import 'package:plinko_mosaic/game/mosaic_engine.dart';
import 'package:plinko_mosaic/theme.dart';
import 'package:plinko_mosaic/widgets/stat_card.dart';

void main() {
  test('preset identity stays SPACE_COSMOS', () {
    expect(pmPreset.name, 'SPACE_COSMOS');
  });

  test('every level is solvable by replaying its stored residual', () {
    for (final LevelDef level in kLevels) {
      final MosaicEngine engine = MosaicEngine(level);

      expect(engine.minMoves, greaterThan(0), reason: 'level ${level.id}');
      expect(engine.movesAllowed, greaterThanOrEqualTo(engine.minMoves));
      expect(engine.solved, isFalse, reason: 'level ${level.id} starts solved');

      int guard = 0;
      while (!engine.solved && guard < 64) {
        final int? index = engine.hintIndex;
        expect(index, isNotNull, reason: 'level ${level.id} ran out of hints');
        engine.tap(index! ~/ engine.cols, index % engine.cols);
        guard++;
      }

      expect(engine.solved, isTrue, reason: 'level ${level.id} unsolved');
      expect(engine.accuracyPercent, 100);
      expect(engine.movesUsed, lessThanOrEqualTo(engine.movesAllowed));
      expect(engine.stars, greaterThan(0));
    }
  });

  test('a tap cycles the node and its two wrapping neighbours', () {
    final MosaicEngine engine = MosaicEngine(kLevels.first);
    final List<List<int>> before = engine.board
        .map((List<int> row) => List<int>.from(row))
        .toList();

    engine.tap(0, 0);

    int changed = 0;
    for (int r = 0; r < engine.cols; r++) {
      for (int c = 0; c < engine.cols; c++) {
        if (before[r][c] != engine.board[r][c]) {
          changed++;
        }
      }
    }
    expect(changed, 3);
    expect(engine.movesUsed, 1);
  });

  testWidgets('StatCard shows the value and an uppercase caption', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: StatCard(
              value: '92%',
              label: 'accuracy',
              valueColor: PMColors.cyan,
            ),
          ),
        ),
      ),
    );

    expect(find.text('92%'), findsOneWidget);
    expect(find.text('ACCURACY'), findsOneWidget);
  });

  testWidgets('StarRow always renders three stars', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: StarRow(earned: 2))),
      ),
    );

    expect(find.byIcon(Icons.star_rounded), findsNWidgets(3));
  });
}
