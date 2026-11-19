import '../core/level_plan.dart';
import '../core/rng.dart';

class NonoLevel {
  final int w;
  final int h;
  final List<int> solution; // 1 filled, 0 empty
  final List<List<int>> rowClues;
  final List<List<int>> colClues;
  final int lives; // 0 = unlimited
  final int timeLimit;
  final int difficulty;
  final int seed;
  final int colorHue;

  const NonoLevel({
    required this.w,
    required this.h,
    required this.solution,
    required this.rowClues,
    required this.colClues,
    required this.lives,
    required this.timeLimit,
    required this.difficulty,
    required this.seed,
    required this.colorHue,
  });
}

List<int> runsOf(List<int> line) {
  final out = <int>[];
  var run = 0;
  for (final v in line) {
    if (v == 1) {
      run++;
    } else if (run > 0) {
      out.add(run);
      run = 0;
    }
  }
  if (run > 0) out.add(run);
  return out;
}

/// Solves one line given clues. cells: -1 unknown, 0 empty, 1 filled.
/// Returns the refined line, or null on contradiction.
List<int>? solveLine(List<int> clues, List<int> cells) {
  final n = cells.length, k = clues.length;
  // suffix feasibility S[i][j]
  final s = List.generate(n + 2, (_) => List<bool>.filled(k + 1, false));
  s[n][k] = true;
  for (var i = n - 1; i >= 0; i--) {
    s[i][k] = s[i + 1][k] && cells[i] != 1;
  }
  s[n + 1][k] = true;
  for (var j = k - 1; j >= 0; j--) {
    for (var i = n - 1; i >= 0; i--) {
      var ok = cells[i] != 1 && s[i + 1][j];
      final c = clues[j];
      if (!ok && i + c <= n) {
        var fits = true;
        for (var t = i; t < i + c; t++) {
          if (cells[t] == 0) {
            fits = false;
            break;
          }
        }
        if (fits) {
          if (i + c == n) {
            ok = j + 1 == k;
          } else {
            ok = cells[i + c] != 1 && s[i + c + 1][j + 1];
          }
        }
      }
      s[i][j] = ok;
    }
  }
  if (!s[0][0]) return null;
  final canFill = List<bool>.filled(n, false);
  final canEmpty = List<bool>.filled(n, false);
  final reach = List.generate(n + 2, (_) => List<bool>.filled(k + 1, false));
  reach[0][0] = true;
  for (var i = 0; i <= n; i++) {
    for (var j = 0; j <= k; j++) {
      if (!reach[i][j] || !s[i][j]) continue;
      if (i >= n) continue;
      if (j == k) {
        for (var t = i; t < n; t++) {
          canEmpty[t] = true;
        }
        continue;
      }
      if (cells[i] != 1 && s[i + 1][j]) {
        canEmpty[i] = true;
        reach[i + 1][j] = true;
      }
      final c = clues[j];
      if (i + c <= n) {
        var fits = true;
        for (var t = i; t < i + c; t++) {
          if (cells[t] == 0) {
            fits = false;
            break;
          }
        }
        if (!fits) continue;
        if (i + c == n) {
          if (j + 1 == k) {
            for (var t = i; t < n; t++) {
              canFill[t] = true;
            }
          }
        } else if (cells[i + c] != 1 && s[i + c + 1][j + 1]) {
          for (var t = i; t < i + c; t++) {
            canFill[t] = true;
          }
          canEmpty[i + c] = true;
          reach[i + c + 1][j + 1] = true;
        }
      }
    }
  }
  final out = List.of(cells);
  for (var i = 0; i < n; i++) {
    if (canFill[i] && !canEmpty[i]) out[i] = 1;
    if (!canFill[i] && canEmpty[i]) out[i] = 0;
    if (!canFill[i] && !canEmpty[i]) return null;
  }
  return out;
}

/// Line-logic solver. Returns the solved grid if the puzzle is solvable
/// purely by logic (which also proves the solution is unique), else null.
List<int>? logicSolve(int w, int h, List<List<int>> rows, List<List<int>> cols) {
  final g = List<int>.filled(w * h, -1);
  var changed = true;
  while (changed) {
    changed = false;
    for (var y = 0; y < h; y++) {
      final line = List.generate(w, (x) => g[y * w + x]);
      final r = solveLine(rows[y], line);
      if (r == null) return null;
      for (var x = 0; x < w; x++) {
        if (r[x] != line[x]) {
          g[y * w + x] = r[x];
          changed = true;
        }
      }
    }
    for (var x = 0; x < w; x++) {
      final line = List.generate(h, (y) => g[y * w + x]);
      final r = solveLine(cols[x], line);
      if (r == null) return null;
      for (var y = 0; y < h; y++) {
        if (r[y] != line[y]) {
          g[y * w + x] = r[y];
          changed = true;
        }
      }
    }
  }
  return g.contains(-1) ? null : g;
}

NonoLevel generateNonogram(LevelSpec spec) {
  final r = SeededRandom(spec.seed);
  final d = spec.difficulty;
  const sizes = [5, 5, 7, 8, 10, 10, 12, 12, 15, 15];
  var n = sizes[(d - 1).clamp(0, 9)];
  if (spec.has('big')) n = (n + 3).clamp(5, 20);
  final w = n, h = n;
  // Smooth random field with optional mirror symmetry -> picture-like shapes.
  final sym = r.nextInt(3); // 0 none, 1 vertical mirror, 2 both
  final density = 0.5 + r.nextDouble() * 0.15;
  var grid = List<int>.generate(w * h, (_) => r.chance(density) ? 1 : 0);
  for (var pass = 0; pass < 2; pass++) {
    final next = List<int>.of(grid);
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        var c = 0;
        for (var dy = -1; dy <= 1; dy++) {
          for (var dx = -1; dx <= 1; dx++) {
            final nx = x + dx, ny = y + dy;
            if (nx >= 0 && ny >= 0 && nx < w && ny < h && grid[ny * w + nx] == 1) c++;
          }
        }
        next[y * w + x] = c >= 5 ? 1 : (c <= 3 ? 0 : grid[y * w + x]);
      }
    }
    grid = next;
  }
  if (sym >= 1) {
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w ~/ 2; x++) {
        grid[y * w + (w - 1 - x)] = grid[y * w + x];
      }
    }
  }
  if (sym == 2) {
    for (var y = 0; y < h ~/ 2; y++) {
      for (var x = 0; x < w; x++) {
        grid[(h - 1 - y) * w + x] = grid[y * w + x];
      }
    }
  }
  final rows = List.generate(h, (y) => runsOf(List.generate(w, (x) => grid[y * w + x])));
  final cols = List.generate(w, (x) => runsOf(List.generate(h, (y) => grid[y * w + x])));
  return NonoLevel(
    w: w,
    h: h,
    solution: grid,
    rowClues: rows,
    colClues: cols,
    lives: spec.has('lives') ? 3 : 0,
    timeLimit: spec.mode == GameModeId.timeAttack ? 60 + n * n : (spec.has('timer') ? 60 + n * n * 2 : 0),
    difficulty: d,
    seed: spec.seed,
    colorHue: r.nextInt(360),
  );
}

class NonoGame {
  final NonoLevel level;
  late List<int> cells; // 0 unknown, 1 filled, 2 crossed
  int mistakes = 0;
  int moves = 0;
  final List<String> _undo = [];

  NonoGame(this.level) {
    cells = List.filled(level.w * level.h, 0);
  }

  bool get won {
    for (var i = 0; i < cells.length; i++) {
      if ((level.solution[i] == 1) != (cells[i] == 1)) return false;
    }
    return true;
  }

  bool get lost => level.lives > 0 && mistakes >= level.lives;

  int get filledCount => cells.where((c) => c == 1).length;

  /// mode: 1 = fill, 2 = cross. Wrong actions are corrected and counted.
  bool mark(int i, int mode) {
    if (cells[i] != 0) return true;
    _push();
    moves++;
    final truth = level.solution[i];
    if (mode == 1 && truth == 0) {
      cells[i] = 2;
      mistakes++;
      return false;
    }
    if (mode == 2 && truth == 1) {
      cells[i] = 1;
      mistakes++;
      return false;
    }
    cells[i] = mode;
    _autoCross(i);
    return true;
  }

  /// Crosses the rest of a row/column once it is complete.
  void _autoCross(int i) {
    final x = i % level.w, y = i ~/ level.w;
    bool rowDone() => List.generate(level.w, (k) => k).every((k) => level.solution[y * level.w + k] == 0 || cells[y * level.w + k] == 1);
    bool colDone() => List.generate(level.h, (k) => k).every((k) => level.solution[k * level.w + x] == 0 || cells[k * level.w + x] == 1);
    if (rowDone()) {
      for (var k = 0; k < level.w; k++) {
        if (cells[y * level.w + k] == 0) cells[y * level.w + k] = 2;
      }
    }
    if (colDone()) {
      for (var k = 0; k < level.h; k++) {
        if (cells[k * level.w + x] == 0) cells[k * level.w + x] = 2;
      }
    }
  }

  bool rowComplete(int y) => List.generate(level.w, (k) => k).every((k) => (level.solution[y * level.w + k] == 1) == (cells[y * level.w + k] == 1));
  bool colComplete(int x) => List.generate(level.h, (k) => k).every((k) => (level.solution[k * level.w + x] == 1) == (cells[k * level.w + x] == 1));

  /// Hint: reveals one unknown filled cell (or empty if none left).
  int? reveal() {
    for (final want in [1, 0]) {
      for (var i = 0; i < cells.length; i++) {
        if (cells[i] == 0 && level.solution[i] == want) {
          _push();
          cells[i] = want == 1 ? 1 : 2;
          _autoCross(i);
          return i;
        }
      }
    }
    return null;
  }

  void forgive() => mistakes = 0;

  void _push() {
    _undo.add(_snap());
    if (_undo.length > 80) _undo.removeAt(0);
  }

  bool get canUndo => _undo.isNotEmpty;
  void undo() {
    if (_undo.isNotEmpty) _restore(_undo.removeLast());
  }

  String _snap() => '${cells.join()}#$mistakes#$moves';
  void _restore(String s) {
    final p = s.split('#');
    cells = p[0].split('').map(int.parse).toList();
    mistakes = int.parse(p[1]);
    moves = int.parse(p[2]);
  }

  String serialize() => _snap();
  static NonoGame restore(NonoLevel l, String s) => NonoGame(l).._restore(s);
}
