import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/jiro_store.dart';
import 'store_detail.dart';
import 'store_list.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<JiroStore>> allStoresFuture;

  @override
  void initState() {
    super.initState();
    allStoresFuture = loadAllStores();
  }

  Future<List<JiroStore>> loadAllStores() async {
    final String jsonString = await rootBundle.loadString(
      'assets/json/jiro_stores.json',
    );
    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.map((json) => JiroStore.fromJson(json)).toList();
  }

  String getCurrentTimeString() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  /// 状態を返す（営業中、休憩中、定休日）
  Map<String, dynamic> getStoreStatus(JiroStore store) {
    final int today = DateTime.now().weekday; // 月曜:1〜日曜:7
    final String currentTime = getCurrentTimeString();

    if (!store.openDays.contains(today)) {
      return {"status": "closed", "hours": ""};
    }

    final hours = store.businessHours?["$today"];
    if (hours == null || hours.isEmpty) {
      return {"status": "closed", "hours": ""};
    }

    final timeSlots = hours.split(',').map((slot) => slot.trim()).toList();
    bool isOpen = false;

    for (var slot in timeSlots) {
      final parts = slot.split('-');
      if (parts.length != 2) continue;
      final start = parts[0];
      final end = parts[1];
      if (currentTime.compareTo(start) >= 0 &&
          currentTime.compareTo(end) <= 0) {
        isOpen = true;
        break;
      }
    }

    final status = isOpen ? "open" : "break";
    return {"status": status, "hours": hours};
  }

  Color getStatusColor(String status) {
    switch (status) {
      case "open":
        return const Color(0xFFFFF000); // 明るい黄色
      case "break":
        return const Color(0xFFDDD000); // 暗めの黄色
      default:
        return Colors.grey[400]!; // グレー
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8D9),
      appBar: AppBar(
        title: const Text('ラーメン二郎データベース'),
        actions: [
          IconButton(
            tooltip: '店舗一覧（エリア別）',
            icon: const Icon(Icons.list_alt),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const StoreListPage()),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<List<JiroStore>>(
        future: allStoresFuture,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final stores = snapshot.data!;
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: GridView.count(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 2.5,
                children: stores.map((store) {
                  final statusInfo = getStoreStatus(store);
                  final color = getStatusColor(statusInfo["status"]);
                  final hours = statusInfo["hours"];

                  return GestureDetector(
                    onTap: () {
                      // 詳細ページへ遷移
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => StoreDetailPage(store: store),
                        ),
                      );
                    },
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            store.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (hours.isNotEmpty)
                            Text(
                              hours,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.black,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            );
          } else if (snapshot.hasError) {
            return Center(child: Text('エラー発生: ${snapshot.error}'));
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}
