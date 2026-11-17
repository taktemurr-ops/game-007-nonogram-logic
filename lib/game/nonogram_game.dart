import 'dart:convert';

/// Each square can be undecided, filled, or crossed off.
enum CellMark { unknown, filled, empty }

List<int> cluesForLine(List<bool> cells) {
  final runs = <int>[];
  var count = 0;
  for (final filled in cells) {
    if (filled) {
      count++;
    } else if (count != 0) {
      runs.add(count);
      count = 0;
    }
  }
  if (count != 0) runs.add(count);
  return runs.isEmpty ? <int>[0] : runs;
}

class NonogramPuzzle {
  NonogramPuzzle(List<List<bool>> board)
      : solution = _validated(board).map((r) => List<bool>.unmodifiable(r)).toList(),
        marks = List.generate(
          board.length,
          (_) => List<CellMark>.filled(board.first.length, CellMark.unknown),
        );

  static List<List<bool>> _validated(List<List<bool>> board) {
    if (board.isEmpty || board.first.isEmpty ||
        board.length > 20 || board.first.length > 20 ||
        board.any((row) => row.length != board.first.length)) {
      throw ArgumentError('A nonogram must be rectangular and 1–20 cells wide/high.');
    }
    return board;
  }

  final List<List<bool>> solution;
  final List<List<CellMark>> marks;
  final List<String> _undo = [];
  final List<String> _redo = [];
  int hintsUsed = 0;
  int taps = 0;

  int get height => solution.length;
  int get width => solution.first.length;
  bool get canUndo => _undo.isNotEmpty;
  bool get canRedo => _redo.isNotEmpty;
  int get filledCount => marks.expand((e) => e).where((e) => e == CellMark.filled).length;
  int get totalFilled => solution.expand((e) => e).where((e) => e).length;
  double get progress => totalFilled == 0 ? 1 :
      marks.asMap().entries.fold<int>(0, (sum, row) =>
          sum + row.value.asMap().entries.where((c) =>
              c.value == CellMark.filled && solution[row.key][c.key]).length) /
              totalFilled;

  List<int> rowClues(int row) => cluesForLine(solution[row]);
  List<int> columnClues(int column) => cluesForLine([
        for (final row in solution) row[column],
      ]);

  bool get solved {
    for (var r = 0; r < height; r++) {
      for (var c = 0; c < width; c++) {
        if ((marks[r][c] == CellMark.filled) != solution[r][c]) return false;
      }
    }
    return true;
  }

  String _encodeMarks() => marks
      .map((row) => row.map((mark) => mark.index).join()).join('/');

  void _restoreMarks(String encoded) {
    final rows = encoded.split('/');
    if (rows.length != height || rows.any((r) => r.length != width)) {
      throw const FormatException('Unexpected mark dimensions');
    }
    for (var r = 0; r < height; r++) {
      for (var c = 0; c < width; c++) {
        final index = int.tryParse(rows[r][c]);
        if (index == null || index >= CellMark.values.length) {
          throw const FormatException('Invalid cell mark');
        }
        marks[r][c] = CellMark.values[index];
      }
    }
  }

  bool setMark(int row, int column, CellMark mark) {
    if (row < 0 || row >= height || column < 0 || column >= width ||
        marks[row][column] == mark) return false;
    _undo.add(_encodeMarks());
    if (_undo.length > 100) _undo.removeAt(0);
    _redo.clear();
    marks[row][column] = mark;
    taps++;
    return true;
  }

  void cycle(int row, int column) {
    if (row < 0 || row >= height || column < 0 || column >= width) return;
    final next = switch (marks[row][column]) {
      CellMark.unknown => CellMark.filled,
      CellMark.filled => CellMark.empty,
      CellMark.empty => CellMark.unknown,
    };
    setMark(row, column, next);
  }

  bool undo() {
    if (_undo.isEmpty) return false;
    _redo.add(_encodeMarks());
    _restoreMarks(_undo.removeLast());
    if (taps > 0) taps--;
    return true;
  }

  bool redo() {
    if (_redo.isEmpty) return false;
    _undo.add(_encodeMarks());
    _restoreMarks(_redo.removeLast());
    taps++;
    return true;
  }

  /// User-initiated, free hint: never silently asks for ad consent or a purchase.
  /// Finds a mismatch and reveals the correct state, preferring filled squares.
  (int, int)? revealHint() {
    if (solved) return null;
    for (final desiredFilled in [true, false]) {
      for (var r = 0; r < height; r++) {
        for (var c = 0; c < width; c++) {
          if (solution[r][c] != desiredFilled) continue;
          final desired = desiredFilled ? CellMark.filled : CellMark.empty;
          if (marks[r][c] != desired && setMark(r, c, desired)) {
            hintsUsed++;
            return (r, c);
          }
        }
      }
    }
    return null;
  }

  void reset() {
    for (final row in marks) {
      row.fillRange(0, row.length, CellMark.unknown);
    }
    _undo.clear();
    _redo.clear();
    hintsUsed = 0;
    taps = 0;
  }

  /// User-local session, contains no identity or purchase entitlement.
  String saveState() => jsonEncode({
    'schema': 1,
    'width': width,
    'height': height,
    'marks': _encodeMarks(),
    'taps': taps,
    'hints': hintsUsed,
  });

  bool loadState(String raw) {
    try {
      final data = jsonDecode(raw);
      if (data is! Map || data['schema'] != 1 ||
          data['width'] != width || data['height'] != height) return false;
      final encoded = data['marks'];
      final restoredTaps = data['taps'];
      final restoredHints = data['hints'];
      if (encoded is! String || restoredTaps is! int ||
          restoredHints is! int || restoredTaps < 0 || restoredHints < 0) {
        return false;
      }
      // Validate the full payload before mutating the live game.
      final candidate = NonogramPuzzle(solution);
      candidate._restoreMarks(encoded);
      for (var r = 0; r < height; r++) {
        marks[r].setAll(0, candidate.marks[r]);
      }
      taps = restoredTaps;
      hintsUsed = restoredHints;
      _undo.clear();
      _redo.clear();
      return true;
    } on FormatException {
      return false;
    } on TypeError {
      return false;
    } catch (_) {
      return false;
    }
  }
}
