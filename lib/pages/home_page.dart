import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

import '../models/jiro_store.dart';
import 'store_detail.dart';
import '../utils/favorites_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<JiroStore>> allStoresFuture;

  // お気に入り（名前のSet）
  Set<String> _favorites = {};

  @override
  void initState() {
    super.initState();
    allStoresFuture = loadAllStores();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    _favorites = await FavoritesService.loadFavorites();
    if (mounted) setState(() {});
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
        return Colors.grey; // 定休
    }
  }

  Future<void> _openDetail(JiroStore store) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => StoreDetailPage(store: store)),
    );
    // 詳細で★が変わったかもしれないので再読込
    await _loadFavorites();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8D9),
      appBar: AppBar(title: const Text('ラーメン二郎データベース')),
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
                childAspectRatio: 2.5, // 横長で看板風
                children: stores.map((store) {
                  final statusInfo = getStoreStatus(store);
                  final color = getStatusColor(statusInfo["status"]);
                  final hours = statusInfo["hours"] as String? ?? '';
                  final isFav = _favorites.contains(store.name);

                  return InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _openDetail(store),
                    child: Stack(
                      children: [
                        Container(
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
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (hours.isNotEmpty)
                                Text(
                                  hours,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.black,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                        // ★バッジ（右上）
                        if (isFav)
                          Positioned(
                            right: 4,
                            top: 4,
                            child: Icon(
                              Icons.star,
                              size: 18,
                              color: Colors.orange.shade700,
                            ),
                          ),
                      ],
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
