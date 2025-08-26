import 'package:shared_preferences/shared_preferences.dart';

class FavoritesService {
  static const _key = 'favorite_store_names';

  static Future<Set<String>> loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? <String>[];
    return list.toSet();
  }

  static Future<Set<String>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? <String>[];
    return list.toSet();
  }

  static Future<void> _save(Set<String> names) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, names.toList());
  }

  /// その店が★かどうかの判別！
  static Future<bool> isFavorite(String storeName) async {
    final favs = await load();
    return favs.contains(storeName);
  }

  /// ★をトグルして、現在の状態（true=お気に入り）を返すやつ
  static Future<bool> toggle(String storeName) async {
    final favs = await load();
    if (favs.contains(storeName)) {
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
