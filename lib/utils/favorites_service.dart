// lib/utils/favorites_service.dart
import 'package:shared_preferences/shared_preferences.dart';

class FavoritesService {
  static const String _key = 'favorite_store_names';
  static SharedPreferences? _prefs;

  /// 1回だけ初期化
  static Future<void> _init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// 現在のお気に入り(Set<String>)を取得
  static Future<Set<String>> loadFavorites() async {
    await _init();
    final list = _prefs!.getStringList(_key) ?? <String>[];
    return list.toSet();
  }

  /// その店が★かどうか
  static Future<bool> isFavorite(String storeName) async {
    final favs = await loadFavorites();
    return favs.contains(storeName);
  }

  /// 保存（内部用）
  static Future<void> _save(Set<String> names) async {
    await _init();
    await _prefs!.setStringList(_key, names.toList());
  }

  /// ★をトグルして、現在の状態（true=お気に入り）を返す
  static Future<bool> toggle(String storeName) async {
    final favs = await loadFavorites();
    final isFav = favs.contains(storeName);
    if (isFav) {
      favs.remove(storeName);
      await _save(favs);
      return false;
    } else {
      favs.add(storeName);
      await _save(favs);
      return true;
    }
  }
}
