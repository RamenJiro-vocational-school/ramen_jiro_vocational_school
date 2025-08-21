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
        .map((e) => JiroStore.fromJson(e))
        .toList();

    // エリア(都道府県)一覧を動的に生成
    final areas = list.map((e) => e.area).toSet().toList()..sort();
    setState(() {
      _areas = ['すべて', ...areas];
    });
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8D9),
      appBar: AppBar(title: const Text('店舗一覧（エリア別）')),
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
              ? all
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
