import 'package:flutter_test/flutter_test.dart';
import 'package:game_007_nonogram_logic/main.dart';

void main() {
  group('Nonogram puzzle rules', () {
    test('clues group contiguous filled cells', () {
      expect(cluesForLine([false, false]), [0]);
      expect(cluesForLine([true, true, false, true, false, true, true]), [2, 1, 2]);
    });

    test('row and column clues reflect the solution', () {
      final puzzle = NonogramPuzzle([
        [true, false, true],
        [true, false, false],
        [false, false, true],
      ]);
      expect(puzzle.rowClues(0), [1, 1]);
      expect(puzzle.columnClues(0), [2]);
      expect(puzzle.columnClues(1), [0]);
    });

    test('marks cycle and reset to unknown', () {
      final puzzle = NonogramPuzzle([[true, false]]);
      expect(puzzle.marks[0][0], CellMark.unknown);
      puzzle.cycle(0, 0);
      expect(puzzle.marks[0][0], CellMark.filled);
      puzzle.cycle(0, 0);
      expect(puzzle.marks[0][0], CellMark.empty);
      puzzle.cycle(0, 0);
      expect(puzzle.marks[0][0], CellMark.unknown);
      puzzle.cycle(0, 0);
      puzzle.reset();
      expect(puzzle.marks[0][0], CellMark.unknown);
    });

    test('solved requires exact filled cells, not all empty marks', () {
      final puzzle = NonogramPuzzle([
        [true, false],
        [false, true],
      ]);
      expect(puzzle.solved, isFalse);
      puzzle.cycle(0, 0);
      expect(puzzle.solved, isFalse);
      puzzle.cycle(1, 1);
      expect(puzzle.solved, isTrue);
      puzzle.cycle(0, 1);
      expect(puzzle.solved, isTrue);
      puzzle.cycle(0, 1);
      expect(puzzle.solved, isTrue);
      puzzle.cycle(0, 1);
      expect(puzzle.solved, isTrue);
      puzzle.cycle(0, 0);
      expect(puzzle.solved, isFalse);
    });
  });
}
