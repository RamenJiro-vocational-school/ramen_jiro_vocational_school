import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';


class PhotoPage extends StatefulWidget {
  final String storeName;
  const PhotoPage({super.key, required this.storeName});

  @override
  State<PhotoPage> createState() => _PhotoPageState();
}

class _PhotoPageState extends State<PhotoPage> {
  final List<XFile> _images = [];

Future<void> _saveData() async {
  final prefs = await SharedPreferences.getInstance();
  final key = _generateKey('record');

  final imagePaths = _images.map((x) => x.path).toList();

  final record = {
    'photos': imagePaths,
    'menu': _menuController.text,
    'call': _callController.text,
    'memo': _memoController.text,
  };

  await prefs.setString(key, jsonEncode(record));
}

// 任意のキーを作る（店舗名と日付から）
String _generateKey(String suffix) {
  final now = DateTime.now();
  final dateString = '${now.year}-${now.month}-${now.day}';
  return 'jiro_${dateString}_${widget.storeName}_$suffix';
}

Future<void> _loadData() async {
  final prefs = await SharedPreferences.getInstance();
  final key = _generateKey('record');

  final jsonString = prefs.getString(key);
  if (jsonString == null) return;

  final data = jsonDecode(jsonString);
  final imagePaths = List<String>.from(data['photos'] ?? []);

  setState(() {
    _images.clear();
    _images.addAll(imagePaths.map((path) => XFile(path)));
    _menuController.text = data['menu'] ?? '';
    _callController.text = data['call'] ?? '';
    _memoController.text = data['memo'] ?? '';
  });
}


  final TextEditingController _menuController = TextEditingController();
  final TextEditingController _callController = TextEditingController();
  final TextEditingController _memoController = TextEditingController();

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null && _images.length < 4) {
      setState(() {
        _images.add(picked);
      });
    }
  }

  @override
  void dispose() {
    _menuController.dispose();
    _callController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadData(); // ← データ読み込み用
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('今日のラーメン'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: '保存する',
            onPressed: () async {
              await _saveData();
              if (!context.mounted) return;
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('保存しました')));
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 📸 写真追加ボタン
            ElevatedButton(onPressed: _pickImage, child: const Text('写真を追加')),
            const SizedBox(height: 12),

            // 📷 選択済み画像たち（タップで削除）
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _images.asMap().entries.map((entry) {
                final index = entry.key;
                final xfile = entry.value;

                return GestureDetector(
                  onTap: () async {
                    final shouldDelete = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('写真の削除'),
                        content: const Text('この写真を削除しますか？'),
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

                    if (shouldDelete == true) {
                      setState(() {
                        _images.removeAt(index);
                      });
                    }
                  },
                  child: Image.file(
                    File(xfile.path),
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // 🍜 メニュー入力
            const Text(
              '🍜 食べたメニュー',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _menuController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: '例：小ラーメン、生たまご追加トッピングなど',
              ),
            ),
            const SizedBox(height: 24),

            // 🔊 コール入力
            const Text('🔊 コール', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            TextField(
              controller: _callController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: '例：アブラカラメ',
              ),
            ),
            const SizedBox(height: 24),

            // 📝 メモ
            const Text('📝 メモ', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            TextField(
              controller: _memoController,
              maxLines: 4,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: '味の感想や印象を記録しよう！',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
