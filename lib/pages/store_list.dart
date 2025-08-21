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
  late Future<Map<String, List<JiroStore>>> groupedFuture;

  @override
  void initState() {
    super.initState();
    groupedFuture = _loadAndGroup();
  }

  Future<Map<String, List<JiroStore>>> _loadAndGroup() async {
    final raw = await rootBundle.loadString('assets/json/jiro_stores.json');
    final list = (json.decode(raw) as List)
        .map((e) => JiroStore.fromJson(e as Map<String, dynamic>))
        .toList();

    // area でグルーピング（表示順のためにソート）
    list.sort((a, b) {
      final c = a.area.compareTo(b.area);
      if (c != 0) return c;
      return a.name.compareTo(b.name);
    });

    final Map<String, List<JiroStore>> grouped = {};
    for (final s in list) {
      grouped.putIfAbsent(s.area, () => []).add(s);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8D9),
      appBar: AppBar(title: const Text('店舗一覧（エリア別）')),
      body: FutureBuilder<Map<String, List<JiroStore>>>(
        future: groupedFuture,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('読み込みエラー: ${snap.error}'));
          }
          final grouped = snap.data!;
          final areas = grouped.keys.toList();

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: areas.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final area = areas[index];
              final stores = grouped[area]!;
              return _AreaSection(area: area, stores: stores);
            },
          );
        },
      ),
    );
  }
}

class _AreaSection extends StatelessWidget {
  const _AreaSection({required this.area, required this.stores});

  final String area;
  final List<JiroStore> stores;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // セクション見出し
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF000),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              area,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(height: 8),
          // 店舗カード（3列グリッド）
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: stores.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 2.2,
            ),
            itemBuilder: (context, i) {
              final s = stores[i];
              return InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => StoreDetailPage(store: s),
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
                    s.name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
