import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'game/nonogram_catalog.dart';
import 'game/nonogram_game.dart';
import 'services/nonogram_progress.dart';
import 'services/nonogram_text.dart';

export 'game/nonogram_game.dart' show CellMark, NonogramPuzzle, cluesForLine;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const NonogramApp());
}

/// A strictly offline game: no advertising SDK, account, or analytics identifier.
class NonogramApp extends StatefulWidget {
  const NonogramApp({super.key});
  @override
  State<NonogramApp> createState() => _NonogramAppState();
}

class _NonogramAppState extends State<NonogramApp> {
  String language = 'en';
  bool dark = true;
  bool reduceMotion = false;
  NonogramProgress? storage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final store = NonogramProgress(await SharedPreferences.getInstance());
      if (!mounted) return;
      setState(() {
        storage = store;
        language = store.locale;
        dark = store.darkMode;
        reduceMotion = store.reduceMotion;
      });
    } catch (_) {
      // The game remains playable even if platform storage is unavailable.
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nonogram Logic',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: dark ? Brightness.dark : Brightness.light,
        colorSchemeSeed: const Color(0xFF6751D8),
      ),
      home: NonogramScreen(
        key: ValueKey('screen-$language'),
        storage: storage,
        language: language,
        reduceMotion: reduceMotion,
        onLanguage: (code) async {
          await storage?.setLocale(code);
          if (mounted) setState(() => language = code);
        },
        onDark: (value) async {
          await storage?.setDarkMode(value);
          if (mounted) setState(() => dark = value);
        },
        onMotion: (value) async {
          await storage?.setReduceMotion(value);
          if (mounted) setState(() => reduceMotion = value);
        },
        dark: dark,
      ),
    );
  }
}

enum PlayMode { classic, timed, zen, daily }
enum InputMode { cycle, fill, cross, erase }

class NonogramScreen extends StatefulWidget {
  const NonogramScreen({super.key, this.storage, this.language = 'en',
    this.reduceMotion = false, this.dark = true,
    this.onLanguage, this.onDark, this.onMotion});
  final NonogramProgress? storage;
  final String language;
  final bool reduceMotion;
  final bool dark;
  final ValueChanged<String>? onLanguage;
  final ValueChanged<bool>? onDark;
  final ValueChanged<bool>? onMotion;

  @override
  State<NonogramScreen> createState() => _NonogramScreenState();
}

class _NonogramScreenState extends State<NonogramScreen> {
  int level = 0;
  late NonogramPuzzle puzzle = NonogramPuzzle(NonogramCatalog.at(0).board);
  PlayMode mode = PlayMode.classic;
  InputMode inputMode = InputMode.cycle;
  bool paused = false;
  int seconds = 0;
  Timer? clock;
  String? announcement;
  bool completionRecorded = false;

  NonogramText get t => NonogramText(widget.language);
  String get saveKey => mode == PlayMode.daily
      ? 'daily.${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day}'
      : 'session.$level';

  @override
  void initState() {
    super.initState();
    clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && !paused && !puzzle.solved) {
        setState(() => seconds++);
      }
    });
    _restore();
  }

  @override
  void didUpdateWidget(covariant NonogramScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.storage != widget.storage && widget.storage != null) _restore();
  }

  void _restore() {
    final raw = widget.storage?.loadSession(saveKey);
    if (raw != null && puzzle.loadState(raw)) {
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    clock?.cancel();
    super.dispose();
  }

  Future<void> _persist() async {
    try {
      await widget.storage?.saveSession(saveKey, puzzle.saveState());
    } catch (_) {
      // No personal data is sent; storage failure must not stop gameplay.
    }
  }

  void _level(int index, {PlayMode? newMode}) {
    if (index < 0 || index >= NonogramCatalog.count) return;
    setState(() {
      if (newMode != null) mode = newMode;
      level = index;
      puzzle = NonogramPuzzle(NonogramCatalog.at(index).board);
      seconds = 0;
      inputMode = InputMode.cycle;
      paused = false;
      announcement = null;
      completionRecorded = false;
    });
    _restore();
  }

  void _changeMode(PlayMode next) {
    if (next == PlayMode.daily) {
      _level(NonogramCatalog.dailyIndex(DateTime.now()), newMode: next);
    } else {
      _level(level, newMode: next);
    }
  }

  void _tap(int r, int c) {
    if (paused || puzzle.solved) return;
    setState(() {
      switch (inputMode) {
        case InputMode.cycle:
          puzzle.cycle(r, c);
          break;
        case InputMode.fill:
          puzzle.setMark(r, c, CellMark.filled);
          break;
        case InputMode.cross:
          puzzle.setMark(r, c, CellMark.empty);
          break;
        case InputMode.erase:
          puzzle.setMark(r, c, CellMark.unknown);
          break;
      }
      announcement = null;
    });
    _persist();
    _onComplete();
  }

  Future<void> _onComplete() async {
    if (!puzzle.solved || completionRecorded) return;
    completionRecorded = true;
    try {
      if (mode == PlayMode.classic) {
        await widget.storage?.complete(level,
          moves: puzzle.taps, hints: puzzle.hintsUsed);
      }
    } catch (_) { /* Offline storage is best effort. */ }
    if (mounted) setState(() {});
  }

  void _hint() {
    if (paused || puzzle.solved) return;
    final position = puzzle.revealHint();
    setState(() => announcement = position == null ? null :
        '${t['hint']}: ${position.$1 + 1}, ${position.$2 + 1}');
    _persist();
    _onComplete();
  }

  void _reset() {
    setState(() {
      puzzle.reset();
      seconds = 0;
      paused = false;
      announcement = null;
      completionRecorded = false;
    });
    _persist();
  }

  Future<void> _chooseLevel() async {
    final selected = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (dialogContext) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(dialogContext).height * 0.65,
          child: Column(children: [
            Text(t['levels'], style: Theme.of(dialogContext).textTheme.titleLarge),
            Expanded(child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 85, childAspectRatio: 1.15,
                crossAxisSpacing: 8, mainAxisSpacing: 8),
              itemCount: NonogramCatalog.count,
              itemBuilder: (_, i) {
                final allowed = mode != PlayMode.classic ||
                    i <= (widget.storage?.highestUnlocked ?? 0);
                return FilledButton.tonal(
                  onPressed: allowed ? () => Navigator.pop(dialogContext, i) : null,
                  child: allowed ? Text('${i + 1}') :
                      const Icon(Icons.lock_outline, size: 18),
                );
              },
            )),
          ]),
        ),
      ),
    );
    if (selected != null) _level(selected);
  }

  Future<void> _settings() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(t['settings'], style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: widget.language,
              decoration: InputDecoration(labelText: t['language']),
              items: const [
                DropdownMenuItem(value: 'tr', child: Text('Türkçe')),
                DropdownMenuItem(value: 'en', child: Text('English')),
                DropdownMenuItem(value: 'ar', child: Text('العربية')),
              ],
              onChanged: (v) { if (v != null) widget.onLanguage?.call(v); },
            ),
            SwitchListTile(
              title: Text(t['dark']), value: widget.dark,
              onChanged: widget.onDark,
            ),
            SwitchListTile(
              title: Text(t['reduced']), value: widget.reduceMotion,
              onChanged: widget.onMotion,
            ),
            const SizedBox(height: 12),
            Text(t['privacy'], textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: ctx,
                  builder: (c) => AlertDialog(
                    title: Text(t['confirm']),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(c, false),
                        child: Text(t['cancel'])),
                      TextButton(onPressed: () => Navigator.pop(c, true),
                        child: Text(t['yes'])),
                    ],
                  ),
                );
                if (confirmed == true) {
                  await widget.storage?.clearAll();
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) _level(0, newMode: PlayMode.classic);
                }
              },
              icon: const Icon(Icons.delete_outline), child: Text(t['delete']),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _puzzleBoard(double availableWidth) {
    const clueWidth = 74.0;
    final boardWidth = availableWidth > 560 ? 560.0 : availableWidth;
    final cell = (boardWidth - clueWidth) / puzzle.width;
    final gridSize = cell * puzzle.width;
    return SizedBox(
      width: boardWidth,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          const SizedBox(width: clueWidth, height: 66),
          for (var c = 0; c < puzzle.width; c++)
            SizedBox(
              height: 66, width: cell,
              child: Center(child: Text(puzzle.columnClues(c).join('\n'),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: cell < 36 ? 10 : 13,
                  fontWeight: FontWeight.bold))),
            ),
        ]),
        for (var r = 0; r < puzzle.height; r++)
          Row(children: [
            SizedBox(width: clueWidth, height: cell,
              child: Center(child: FittedBox(child: Text(
                puzzle.rowClues(r).join(' '),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)))),
            ),
            for (var c = 0; c < puzzle.width; c++)
              SizedBox(width: cell, height: cell,
                child: Semantics(
                  label: 'Row ${r + 1}, column ${c + 1}, ${puzzle.marks[r][c].name}',
                  button: true,
                  child: InkWell(
                    key: ValueKey('cell-$r-$c'),
                    onTap: paused || puzzle.solved ? null : () => _tap(r, c),
                    child: AnimatedContainer(
                      duration: widget.reduceMotion ? Duration.zero :
                        const Duration(milliseconds: 120),
                      margin: EdgeInsets.all(cell < 34 ? 1 : 2),
                      decoration: BoxDecoration(
                        color: puzzle.marks[r][c] == CellMark.filled
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(cell < 34 ? 3 : 5),
                        border: Border.all(color: Theme.of(context).dividerColor),
                      ),
                      alignment: Alignment.center,
                      child: puzzle.marks[r][c] == CellMark.empty
                          ? Icon(Icons.close, size: cell * 0.55)
                          : null,
                    ),
                  ),
                ),
              ),
          ]),
        SizedBox(height: gridSize * 0.01),
      ]),
    );
  }

  Widget _tools() {
    return Wrap(alignment: WrapAlignment.center, spacing: 8, runSpacing: 8,
      children: [
        for (final type in InputMode.values)
          ChoiceChip(
            label: Text(switch(type) {
              InputMode.cycle => '● ↻',
              InputMode.fill => t['filled'],
              InputMode.cross => t['empty'],
              InputMode.erase => t['erase'],
            }),
            selected: inputMode == type,
            onSelected: (_) => setState(() => inputMode = type),
          ),
        IconButton.outlined(
          onPressed: puzzle.canUndo ? () {setState(puzzle.undo); _persist();} : null,
          tooltip: t['undo'], icon: const Icon(Icons.undo),
        ),
        IconButton.outlined(
          onPressed: puzzle.canRedo ? () {setState(puzzle.redo); _persist();} : null,
          tooltip: t['redo'], icon: const Icon(Icons.redo),
        ),
        IconButton.outlined(
          onPressed: puzzle.solved ? null : _hint,
          tooltip: t['hint'], icon: const Icon(Icons.lightbulb_outline),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isComplete = puzzle.solved;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nonogram Logic'),
        actions: [
          IconButton(onPressed: () => setState(() => paused = !paused),
            tooltip: paused ? t['resume'] : t['pause'],
            icon: Icon(paused ? Icons.play_arrow : Icons.pause)),
          IconButton(onPressed: _settings, tooltip: t['settings'],
            icon: const Icon(Icons.settings_outlined)),
        ],
      ),
      body: SafeArea(child: LayoutBuilder(builder: (context, bounds) =>
        Center(child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(t['title'], style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 6),
              Wrap(alignment: WrapAlignment.center, spacing: 8, runSpacing: 4,
                children: [
                  for (final m in PlayMode.values)
                    ChoiceChip(
                      label: Text(switch(m) {
                        PlayMode.classic => t['play'],
                        PlayMode.timed => t['timed'],
                        PlayMode.zen => t['zen'],
                        PlayMode.daily => t['daily'],
                      }),
                      selected: mode == m,
                      onSelected: (_) => _changeMode(m),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text('${t['levels']} ${level + 1}/${NonogramCatalog.count} · '
                   '${t['moves']}: ${puzzle.taps} · ${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}',
                style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(t['help'], textAlign: TextAlign.center),
              const SizedBox(height: 10),
              if (paused) Padding(
                padding: const EdgeInsets.all(24),
                child: Column(children: [
                  const Icon(Icons.pause_circle_outline, size: 64),
                  FilledButton(onPressed: () => setState(() => paused = false),
                    child: Text(t['resume'])),
                ]),
              ) else _puzzleBoard(bounds.maxWidth - 24),
              const SizedBox(height: 10),
              LinearProgressIndicator(value: puzzle.progress),
              const SizedBox(height: 10),
              Text(isComplete ? t['solved'] : 'Complete the picture to win.',
                key: const ValueKey('status')),
              if (announcement != null) Text(announcement!, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              _tools(),
              const SizedBox(height: 10),
              Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center,
                children: [
                  OutlinedButton.icon(onPressed: _reset,
                    icon: const Icon(Icons.restart_alt), child: Text(t['reset'])),
                  FilledButton.tonalIcon(
                    onPressed: _chooseLevel,
                    icon: const Icon(Icons.grid_view), label: Text(t['levels'])),
                  if (isComplete) FilledButton.icon(
                    onPressed: () => _level((level + 1) % NonogramCatalog.count),
                    icon: const Icon(Icons.arrow_forward), label: Text(t['next'])),
                ],
              ),
              const SizedBox(height: 12),
              Text('${t['progress']}: ${widget.storage?.solvedCount ?? 0} / '
                   '${NonogramCatalog.count}',
                style: Theme.of(context).textTheme.bodySmall),
            ]),
          ),
        )),
      )),
    );
  }
}
