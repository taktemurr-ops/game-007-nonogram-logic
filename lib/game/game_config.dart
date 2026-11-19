import 'package:flutter/material.dart';

import '../app/game_api.dart';
import 'nonogram_view.dart';
import 'rules.dart';

final gameConfig = GameConfig(
  gameId: 'game-007-nonogram-logic',
  title: const ['Nonogram Mantık', 'Nonogram Logic', 'Nonogramm Logik', 'Nonograma Lógico', 'Logique Nonogramme'],
  tagline: const [
    'Sayı ipuçlarını çöz, gizli resmi ortaya çıkar!',
    'Solve number clues, reveal hidden pictures!',
    'Löse Zahlenhinweise, entdecke Bilder!',
    '¡Resuelve pistas y descubre imágenes!',
    'Résolvez les indices, révélez l\'image !',
  ],
  seedColor: const Color(0xFF455A64),
  icon: Icons.apps,
  rules: NonoRules(),
  buildPlay: (ctx) => NonogramView(ctx: ctx),
  tutorial: const [
    TutorialStep(Icons.format_list_numbered, [
      'Satır ve sütundaki sayılar, sırasıyla kaç tane dolu kare grubu olduğunu gösterir.',
      'Numbers on each row/column tell the lengths of filled groups, in order.',
      'Zahlen zeigen die Längen der gefüllten Gruppen.',
      'Los números indican los grupos de casillas llenas.',
      'Les nombres indiquent les groupes de cases pleines.',
    ]),
    TutorialStep(Icons.square, [
      'Doldur modunda kareleri boya, X modunda boş olduğunu bildiğin kareleri işaretle. Parmağını sürükleyerek çoklu işaretle.',
      'Fill mode paints cells, X mode marks empties. Drag to mark many cells.',
      'Füllen malt, X markiert Leere. Ziehen für viele Felder.',
      'Rellenar pinta, X marca vacías. Arrastra para varias.',
      'Remplir peint, X marque les vides. Glissez pour plusieurs.',
    ]),
    TutorialStep(Icons.psychology, [
      'Her bulmaca tahmin gerektirmeden yalnızca mantıkla çözülebilir.',
      'Every puzzle can be solved by logic alone - no guessing.',
      'Jedes Rätsel ist ohne Raten lösbar.',
      'Todos se resuelven solo con lógica.',
      'Chaque grille se résout par la logique.',
    ]),
  ],
);
