import 'package:flutter_test/flutter_test.dart';
import 'package:game_007_nonogram_logic/main.dart';

void main() {
  group('Nonogram clue rules', () {
    test('column clues follow vertical runs', () {
      final puzzle = NonogramPuzzle([
        [true, false, true],
        [true, true, false],
        [false, true, true],
        [true, false, true],
      ]);
      expect(puzzle.columnClues(0), [2, 1]);
      expect(puzzle.columnClues(1), [2]);
      expect(puzzle.columnClues(2), [1, 2]);
      expect(puzzle.rowClues(0), [1, 1]);
    });

    test('all-empty puzzle starts solved by filled-cell equivalence', () {
      final puzzle = NonogramPuzzle([
        [false, false],
        [false, false],
      ]);
      expect(puzzle.rowClues(0), [0]);
      expect(puzzle.columnClues(0), [0]);
      expect(puzzle.solved, isTrue);
    });

    test('cycling is reversible and reset clears every mark', () {
      final puzzle = NonogramPuzzle([
        [true, false],
        [false, true],
      ]);
      puzzle.cycle(0, 0);
      expect(puzzle.marks[0][0], CellMark.filled);
      puzzle.cycle(0, 0);
      expect(puzzle.marks[0][0], CellMark.empty);
      puzzle.cycle(0, 0);
      expect(puzzle.marks[0][0], CellMark.unknown);
      puzzle.cycle(1, 1);
      puzzle.reset();
      expect(puzzle.marks.expand((row) => row), everyElement(CellMark.unknown));
    });
  });
}
