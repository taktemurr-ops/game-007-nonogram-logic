import 'package:flutter/material.dart';

import '../app/game_api.dart';
import '../app/play_kit.dart';
import '../app/services/audio.dart';
import '../core/game_rules.dart';
import '../core/level_plan.dart';
import '../core/rng.dart';
import 'nonogram_engine.dart';
import 'rules.dart';

/// Nonogram board with clue headers. Tap or drag to fill/cross many cells.
class NonogramView extends StatefulWidget {
  final PlayContext ctx;
  const NonogramView({super.key, required this.ctx});

  @override
  State<NonogramView> createState() => _NonogramViewState();
}

class _NonogramViewState extends State<NonogramView> with RoundClock {
  late NonoGame game;
  int _mode = 1; // 1 fill, 2 cross
  int _hints = 0;
  int _undos = 0;
  int _solved = 0;
  int _filledTotal = 0;
  bool _ended = false;
  final Set<int> _dragged = {};

  PlayContext get ctx => widget.ctx;
  bool get _chain => const [GameModeId.endless, GameModeId.timeAttack].contains(ctx.spec.mode);

  @override
  void initState() {
    super.initState();
    final level = (ctx.generated as GeneratedLevel<NonoLevel>).puzzle;
    final snap = ctx.resume['snap'];
    game = snap is String ? NonoGame.restore(level, snap) : NonoGame(level);
    _hints = (ctx.resume['hints'] as num?)?.toInt() ?? 0;
    _solved = (ctx.resume['solved'] as num?)?.toInt() ?? 0;
    startClock(initialSeconds: (ctx.resume['secs'] as num?)?.toInt() ?? 0, limit: level.timeLimit);
  }

  @override
  void dispose() {
    stopClock();
    super.dispose();
  }

  @override
  void onTimeUp() => _end(_chain ? _solved > 0 : game.won);

  void _persist() => ctx.saveResume({'snap': game.serialize(), 'secs': seconds, 'hints': _hints, 'solved': _solved});

  void _markAt(Offset local, double cell, double left, double top) {
    final x = ((local.dx - left) / cell).floor();
    final y = ((local.dy - top) / cell).floor();
    if (x < 0 || y < 0 || x >= game.level.w || y >= game.level.h) return;
    final i = y * game.level.w + x;
    if (_dragged.contains(i) || game.cells[i] != 0) return;
    _dragged.add(i);
    final ok = game.mark(i, _mode);
    if (ok && _mode == 1) _filledTotal++;
    ctx.sfx(ok ? Sfx.tap : Sfx.error);
    setState(() {});
  }

  void _afterStroke() {
    _dragged.clear();
    _persist();
    if (game.won) {
      ctx.sfx(Sfx.combo);
      if (_chain) {
        _solved++;
        final next = ctx.spec.copyWith(seed: mixSeed([ctx.spec.seed, _solved]));
        setState(() => game = NonoGame(NonoRules().build(next).puzzle));
        _persist();
        return;
      }
      _end(true);
    } else if (game.lost) {
      _offerContinue();
    }
  }

  Future<void> _offerContinue() async {
    if (ctx.spec.mode == GameModeId.zen) {
      game.forgive();
      return;
    }
    clockPaused = true;
    final again = await ctx.requestContinue();
    clockPaused = false;
    if (!mounted) return;
    if (again) {
      setState(game.forgive);
    } else {
      _end(false);
    }
  }

  void _end(bool won) {
    if (_ended) return;
    _ended = true;
    stopClock();
    ctx.finish(RoundResult(
      won: won,
      score: _chain ? _solved * 400 : (won ? (game.level.w * game.level.h * 20 - game.mistakes * 100).clamp(50, 99999) : 0),
      stars: won ? (_chain ? (_solved >= 5 ? 3 : _solved >= 2 ? 2 : 1) : NonoRules.stars(game)) : 0,
      seconds: seconds,
      moves: game.moves,
      hintsUsed: _hints,
      undosUsed: _undos,
      gameStats: {
        'cells_filled': _filledTotal,
        'pictures_solved': won ? 1 + _solved : _solved,
        'flawless': won && game.mistakes == 0 ? 1 : 0,
      },
    ));
  }

  Future<void> _hint() async {
    if (!await ctx.requestHint()) return;
    _hints++;
    setState(() => game.reveal());
    _afterStroke();
  }

  @override
  Widget build(BuildContext context) {
    final t = ctx.t;
    final l = game.level;
    final fill = HSLColor.fromAHSL(1, l.colorHue.toDouble(), 0.55, 0.35).toColor();
    return Column(children: [
      PlayHud(items: [
        (Icons.timer, timeText),
        (Icons.favorite, l.lives > 0 ? '${(l.lives - game.mistakes).clamp(0, 9)}/${l.lives}' : '${game.mistakes}'),
        (Icons.grid_on, '${l.w}×${l.h}'),
        if (_chain) (Icons.emoji_events, '$_solved'),
      ]),
      Expanded(
        child: LayoutBuilder(builder: (context, c) {
          final maxRowClue = l.rowClues.map((r) => r.length).fold(1, (a, b) => b > a ? b : a);
          final maxColClue = l.colClues.map((r) => r.length).fold(1, (a, b) => b > a ? b : a);
          final unitsW = l.w + maxRowClue * 0.7;
          final unitsH = l.h + maxColClue * 0.7;
          final cell = ((c.maxWidth - 8) / unitsW).clamp(8.0, 60.0) < ((c.maxHeight - 8) / unitsH)
              ? ((c.maxWidth - 8) / unitsW).clamp(8.0, 60.0)
              : ((c.maxHeight - 8) / unitsH).clamp(8.0, 60.0);
          final left = maxRowClue * 0.7 * cell;
          final top = maxColClue * 0.7 * cell;
          final w = left + l.w * cell, h = top + l.h * cell;
          return Center(
            child: GestureDetector(
              onPanStart: (d) => _markAt(d.localPosition, cell, left, top),
              onPanUpdate: (d) => _markAt(d.localPosition, cell, left, top),
              onPanEnd: (_) => _afterStroke(),
              onTapUp: (d) {
                _markAt(d.localPosition, cell, left, top);
                _afterStroke();
              },
              child: Semantics(
                label: 'nonogram ${l.w} by ${l.h}',
                child: CustomPaint(
                  size: Size(w, h),
                  painter: _NonoPainter(game, cell, left, top, fill, game.won),
                ),
              ),
            ),
          );
        }),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 1, icon: Icon(Icons.square)),
            ButtonSegment(value: 2, icon: Icon(Icons.close)),
          ],
          selected: {_mode},
          onSelectionChanged: (s) => setState(() => _mode = s.first),
        ),
      ),
      BoosterBar(buttons: [
        BoosterButton(Icons.lightbulb, t('hint'), _hint),
        BoosterButton(Icons.undo, t('undo'), game.canUndo
            ? () {
                setState(() {
                  game.undo();
                  _undos++;
                });
                _persist();
              }
            : null),
      ]),
    ]);
  }
}

class _NonoPainter extends CustomPainter {
  final NonoGame g;
  final double cell;
  final double left;
  final double top;
  final Color fill;
  final bool done;
  _NonoPainter(this.g, this.cell, this.left, this.top, this.fill, this.done);

  @override
  void paint(Canvas canvas, Size size) {
    final l = g.level;
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white.withValues(alpha: 0.92));
    final fs = cell * 0.5;
    for (var y = 0; y < l.h; y++) {
      final clue = l.rowClues[y].isEmpty ? [0] : l.rowClues[y];
      final complete = g.rowComplete(y);
      for (var k = 0; k < clue.length; k++) {
        final cx = left - (clue.length - k - 0.5) * cell * 0.7;
        paintText(canvas, '${clue[k]}', Offset(cx, top + (y + 0.5) * cell), fs,
            complete ? Colors.black26 : Colors.black87);
      }
    }
    for (var x = 0; x < l.w; x++) {
      final clue = l.colClues[x].isEmpty ? [0] : l.colClues[x];
      final complete = g.colComplete(x);
      for (var k = 0; k < clue.length; k++) {
        final cy = top - (clue.length - k - 0.5) * cell * 0.7;
        paintText(canvas, '${clue[k]}', Offset(left + (x + 0.5) * cell, cy), fs,
            complete ? Colors.black26 : Colors.black87);
      }
    }
    for (var i = 0; i < g.cells.length; i++) {
      final x = i % l.w, y = i ~/ l.w;
      final r = Rect.fromLTWH(left + x * cell, top + y * cell, cell, cell);
      if (g.cells[i] == 1) {
        canvas.drawRect(r.deflate(done ? 0 : 1), Paint()..color = fill);
      } else if (g.cells[i] == 2 && !done) {
        final p = Paint()
          ..color = Colors.black38
          ..strokeWidth = 1.5;
        canvas.drawLine(r.topLeft + Offset(cell * .25, cell * .25), r.bottomRight - Offset(cell * .25, cell * .25), p);
        canvas.drawLine(r.topRight + Offset(-cell * .25, cell * .25), r.bottomLeft + Offset(cell * .25, -cell * .25), p);
      }
    }
    if (!done) {
      for (var x = 0; x <= l.w; x++) {
        canvas.drawLine(Offset(left + x * cell, top), Offset(left + x * cell, top + l.h * cell),
            Paint()
              ..color = Colors.black54
              ..strokeWidth = x % 5 == 0 ? 2 : 0.6);
      }
      for (var y = 0; y <= l.h; y++) {
        canvas.drawLine(Offset(left, top + y * cell), Offset(left + l.w * cell, top + y * cell),
            Paint()
              ..color = Colors.black54
              ..strokeWidth = y % 5 == 0 ? 2 : 0.6);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
