import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class RecordListPage extends StatefulWidget {
  const RecordListPage({super.key});

  @override
  State<RecordListPage> createState() => _RecordListPageState();
}

class _RecordListPageState extends State<RecordListPage> {
  List<Map<String, dynamic>> _records = [];

  @override
  void initState() {
    super.initState();
    _loadAllRecords();
  }

  Future<void> _loadAllRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();

    final records = <Map<String, dynamic>>[];

    for (final key in keys) {
      if (key.startsWith('jiro_') && key.endsWith('_record')) {
        final jsonStr = prefs.getString(key);
        if (jsonStr != null) {
          final data = jsonDecode(jsonStr);
          records.add({
            'key': key,
            'store': key.split('_')[2],
            'date': key.split('_')[1],
            'menu': data['menu'] ?? '',
            'call': data['call'] ?? '',
            'memo': data['memo'] ?? '',
          });
        }
      }
    }

    // 最新日付順に並べ替え
    records.sort((a, b) => b['date'].compareTo(a['date']));

    setState(() {
      _records = records;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('記録一覧')),
      body: _records.isEmpty
          ? const Center(child: Text('記録が見つかりません'))
          : ListView.separated(
              itemCount: _records.length,
              separatorBuilder: (_, __) => const Divider(height: 0),
              itemBuilder: (context, index) {
                final record = _records[index];
                return ListTile(
                  title: Text('${record['date']}｜${record['store']}'),
                  subtitle: Text('🍜 ${record['menu']} / 🔊 ${record['call']}'),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: Text('${record['store']}（${record['date']}）'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('🍜 メニュー: ${record['menu']}'),
                            Text('🔊 コール: ${record['call']}'),
                            Text('📝 メモ:\n${record['memo']}'),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('閉じる'),
                          )
                        ],
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
