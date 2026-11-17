import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:game_007_nonogram_logic/services/nonogram_progress.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('save and load local session, unlock campaign levels', () async {
    final progress = NonogramProgress(await SharedPreferences.getInstance());
    expect(progress.highestUnlocked, 0);
    await progress.saveSession('session.0', 'test-state');
    expect(progress.loadSession('session.0'), 'test-state');
    await progress.complete(0, moves: 10, hints: 0);
    expect(progress.highestUnlocked, 1);
    expect(progress.solvedCount, 1);
    expect(progress.loadSession('session.0'), isNull);
    await progress.complete(0, moves: 7, hints: 1);
    expect(progress.solvedCount, 1);
  });

  test('preferences and wipe remain under unique namespace', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('another_app.safe', 'keep');
    final progress = NonogramProgress(prefs);
    await progress.setLocale('ar');
    await progress.setReduceMotion(true);
    await progress.setDarkMode(false);
    expect(progress.locale, 'ar');
    expect(progress.reduceMotion, isTrue);
    expect(progress.darkMode, isFalse);
    await progress.clearAll();
    expect(progress.locale, 'tr');
    expect(prefs.getString('another_app.safe'), 'keep');
  });
}
