// ✅ 修正済み home_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../models/jiro_store.dart';
import '../utils/favorites_service.dart';
import 'store_detail.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<JiroStore>> _allStoresFuture;

  Set<String> _favorites = {};
  DateTime? _customDateTime; // ← 任意時刻用

  @override
  void initState() {
    super.initState();
    _allStoresFuture = _loadAllStores();
    _reloadFavorites();

    //ポップアップ表示
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showNoticeDialog();
    });
  }

  Future<void> _reloadFavorites() async {
    _favorites = await FavoritesService.loadFavorites();
    if (mounted) setState(() {});
  }

  Future<List<JiroStore>> _loadAllStores() async {
    final jsonString = await rootBundle.loadString(
      'assets/json/jiro_stores.json',
    );
    final list = (json.decode(jsonString) as List)
        .map((e) => JiroStore.fromJson(e as Map<String, dynamic>))
        .toList();
    return list;
  }

  String _formatHHmm(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  DateTime _currentDateTime() => _customDateTime ?? DateTime.now();

  Map<String, String> _statusOf(JiroStore store) {
    final now = _currentDateTime();
    final int today = now.weekday;
    final String nowHHmm = _formatHHmm(now);

    if (!store.openDays.contains(today)) {
      return {"status": "closed", "hours": ""};
    }

    final hours = store.businessHours?["$today"];
    if (hours == null || hours.isEmpty) {
      return {"status": "closed", "hours": ""};
    }

    bool isOpen = false;
    for (final slot in hours.split(',').map((s) => s.trim())) {
      final parts = slot.split('-');
      if (parts.length != 2) continue;
      final start = parts[0], end = parts[1];
      if (nowHHmm.compareTo(start) >= 0 && nowHHmm.compareTo(end) <= 0) {
        isOpen = true;
        break;
      }
    }
    return {"status": isOpen ? "open" : "break", "hours": hours};
  }

  Color _tileColor(String status) {
    switch (status) {
      case "open":
        return const Color(0xFFFFF000);
      case "break":
        return const Color(0xFFDDD000);
      default:
        return Colors.grey;
    }
  }

  void _showNoticeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ ご注意ください ⚠️', textAlign: TextAlign.center),
        content: const Text(
          '本アプリの営業時間情報はあくまで目安です\n\n'
          '・麺切れ等で早仕舞いになる場合があります\n'
          '・臨時の営業/休業もあり得ます\n'
          '・祝日は不定休な店舗も多いです\n'
          '・年末年始や大型連休は特にご注意を\n\n'
          '必ず店舗のSNSや公式情報をご確認のうえご訪問ください',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDateTime() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _currentDateTime(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (pickedDate == null) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_currentDateTime()),
    );
    if (pickedTime == null) return;

    setState(() {
      _customDateTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  Future<void> _openDetail(JiroStore store) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => StoreDetailPage(store: store)),
    );
    await _reloadFavorites();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8D9),
      appBar: AppBar(
        title: const Text('ラーメン二郎データベース'),
        actions: [
          IconButton(
            icon: const Icon(Icons.access_time),
            tooltip: '時刻を指定',
            onPressed: _pickDateTime,
          ),
          if (_customDateTime != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: '現在時刻に戻す',
              onPressed: () => setState(() => _customDateTime = null),
            ),
        ],
      ),
      body: FutureBuilder<List<JiroStore>>(
        future: _allStoresFuture,
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text('エラー発生: \${snap.error}'));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final stores = snap.data!;
          return Padding(
            padding: const EdgeInsets.all(8),
            child: GridView.count(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 2.5,
              children: stores.map((store) {
                final info = _statusOf(store);
                final color = _tileColor(info["status"]!);
                final hours = info["hours"] ?? '';
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
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            if (hours.isNotEmpty)
                              Text(
                                hours,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.black,
                                ),
                              ),
                          ],
                        ),
                      ),
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
        },
      ),
    );
  }
}
