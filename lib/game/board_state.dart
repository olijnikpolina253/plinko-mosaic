/// A grid of colour indices plus the single legal move of the game.
///
/// Tapping `(r, c)` advances the node itself, its right neighbour and its
/// lower neighbour by one colour, wrapping on both axes so every node has
/// identical influence.
class BoardState {
  BoardState({
    required this.cols,
    required this.rows,
    required this.colourCount,
    required List<int> cells,
  }) : cells = List<int>.of(cells);

  BoardState.filled({
    required this.cols,
    required this.rows,
    required this.colourCount,
  }) : cells = List<int>.filled(cols * rows, 0, growable: true);

  final int cols;
  final int rows;
  final int colourCount;

  /// Always a growable copy — a const literal would throw on the first tap.
  final List<int> cells;

  int get cellCount => cols * rows;

  int indexOf(int r, int c) => r * cols + c;

  int colourAt(int r, int c) => cells[indexOf(r, c)];

  void setColour(int r, int c, int value) {
    cells[indexOf(r, c)] = value % colourCount;
  }

  /// The one legal move. Deterministic and toroidal.
  void applyTap(int r, int c) {
    _bump(r, c);
    _bump(r, (c + 1) % cols);
    _bump((r + 1) % rows, c);
  }

  void applyTapIndex(int index) {
    applyTap(index ~/ cols, index % cols);
  }

  void _bump(int r, int c) {
    final int i = indexOf(r, c);
    cells[i] = (cells[i] + 1) % colourCount;
  }

  int matchedCount(BoardState target) {
    int matched = 0;
    for (int i = 0; i < cells.length; i++) {
      if (cells[i] == target.cells[i]) matched++;
    }
    return matched;
  }

  bool matchesAt(BoardState target, int r, int c) {
    final int i = indexOf(r, c);
    return cells[i] == target.cells[i];
  }

  bool equalsTarget(BoardState target) =>
      matchedCount(target) == cells.length;

  BoardState copy() => BoardState(
        cols: cols,
        rows: rows,
        colourCount: colourCount,
        cells: cells,
      );
}
