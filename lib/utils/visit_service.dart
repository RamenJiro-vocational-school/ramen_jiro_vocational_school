import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class VisitService {
  static const String _key = 'visit_counts';
  static SharedPreferences? _prefs;
  static const String _keyPrefix = 'visit_count_';

  static Future<void> _init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// 訪問回数のマップを読み込む
  static Future<Map<String, int>> loadVisitCounts() async {
    await _init();
    final jsonString = _prefs!.getString(_key);
    if (jsonString == null) return {};
    final Map<String, dynamic> map = json.decode(jsonString);
    return map.map((key, value) => MapEntry(key, value as int));
  }

  // 訪問回数+1
  static Future<int> incrementVisit(String storeName) async {
    await _init();
    final key = _keyPrefix + storeName;
    int count = _prefs!.getInt(key) ?? 0;
    count++;
    await _prefs!.setInt(key, count);
    return count;
  }

  // 訪問回数-1
  static Future<int> decrementVisit(String storeName) async {
    await _init();
    final key = _keyPrefix + storeName;
    int count = _prefs!.getInt(key) ?? 0;
    count = (count > 0) ? count - 1 : 0;
    await _prefs!.setInt(key, count);
    return count;
  }

  /// 訪問回数を取得
  static Future<int> getVisitCount(String storeName) async {
    await _init();
    final key = _keyPrefix + storeName;
    return _prefs!.getInt(key) ?? 0;
  }

  static Future<void> resetAllVisits() async {
    await _init();
    final keys = _prefs!.getKeys();
    for (final key in keys) {
      if (key.startsWith(_keyPrefix)) {
        await _prefs!.remove(key);
      }
    }
  }
}
