import 'package:studio_core/core/game_rules.dart';
import 'package:studio_core/core/level_plan.dart';
import 'package:studio_core/core/missions.dart';
import 'package:studio_core/core/stats.dart';
import 'nonogram_engine.dart';

class NonoRules extends GameRules<NonoLevel> {
  @override
  String get gameId => 'game-007-nonogram-logic';

  @override
  List<String> get optionalMechanics => const ['lives', 'timer', 'big'];

  @override
  List<GameModeId> get modes => const [
        GameModeId.campaign,
        GameModeId.endless,
        GameModeId.timeAttack,
        GameModeId.zen,
        GameModeId.daily,
        GameModeId.weekly,
        GameModeId.challenge,
      ];

  @override
  List<GameStat> get gameStats => const [
        GameStat('cells_filled', 'Boyanan kare', 'Cells filled', scale: 200),
        GameStat('pictures_solved', 'Çözülen resim', 'Pictures solved', scale: 5),
        GameStat('flawless', 'Hatasız resim', 'Flawless pictures', scale: 2),
      ];

  @override
  List<MissionTemplate> get missionTemplates => const [
        MissionTemplate('cells', 'cells_filled', [100, 250, 500]),
        MissionTemplate('flawless', 'flawless', [1, 2, 4], coinReward: 80),
      ];

  @override
  NonoLevel generate(LevelSpec spec) => generateNonogram(spec);

  @override
  Validation validate(NonoLevel l, LevelSpec spec) {
    final filled = l.solution.where((v) => v == 1).length;
    if (filled < l.w * l.h * 0.25 || filled > l.w * l.h * 0.85) return const Validation.fail('density');
    for (var y = 0; y < l.h; y++) {
      if (runsOf(List.generate(l.w, (x) => l.solution[y * l.w + x])).join(',') != l.rowClues[y].join(',')) {
        return const Validation.fail('row clue');
      }
    }
    final solved = logicSolve(l.w, l.h, l.rowClues, l.colClues);
    if (solved == null) return const Validation.fail('needs guessing / not unique');
    for (var i = 0; i < solved.length; i++) {
      if (solved[i] != l.solution[i]) return const Validation.fail('mismatch');
    }
    return Validation.ok(filled);
  }

  static int stars(NonoGame g) {
    if (!g.won) return 0;
    if (g.mistakes == 0) return 3;
    if (g.mistakes <= 2) return 2;
    return 1;
  }
}

GameRules createRules() => NonoRules();
