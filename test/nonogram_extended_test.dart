import 'package:flutter_test/flutter_test.dart';
import 'package:game_007_nonogram_logic/game/nonogram_catalog.dart';
import 'package:game_007_nonogram_logic/game/nonogram_game.dart';

void main() {
  test('160 deterministic campaign stages have consistent dimensions', () {
    expect(NonogramCatalog.count, 160);
    for (final level in NonogramCatalog.levels) {
      expect(level.board.length, level.size);
      expect(level.board.every((row) => row.length == level.size), isTrue);
      expect(level.board.expand((row) => row).any((filled) => filled), isTrue);
      final game = NonogramPuzzle(level.board);
      expect(game.solved, isFalse);
      for (var r = 0; r < game.height; r++) {
        expect(game.rowClues(r), isNotEmpty);
      }
      for (var c = 0; c < game.width; c++) {
        expect(game.columnClues(c), isNotEmpty);
      }
    }
  });

  test('daily level seed stable within UTC date, including before epoch', () {
    expect(NonogramCatalog.dailyIndex(DateTime(2026, 11, 17, 0)),
        NonogramCatalog.dailyIndex(DateTime(2026, 11, 17, 23)));
    expect(NonogramCatalog.dailyIndex(DateTime(2020)), inInclusiveRange(0, 159));
  });

  test('undo/redo persists visually correct marks', () {
    final game = NonogramPuzzle([[true, false], [false, true]]);
    game.cycle(0, 0);
    game.cycle(1, 1);
    expect(game.solved, isTrue);
    expect(game.canUndo, isTrue);
    expect(game.undo(), isTrue);
    expect(game.solved, isFalse);
    expect(game.canRedo, isTrue);
    expect(game.redo(), isTrue);
    expect(game.solved, isTrue);
    expect(game.setMark(0, 1, CellMark.empty), isTrue);
    expect(game.canRedo, isFalse);
  });

  test('invalid moves do not change the model', () {
    final game = NonogramPuzzle([[true]]);
    expect(game.setMark(2, 0, CellMark.filled), isFalse);
    expect(game.setMark(0, -1, CellMark.empty), isFalse);
    expect(game.canUndo, isFalse);
    game.cycle(-1, -1);
    expect(game.taps, 0);
  });

  test('save restores a verified snapshot of the same puzzle size', () {
    final game = NonogramPuzzle([[true, false], [false, true]]);
    game.setMark(0, 0, CellMark.filled);
    game.setMark(1, 0, CellMark.empty);
    game.revealHint();
    final raw = game.saveState();
    final next = NonogramPuzzle([[true, false], [false, true]]);
    expect(next.loadState(raw), isTrue);
    expect(next.marks, game.marks);
    expect(next.hintsUsed, game.hintsUsed);
    expect(next.loadState('{"schema":999}'), isFalse);
    expect(next.loadState('not-json'), isFalse);
    expect(next.marks, game.marks);
  });

  test('hint supplies correct cell without rewarded-ad requirement', () {
    final game = NonogramPuzzle([[true, false], [false, true]]);
    expect(game.revealHint(), (0, 0));
    expect(game.hintsUsed, 1);
    expect(game.marks[0][0], CellMark.filled);
    expect(game.revealHint(), (1, 1));
    expect(game.solved, isTrue);
    expect(game.revealHint(), isNull);
  });

  test('input can reject a malformed board', () {
    expect(() => NonogramPuzzle([[true, false], [true]]), throwsArgumentError);
  });
}
