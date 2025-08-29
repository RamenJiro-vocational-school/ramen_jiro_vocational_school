import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class VisitService {
  static const String _key = 'visit_counts';
  static SharedPreferences? _prefs;

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

  /// 指定店舗の訪問回数をインクリメント（+1）
  static Future<int> incrementVisit(String storeName) async {
    final counts = await loadVisitCounts();
    final current = counts[storeName] ?? 0;
    counts[storeName] = current + 1;
    await _prefs!.setString(_key, json.encode(counts));
    return counts[storeName]!;
  }

  /// 訪問回数を取得
  static Future<int> getVisitCount(String storeName) async {
    final counts = await loadVisitCounts();
    return counts[storeName] ?? 0;
  }
}
