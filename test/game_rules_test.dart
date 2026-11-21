import 'package:flutter_test/flutter_test.dart';
import 'package:studio_core/core/level_plan.dart';
import 'package:game_007_nonogram_logic/game/nonogram_engine.dart';
import 'package:game_007_nonogram_logic/game/rules.dart';

void main() {
  final rules = NonoRules();
  final planner = LevelPlanner(gameId: rules.gameId, optionalMechanics: rules.optionalMechanics);

  test('line solver deduces overlaps and empties', () {
    expect(solveLine([4], [-1, -1, -1, -1, -1]), equals([-1, 1, 1, 1, -1]));
    expect(solveLine([2, 2], [-1, -1, -1, -1, -1]), equals([1, 1, 0, 1, 1]));
    expect(solveLine([0 + 1], [0, 0, 1, 0, 0]), equals([0, 0, 1, 0, 0]));
    expect(solveLine([3], [1, 0, -1, -1, -1]), isNull);
  });

  test('every generated picture is solvable by logic alone (unique)', () {
    for (var n = 1; n <= 120; n++) {
      final g = rules.build(planner.spec(n));
      expect(g.validation.ok, isTrue, reason: 'level $n');
    }
  });

  test('fill / cross with mistake correction, auto-cross, hint, win', () {
    final l = rules.build(planner.spec(4)).puzzle;
    final g = NonoGame(l);
    final empty = l.solution.indexOf(0);
    expect(g.mark(empty, 1), isFalse);
    expect(g.mistakes, 1);
    expect(g.cells[empty], 2);
    var guard = 0;
    while (!g.won && guard++ < 1000) {
      g.reveal();
    }
    expect(g.won, isTrue);
  });

  test('resume restores state', () {
    final l = rules.build(planner.spec(9)).puzzle;
    final g = NonoGame(l)..reveal();
    expect(NonoGame.restore(l, g.serialize()).serialize(), g.serialize());
  });

  test('big boards sampled to 50.000', () {
    for (var n = 5000; n <= 50000; n += 9000) {
      expect(rules.build(planner.spec(n)).validation.ok, isTrue, reason: 'level $n');
    }
  });
}
