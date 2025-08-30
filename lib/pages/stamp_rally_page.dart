import 'package:flutter/material.dart';
import '../models/jiro_store.dart';
import '../utils/visit_service.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class StampRallyPage extends StatefulWidget {
  const StampRallyPage({super.key});

  @override
  State<StampRallyPage> createState() => _StampRallyPageState();
}

class _StampRallyPageState extends State<StampRallyPage> {
  List<JiroStore> _stores = [];
  Future<void> _loadStores() async {
    final data = await rootBundle.loadString('assets/json/jiro_stores.json');
    final jsonList = json.decode(data) as List;

    final stores = jsonList.map((e) => JiroStore.fromJson(e)).toList();

    final counts = <String, int>{};
    for (final store in stores) {
      final count = await VisitService.getVisitCount(store.name);
      counts[store.name] = count;
    }

    setState(() {
      _stores = stores;
      _visitCounts = counts;
      _checkCompletion();
    });
  }

  void _checkCompletion() {
    final visitedCount = _visitCounts.values.where((v) => v > 0).length;
    final total = _stores.length;

    setState(() {
      _visitedTotal = visitedCount;
    });

    if (visitedCount == total) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('🎉 スタンプラリー制覇！'),
          content: const Text('全店舗を訪問しました！おめでとうございます！'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('閉じる'),
            ),
          ],
        ),
      );
    }
  }

  Map<String, int> _visitCounts = {};

  int _visitedTotal = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadStores();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'ラーメン二郎スタンプラリー',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'スタンプをリセット',
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('リセット確認'),
                  content: const Text('すべてのスタンプをリセットしますか？'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('キャンセル'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );

              if (confirmed == true) {
                await VisitService.resetAllVisits();
                await _loadStores(); // ← 状態を再取得して更新
              }
            },
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_stores.length} 店舗中 $_visitedTotal 店舗訪問済み',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: GridView.builder(
                itemCount: _stores.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 6,
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 6,
                  childAspectRatio: 1.4, // ← 高さ・幅の比率
                ),
                itemBuilder: (context, index) {
                  final store = _stores[index];
                  final count = _visitCounts[store.name] ?? 0;
                  final isVisited = count > 0;

                  return Container(
                    decoration: BoxDecoration(
                      color: isVisited
                          ? const Color.fromARGB(255, 242, 255, 0)
                          : Colors.yellow.shade200,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: isVisited ? const Color.fromARGB(205, 0, 0, 0) : Colors.grey.shade400,
                        width: 1,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Stack(
                      children: [
                        Center(
                          child: Text(
                            store.name,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isVisited
                                  ? const Color.fromARGB(255, 0, 0, 0)
                                  : Colors.black87,
                            ),
                          ),
                        ),
                        if (count > 0)
                          Positioned(
                            right: 4,
                            top: 4,
                            child: CircleAvatar(
                              radius: 8,
                              backgroundColor: Colors.red,
                              child: Text(
                                '$count',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
