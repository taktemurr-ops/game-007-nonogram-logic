import 'package:flutter_test/flutter_test.dart';
import 'package:game_007_nonogram_logic/game/nonogram_catalog.dart';
import 'package:game_007_nonogram_logic/game/nonogram_game.dart';

/// Independent row-pattern backtracker. This test deliberately works from
/// clues only, never uses the artwork as an answer during the search.
int countSolutions(List<List<bool>> board, {int stopAt = 2}) {
  final size = board.length;
  final game = NonogramPuzzle(board);
  final rowClues = [for (var r = 0; r < size; r++) game.rowClues(r)];
  final colClues = [for (var c = 0; c < size; c++) game.columnClues(c)];
  final allPatterns = <List<bool>>[
    for (var mask = 0; mask < 1 << size; mask++)
      [for (var c = 0; c < size; c++) (mask & (1 << c)) != 0],
  ];
  final rows = [for (final clue in rowClues)
    allPatterns.where((p) => _same(cluesForLine(p), clue)).toList()];
  final columns = [for (final clue in colClues)
    allPatterns.where((p) => _same(cluesForLine(p), clue)).toList()];
  var found = 0;

  void dfs(int row, List<List<List<bool>>> possibilities) {
    if (found >= stopAt) return;
    if (row == size) {
      found++;
      return;
    }
    for (final pattern in rows[row]) {
      final filtered = <List<List<bool>>>[];
      var feasible = true;
      for (var col = 0; col < size; col++) {
        final matches = possibilities[col].where((option) =>
            option[row] == pattern[col]).toList();
        if (matches.isEmpty) {
          feasible = false;
          break;
        }
        filtered.add(matches);
      }
      if (feasible) dfs(row + 1, filtered);
    }
  }

  dfs(0, columns);
  return found;
}

bool _same(List<int> a, List<int> b) => a.length == b.length &&
    List.generate(a.length, (i) => a[i] == b[i]).every((x) => x);

void main() {
  test('every campaign board has exactly one clue solution', () {
    for (final level in NonogramCatalog.levels) {
      expect(countSolutions(level.board), 1,
          reason: '${level.id}: ${level.title} must have a unique solution');
    }
  });
}
