import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../models/jiro_store.dart';
import 'store_detail.dart';

class StoreListPage extends StatefulWidget {
  const StoreListPage({super.key});

  @override
  State<StoreListPage> createState() => _StoreListPageState();
}

class _StoreListPageState extends State<StoreListPage> {
  late Future<List<JiroStore>> _allStoresFuture;

  // 検索で即使えるようキャッシュも保持
  List<JiroStore> _allStoresCache = [];

  String _selectedArea = 'すべて';
  List<String> _areas = const [];

  @override
  void initState() {
    super.initState();
    _allStoresFuture = _loadAllStores();
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

    // エリア(都道府県)一覧を動的に生成
    final areas = list.map((e) => e.area).toSet().toList()..sort();
    setState(() {
      _areas = ['すべて', ...areas];
    });
    return list;
  }

  // 検索UIを開く
  Future<void> _openSearch() async {
    // キャッシュが空のときは読み込み完了を待つ
    if (_allStoresCache.isEmpty) {
      final loaded = await _allStoresFuture;
      _allStoresCache = loaded;
    }
    if (!mounted) return;

    await showSearch<JiroStore?>(
      context: context,
      delegate: StoreSearchDelegate(allStores: _allStoresCache),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8D9),
      appBar: AppBar(
        title: const Text('店舗一覧（エリア別）'),
        actions: [
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

          final all = snapshot.data!;
          final filtered = (_selectedArea == 'すべて')
              ? List<JiroStore>.from(all)
              : all.where((s) => s.area == _selectedArea).toList();

          // 店名順で並べ替え（お好みで）
          filtered.sort((a, b) => a.name.compareTo(b.name));

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
                      return InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => StoreDetailPage(store: store),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF000),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(horizontal: 6),
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
            );
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
