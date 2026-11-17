import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Local-only persistence. No SDK ad identifiers, account IDs or telemetry.
class NonogramProgress {
  NonogramProgress(this.preferences);
  final SharedPreferences preferences;
  static const _root = 'nonogram.v1.';

  int get highestUnlocked => preferences.getInt('${_root}unlocked') ?? 0;
  int get solvedCount => preferences.getInt('${_root}solved') ?? 0;
  int get bestStreak => preferences.getInt('${_root}streak') ?? 0;
  String get locale => preferences.getString('${_root}locale') ?? 'tr';
  bool get reduceMotion => preferences.getBool('${_root}reduce_motion') ?? false;
  bool get sounds => preferences.getBool('${_root}sounds') ?? true;
  bool get darkMode => preferences.getBool('${_root}dark') ?? true;

  String? loadSession(String key) => preferences.getString('$_root$key');
  Future<bool> saveSession(String key, String data) =>
      preferences.setString('$_root$key', data);
  Future<void> complete(int level, {required int moves, required int hints}) async {
    final id = '$_root' 'completed.$level';
    if (!preferences.containsKey(id)) {
      await preferences.setInt('${_root}solved', solvedCount + 1);
    }
    await preferences.setString(id, jsonEncode({'moves': moves, 'hints': hints}));
    if (level >= highestUnlocked) {
      await preferences.setInt('${_root}unlocked', level + 1);
    }
    await preferences.remove('${_root}session.$level');
  }

  Future<void> setLocale(String value) => preferences.setString('${_root}locale', value);
  Future<void> setReduceMotion(bool value) =>
      preferences.setBool('${_root}reduce_motion', value);
  Future<void> setSounds(bool value) => preferences.setBool('${_root}sounds', value);
  Future<void> setDarkMode(bool value) => preferences.setBool('${_root}dark', value);

  Future<void> clearAll() async {
    final keys = preferences.getKeys().where((k) => k.startsWith(_root)).toList();
    for (final key in keys) {
      await preferences.remove(key);
    }
  }
}
