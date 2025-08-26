import 'package:shared_preferences/shared_preferences.dart';

/// お気に入り（★）を端末ローカルに保存するだけの超シンプルなサービス。
/// すべて static に統一して、API名も load / toggle に一本化。
class FavoritesService {
  FavoritesService._();

  static const String _key = 'favorite_store_names';

  /// 保存されている★店名セットを取得
  static Future<Set<String>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? const <String>[];
    return list.toSet();
  }

  /// 内部用：セットを丸ごと保存
  static Future<void> _save(Set<String> names) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, names.toList());
  }

  /// その店が★かどうか
  static Future<bool> isFavorite(String storeName) async {
    final favs = await load();
    return favs.contains(storeName);
  }

  /// ★をトグルし、現在の状態（true=お気に入り）を返す
  static Future<bool> toggle(String storeName) async {
    final prefs = await SharedPreferences.getInstance();
    final set = (prefs.getStringList(_key) ?? <String>[]).toSet();
    final bool nowFav;
    if (set.contains(storeName)) {
      set.remove(storeName);
      nowFav = false;
    } else {
      set.add(storeName);
      nowFav = true;
    }
    await prefs.setStringList(_key, set.toList());
    return nowFav;
  }
}
