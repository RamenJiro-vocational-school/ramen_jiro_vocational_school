import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/jiro_store.dart';
import 'store_detail.dart';

class StoreListPage extends StatefulWidget {
  const StoreListPage({super.key});

  @override
  State<StoreListPage> createState() => _StoreListPageState();
}

class _StoreListPageState extends State<StoreListPage> {
  late Future<List<JiroStore>> _allStoresFuture;

  // 検索やフィルタで使うキャッシュ
  List<JiroStore> _allStoresCache = [];

  // エリア選択
  String _selectedArea = 'すべて';
  List<String> _areas = const [];

  // お気に入り
  Set<String> _favorites = {};
  bool _onlyFavorites = false;

  @override
  void initState() {
    super.initState();
    _allStoresFuture = _loadAllStores();
    _loadFavorites();
  }

  Future<List<JiroStore>> _loadAllStores() async {
    final jsonString = await rootBundle.loadString(
      'assets/json/jiro_stores.json',
    );
    final list = (json.decode(jsonString) as List)
        .map((e) => JiroStore.fromJson(e as Map<String, dynamic>))
        .toList();

    // キャッシュ
    _allStoresCache = List<JiroStore>.from(list);

    // エリア一覧を動的に生成
    final areas = list.map((e) => e.area).toSet().toList()..sort();
    setState(() {
      _areas = ['すべて', ...areas];
    });
    return list;
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('favorites') ?? <String>[];
    setState(() {
      _favorites = list.toSet();
    });
  }

  // 検索UIを開く
  Future<void> _openSearch() async {
    if (_allStoresCache.isEmpty) {
      final loaded = await _allStoresFuture;
      _allStoresCache = loaded;
    }
    if (!mounted) return;

    await showSearch<JiroStore?>(
      context: context,
      delegate: StoreSearchDelegate(allStores: _allStoresCache),
    );
    // （検索結果から遷移→戻ってきた後に）お気に入りの変化を反映
    if (mounted) _loadFavorites();
  }

  // 詳細から戻ってきたら★を取り直す
  Future<void> _openDetail(JiroStore store) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => StoreDetailPage(store: store)),
    );
    if (mounted) _loadFavorites();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8D9),
      appBar: AppBar(
        title: const Text('店舗一覧（エリア別）'),
        actions: [
          IconButton(
            tooltip: _onlyFavorites ? 'すべて表示' : 'お気に入りだけ表示',
            icon: Icon(_onlyFavorites ? Icons.star : Icons.star_border),
            onPressed: () => setState(() => _onlyFavorites = !_onlyFavorites),
          ),
          IconButton(
            tooltip: '店舗検索',
            icon: const Icon(Icons.search),
            onPressed: _openSearch,
          ),
        ],
      ),
      body: FutureBuilder<List<JiroStore>>(
        future: _allStoresFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('エラー: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          // 基本リスト
          final all = snapshot.data!;

          // エリア絞り
          List<JiroStore> filtered = (_selectedArea == 'すべて')
              ? List<JiroStore>.from(all)
              : all.where((s) => s.area == _selectedArea).toList();

          // お気に入り絞り
          if (_onlyFavorites) {
            filtered = filtered
                .where((s) => _favorites.contains(s.name))
                .toList();
          }

          // 並び順（創業順にしたいなら JSON の順番を維持するのでソート無し）
          // store.name 順にしたい場合は↓を有効化
          // filtered.sort((a, b) => a.name.compareTo(b.name));

          return Column(
            children: [
              // エリアフィルタ（横スクロールのチップ）
              SizedBox(
                height: 56,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (context, i) {
                    final area = _areas[i];
                    final selected = area == _selectedArea;
                    return ChoiceChip(
                      label: Text(area),
                      selected: selected,
                      onSelected: (_) => setState(() => _selectedArea = area),
                      selectedColor: const Color(0xFFFFF000),
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemCount: _areas.length,
                ),
              ),

              const Divider(height: 1),

              // グリッド表示（ホームと同じ看板タイル）
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 2.5,
                        ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final store = filtered[index];
                      final isFav = _favorites.contains(store.name);

                      return InkWell(
                        onTap: () => _openDetail(store),
                        borderRadius: BorderRadius.circular(12),
                        child: Stack(
                          children: [
                            // 看板タイル
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF000),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.center,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                              ),
                              child: Text(
                                store.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            // 右上に★バッジ
                            if (isFav)
                              Positioned(
                                top: 4,
                                right: 4,
                                child: Icon(
                                  Icons.star,
                                  size: 18,
                                  color: Colors.orange.shade700,
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// 検索デリゲート（店名・かな・エリアを対象）
class StoreSearchDelegate extends SearchDelegate<JiroStore?> {
  StoreSearchDelegate({required this.allStores})
    : super(searchFieldLabel: '店名・かな・エリアで検索');

  final List<JiroStore> allStores;

  @override
  List<Widget>? buildActions(BuildContext context) => [
    if (query.isNotEmpty)
      IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
  ];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
    icon: const Icon(Icons.arrow_back),
    onPressed: () => close(context, null),
  );

  @override
  Widget buildResults(BuildContext context) => _buildList(context);
  @override
  Widget buildSuggestions(BuildContext context) => _buildList(context);

  Widget _buildList(BuildContext context) {
    final q = query.trim();
    final lower = q.toLowerCase();

    final results = allStores.where((s) {
      if (q.isEmpty) return true;
      final name = s.name.toLowerCase();
      final area = s.area.toLowerCase();
      final kana = (s.kana ?? '').toLowerCase();
      return name.contains(lower) ||
          area.contains(lower) ||
          kana.contains(lower);
    }).toList();

    if (results.isEmpty) {
      return const Center(child: Text('該当する店舗がありません'));
    }

    return ListView.separated(
      itemCount: results.length,
      separatorBuilder: (_, __) => const Divider(height: 0),
      itemBuilder: (context, i) {
        final s = results[i];
        return ListTile(
          title: _highlight(s.name, lower),
          subtitle: Text('${s.area}｜${s.address}'),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => StoreDetailPage(store: s)),
            ).then((_) {
              // 検索画面から戻ってきた後、呼び出し元でお気に入りを更新させたいときは
              // close(context, s); などで結果を返してもOK
            });
          },
        );
      },
    );
  }

  // クエリに一致する部分を太字に
  Widget _highlight(String text, String lowerQuery) {
    if (lowerQuery.isEmpty) return Text(text);
    final lowerText = text.toLowerCase();
    final start = lowerText.indexOf(lowerQuery);
    if (start < 0) return Text(text);

    final end = start + lowerQuery.length;
    return RichText(
      text: TextSpan(
        style: const TextStyle(color: Colors.black, fontSize: 16),
        children: [
          TextSpan(text: text.substring(0, start)),
          TextSpan(
            text: text.substring(start, end),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          TextSpan(text: text.substring(end)),
        ],
      ),
    );
  }
}
