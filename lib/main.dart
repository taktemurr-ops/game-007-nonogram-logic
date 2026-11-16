import 'package:flutter/material.dart';

void main() => runApp(const NonogramApp());

/// A cell is either unknown, filled, or explicitly marked empty.
enum CellMark { unknown, filled, empty }

List<int> cluesForLine(List<bool> cells) {
  final result = <int>[];
  var streak = 0;
  for (final filled in cells) {
    if (filled) {
      streak++;
    } else if (streak > 0) {
      result.add(streak);
      streak = 0;
    }
  }
  if (streak > 0) result.add(streak);
  return result.isEmpty ? [0] : result;
}

class NonogramPuzzle {
  NonogramPuzzle(this.solution)
      : assert(solution.isNotEmpty),
        assert(solution.every((row) => row.length == solution.first.length)),
        marks = List.generate(solution.length,
            (_) => List.filled(solution.first.length, CellMark.unknown));

  final List<List<bool>> solution;
  final List<List<CellMark>> marks;

  int get height => solution.length;
  int get width => solution.first.length;

  List<int> rowClues(int row) => cluesForLine(solution[row]);
  List<int> columnClues(int column) =>
      cluesForLine([for (final row in solution) row[column]]);

  void cycle(int row, int column) {
    final mark = marks[row][column];
    marks[row][column] = switch (mark) {
      CellMark.unknown => CellMark.filled,
      CellMark.filled => CellMark.empty,
      CellMark.empty => CellMark.unknown,
    };
  }

  void reset() {
    for (final row in marks) {
      row.fillRange(0, row.length, CellMark.unknown);
    }
  }

  bool get solved {
    for (var row = 0; row < height; row++) {
      for (var col = 0; col < width; col++) {
        if ((marks[row][col] == CellMark.filled) != solution[row][col]) {
          return false;
        }
      }
    }
    return true;
  }
}

final sampleLevels = <List<List<bool>>>[
  [
    [false, false, true, false, false],
    [false, true, true, true, false],
    [true, true, true, true, true],
    [false, true, true, true, false],
    [false, false, true, false, false],
  ],
  [
    [true, false, false, false, true],
    [true, true, false, true, true],
    [false, true, true, true, false],
    [false, false, true, false, false],
    [false, false, true, false, false],
  ],
];

class NonogramApp extends StatelessWidget {
  const NonogramApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Nonogram Logic',
        theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
        home: const NonogramScreen(),
      );
}

class NonogramScreen extends StatefulWidget {
  const NonogramScreen({super.key});

  @override
  State<NonogramScreen> createState() => _NonogramScreenState();
}

class _NonogramScreenState extends State<NonogramScreen> {
  int level = 0;
  late NonogramPuzzle puzzle = NonogramPuzzle(sampleLevels[level]);

  void nextLevel() => setState(() {
        level = (level + 1) % sampleLevels.length;
        puzzle = NonogramPuzzle(sampleLevels[level]);
      });

  @override
  Widget build(BuildContext context) {
    final solved = puzzle.solved;
    return Scaffold(
      appBar: AppBar(title: const Text('Nonogram Logic')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text('Level ${level + 1}', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              const Text('Follow the row and column clues. Tap to fill, mark empty, or clear.'),
              const SizedBox(height: 20),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: LayoutBuilder(builder: (context, bounds) {
                  final cell = (bounds.maxWidth - 64) / puzzle.width;
                  return Column(children: [
                    Row(children: [
                      const SizedBox(width: 64),
                      for (var col = 0; col < puzzle.width; col++)
                        SizedBox(
                          width: cell,
                          height: 60,
                          child: Center(child: Text(puzzle.columnClues(col).join('\n'),
                              textAlign: TextAlign.center)),
                        ),
                    ]),
                    for (var row = 0; row < puzzle.height; row++)
                      Row(children: [
                        SizedBox(
                          width: 64,
                          height: cell,
                          child: Center(child: Text(puzzle.rowClues(row).join(' '))),
                        ),
                        for (var col = 0; col < puzzle.width; col++)
                          SizedBox(
                            width: cell,
                            height: cell,
                            child: Semantics(
                              label: 'Row ${row + 1}, column ${col + 1}, ${puzzle.marks[row][col].name}',
                              button: true,
                              child: InkWell(
                                key: ValueKey('cell-$row-$col'),
                                onTap: solved ? null : () => setState(() => puzzle.cycle(row, col)),
                                child: Container(
                                  margin: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.indigo),
                                    color: puzzle.marks[row][col] == CellMark.filled
                                        ? Colors.indigo
                                        : Colors.white,
                                  ),
                                  child: Center(child: puzzle.marks[row][col] == CellMark.empty
                                      ? const Icon(Icons.close, color: Colors.black54)
                                      : null),
                                ),
                              ),
                            ),
                          ),
                      ]),
                  ]);
                }),
              ),
              const SizedBox(height: 16),
              Text(solved ? 'Puzzle solved!' : 'Complete the picture to win.',
                  key: const ValueKey('status')),
              const SizedBox(height: 12),
              Wrap(spacing: 12, children: [
                OutlinedButton(onPressed: () => setState(puzzle.reset), child: const Text('Reset')),
                FilledButton(onPressed: nextLevel, child: Text(solved ? 'Next level' : 'Change level')),
              ]),
            ]),
          ),
        ),
      ),
    );
  }
}
