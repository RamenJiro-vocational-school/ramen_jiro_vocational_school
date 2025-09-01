import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class RecordListPage extends StatefulWidget {
  const RecordListPage({super.key});

  @override
  State<RecordListPage> createState() => _RecordListPageState();
}

class _RecordListPageState extends State<RecordListPage> {
  List<MapEntry<String, dynamic>> _records = [];

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final allKeys = prefs.getKeys();

    final recordKeys = allKeys.where((k) => k.contains('_record')).toList();

    final loaded = <MapEntry<String, dynamic>>[];
    for (final key in recordKeys) {
      final jsonString = prefs.getString(key);
      if (jsonString == null) continue;

      try {
        final data = jsonDecode(jsonString);
        loaded.add(MapEntry(key, data));
      } catch (e) {
        debugPrint('デコード失敗: $key');
      }
    }

    loaded.sort((a, b) => b.key.compareTo(a.key));

    setState(() {
      _records = loaded;
    });
  }

  Future<void> _deleteRecord(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
    _loadRecords(); // 再読み込み
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('記録一覧')),
      body: _records.isEmpty
          ? const Center(child: Text('記録がありません'))
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: _records.length,
              separatorBuilder: (_, __) => const Divider(height: 0),
              itemBuilder: (context, i) {
                final entry = _records[i];
                final key = entry.key;
                final data = entry.value;

                final date = data['date'] ?? '';
                final store = data['store'] ?? '店舗不明';
                final menu = data['menu'] ?? '';
                final photoList = (data['photos'] as List?) ?? [];
                final photoPath = photoList.isNotEmpty ? photoList.first : null;

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 6,
                    horizontal: 12,
                  ),
                  leading: Builder(
                    builder: (context) {
                      if (photoPath != null) {
                        if (kIsWeb) {
                          return Image.network(
                            photoPath,
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 56,
                                height: 56,
                                color: Colors.grey.shade300,
                                child: const Icon(
                                  Icons.ramen_dining,
                                  color: Colors.black45,
                                ),
                              );
                            },
                          );
                        } else if (File(photoPath).existsSync()) {
                          return Image.file(
                            File(photoPath),
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                          );
                        }
                      }
                      return Container(
                        width: 56,
                        height: 56,
                        color: Colors.grey.shade300,
                        child: const Icon(
                          Icons.ramen_dining,
                          color: Colors.black45,
                        ),
                      );
                    },
                  ),
                  title: Text(store),
                  subtitle: Text('$date\n$menu'),
                  isThreeLine: true,
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    tooltip: '削除',
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('削除確認'),
                          content: const Text('この記録を削除しますか？'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('キャンセル'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('削除する'),
                            ),
                          ],
                        ),
                      );
                      if (confirmed == true) {
                        await _deleteRecord(key);
                      }
                    },
                  ),
                );
              },
            ),
    );
  }
}
