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

  String? _selectedYear;
  String? _selectedStore;

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
    final filtered = _records.where((entry) {
      final date = entry.value['date'] as String?;
      final store = entry.value['store'] as String?;

      final matchYear =
          _selectedYear == null || (date?.startsWith(_selectedYear!) ?? false);
      final matchStore = _selectedStore == null || store == _selectedStore;

      return matchYear && matchStore;
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('記録一覧')),
      body: Column(
        children: [
          // ▼ フィルターUI
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                // 年フィルター
                Expanded(
                  child: DropdownButton<String>(
                    value: _selectedYear,
                    hint: const Text('年で絞り込み'),
                    isExpanded: true,
                    items: _records
                        .map(
                          (e) => (e.value['date'] as String?)?.split('-').first,
                        )
                        .where((year) => year != null)
                        .toSet()
                        .map(
                          (year) =>
                              DropdownMenuItem(value: year, child: Text(year!)),
                        )
                        .toList(),
                    onChanged: (val) => setState(() => _selectedYear = val),
                  ),
                ),
                const SizedBox(width: 8),
                // 店舗フィルター
                Expanded(
                  child: DropdownButton<String>(
                    value: _selectedStore,
                    hint: const Text('店舗で絞り込み'),
                    isExpanded: true,
                    items: _records
                        .map((e) => e.value['store'] as String?)
                        .where((store) => store != null)
                        .toSet()
                        .map(
                          (store) => DropdownMenuItem(
                            value: store,
                            child: Text(store!),
                          ),
                        )
                        .toList(),
                    onChanged: (val) => setState(() => _selectedStore = val),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.clear),
                  tooltip: '絞り込み解除',
                  onPressed: () => setState(() {
                    _selectedYear = null;
                    _selectedStore = null;
                  }),
                ),
              ],
            ),
          ),

          // ▼ 記録リスト
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text('記録がありません'))
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const Divider(height: 0),
                    itemBuilder: (context, i) {
                      final entry = filtered[i];
                      final key = entry.key;
                      final data = entry.value;

                      final rawDate = data['date'];
                      final date = rawDate != null
                          ? DateTime.tryParse(
                                  rawDate,
                                )?.toLocal().toString().split(' ').first ??
                                ''
                          : '';
                      final store = data['store'] ?? '店舗不明';
                      final menu = data['menu'] ?? '';
                      final photoList = (data['photos'] as List?) ?? [];
                      final photoPath = photoList.isNotEmpty
                          ? photoList.first
                          : null;

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
                                  errorBuilder: (_, __, ___) =>
                                      const Icon(Icons.ramen_dining),
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
                              builder: (_) => AlertDialog(
                                title: const Text('削除確認'),
                                content: const Text('この記録を削除しますか？'),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('キャンセル'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
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
                        onTap: () {
                          int currentPage = 0;
                          final pageController = PageController();

                          showDialog(
                            context: context,
                            builder: (_) => StatefulBuilder(
                              builder: (context, setState) => AlertDialog(
                                title: Text(store),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (photoList.isNotEmpty)
                                      Column(
                                        children: [
                                          // ここで SizedBox でサイズをしっかり固定！
                                          SizedBox(
                                            height: 200,
                                            width: double.infinity,
                                            child: PageView.builder(
                                              controller: pageController,
                                              itemCount: photoList.length,
                                              onPageChanged: (index) {
                                                setState(
                                                  () => currentPage = index,
                                                );
                                              },
                                              itemBuilder: (context, index) {
                                                final path = photoList[index];
                                                if (kIsWeb) {
                                                  return Image.network(
                                                    path,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (_, __, ___) =>
                                                        const SizedBox.shrink(),
                                                  );
                                                } else if (File(
                                                  path,
                                                ).existsSync()) {
                                                  return Image.file(
                                                    File(path),
                                                    fit: BoxFit.cover,
                                                  );
                                                } else {
                                                  return const SizedBox.shrink();
                                                }
                                              },
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          // 🔘 ドットインジケーター
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: List.generate(
                                              photoList.length,
                                              (index) {
                                                final isActive =
                                                    index == currentPage;
                                                return Container(
                                                  margin:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 4,
                                                      ),
                                                  width: isActive ? 10 : 6,
                                                  height: isActive ? 10 : 6,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: isActive
                                                        ? Colors.black
                                                        : Colors.grey,
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        const Text('📅 '),
                                        Text('日付: $date'),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        const Text('🍜 '),
                                        Text('メニュー: $menu'),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        const Text('🔊 '),
                                        Text('コール: ${data['call'] ?? ''}'),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        const Text('📝 '),
                                        Flexible(
                                          child: Text(
                                            'メモ: ${data['memo'] ?? ''}',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('閉じる'),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
