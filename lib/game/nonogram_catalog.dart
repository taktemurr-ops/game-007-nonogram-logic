import 'dart:math';

/// Original pixel artwork defined in source; no proprietary images required.
/// Each seed yields up to eight transformed board orientations.
class NonogramLevel {
  const NonogramLevel({required this.id, required this.title,
    required this.size, required this.board});
  final String id;
  final String title;
  final int size;
  final List<List<bool>> board;
}

class NonogramCatalog {
  static const _seeds = <String, List<String>>{
    'Heart': ['.###.', '#####', '#####', '.###.', '..#..'],
    'House': ['..#..', '.###.', '#####', '#...#', '#####'],
    'Arrow': ['..#..', '.##..', '#####', '.##..', '..#..'],
    'Cup': ['#...#', '#...#', '#...#', '.###.', '..#..'],
    'Flower': ['.#.#.', '#####', '.###.', '#####', '.#.#.'],
    'Plane': ['..#..', '#.#.#', '#####', '..#..', '.###.'],
    'Duck': ['###..', '####.', '.####', '.###.', '..###'],
    'Fish': ['#..##', '.####', '#####', '.####', '#..##'],
    'Star': ['..#..', '#####', '.###.', '#####', '..#..'],
    'Tree': ['..#..', '.###.', '#####', '..#..', '..#..'],
    'Sail': ['..#..', '.##..', '.###.', '#####', '.###.'],
    'Rocket': ['..#..', '.###.', '.###.', '#####', '#.#.#'],
    'Moon': ['..###', '.##..', '##...', '.##..', '..###'],
    'Cat': ['#...#', '##.##', '#####', '.###.', '.#.#.'],
    'Gift': ['.#.#.', '#####', '#####', '#####', '#####'],
    'Butterfly': ['##.##', '#####', '.###.', '#####', '##.##'],
    'Bird': ['..##.', '.####', '#####', '..##.', '..#..'],
    'Castle': ['#.#.#', '#####', '.###.', '#####', '#...#'],
    'Key': ['###..', '#.#..', '###..', '.#...', '.##..'],
    'Crown': ['#.#.#', '#####', '.###.', '.###.', '#####'],
  };

  static List<List<bool>> _transform(List<List<bool>> base,
      {required int turns, required bool flip}) {
    var rows = base.map((row) => List<bool>.from(row)).toList();
    if (flip) rows = rows.map((row) => row.reversed.toList()).toList();
    for (var i = 0; i < turns; i++) {
      rows = List.generate(rows.first.length,
        (r) => List.generate(rows.length, (c) => rows[rows.length - 1 - c][r]));
    }
    return rows;
  }

  /// Deterministic 160-stage offline campaign. Rotations/reflections are
  /// always solvable because the artwork itself is the solution.
  static final List<NonogramLevel> levels = () {
    final levels = <NonogramLevel>[];
    var i = 0;
    for (final entry in _seeds.entries) {
      final base = entry.value.map((line) =>
        line.split('').map((c) => c == '#').toList()).toList();
      for (var flip = 0; flip < 2; flip++) {
        for (var rotate = 0; rotate < 4; rotate++) {
          i++;
          levels.add(NonogramLevel(
            id: 'campaign-$i', title: entry.key, size: base.length,
            board: _transform(base, turns: rotate, flip: flip != 0),
          ));
        }
      }
    }
    return List<NonogramLevel>.unmodifiable(levels);
  }();

  static int get count => levels.length;
  static NonogramLevel at(int index) => levels[index];

  static int dailyIndex(DateTime date) {
    final day = DateTime.utc(date.year, date.month, date.day);
    final seed = day.difference(DateTime.utc(2025, 1, 1)).inDays;
    return (seed % levels.length + levels.length) % levels.length;
  }

  static NonogramLevel daily(DateTime day) => at(dailyIndex(day));

  static NonogramLevel random(Random random) => at(random.nextInt(count));
}
