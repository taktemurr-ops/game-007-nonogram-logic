import 'package:flutter_test/flutter_test.dart';
import 'package:game_007_nonogram_logic/main.dart';

void main() {
  test('run clues handle separated groups and empty lines', () {
    expect(cluesForLine([true, true, false, true, false]), [2, 1]);
    expect(cluesForLine([false, false]), [0]);
    expect(cluesForLine([true, true]), [2]);
  });

  test('marks cycle and only correct filled cells win', () {
    final puzzle = NonogramPuzzle([
      [true, false],
      [false, true],
    ]);
    expect(puzzle.solved, isFalse);
    puzzle.cycle(0, 0);
    puzzle.cycle(1, 1);
    expect(puzzle.solved, isTrue);
    puzzle.cycle(0, 0);
    expect(puzzle.solved, isFalse);
    puzzle.cycle(0, 0);
    expect(puzzle.solved, isFalse);
    puzzle.cycle(0, 0);
    expect(puzzle.solved, isTrue);
    puzzle.reset();
    expect(puzzle.solved, isFalse);
  });

  testWidgets('game screen shows playable cells and clues', (tester) async {
    await tester.pumpWidget(const NonogramApp());
    expect(find.text('Nonogram Logic'), findsOneWidget);
    expect(find.byKey(const ValueKey('cell-0-0')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('cell-0-0')));
    await tester.pump();
    expect(find.text('Complete the picture to win.'), findsOneWidget);
  });
}
