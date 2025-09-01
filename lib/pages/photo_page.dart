import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import 'package:flutter/foundation.dart'; // Webかどうか判定するやつ

class PhotoPage extends StatefulWidget {
  const PhotoPage({super.key});

  @override
  State<PhotoPage> createState() => _PhotoPageState();
}

class _PhotoPageState extends State<PhotoPage> {
  final List<XFile> _images = [];

  final TextEditingController _menuController = TextEditingController();
  final TextEditingController _callController = TextEditingController();
  final TextEditingController _memoController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  List<String> _storeNames = [];
  String? _selectedStore;

  @override
  void initState() {
    super.initState();
    _loadStores();
  }

  Future<void> _loadStores() async {
    final data = await rootBundle.loadString('assets/json/jiro_stores.json');
    final jsonList = json.decode(data) as List;
    final names = jsonList.map((e) => e['name'] as String).toList();

    setState(() {
      _storeNames = names;
      _selectedStore = names.first;
    });

    _loadData();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null && _images.length < 4) {
      setState(() {
        _images.add(picked);
      });
    }
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveData() async {
    if (_selectedStore == null) return;

    final prefs = await SharedPreferences.getInstance();
    final key = _generateKey('record');

    final imagePaths = _images.map((x) => x.path).toList();

    final record = {
      'store': _selectedStore,
      'photos': imagePaths,
      'menu': _menuController.text,
      'call': _callController.text,
      'memo': _memoController.text,
      'date': _selectedDate.toIso8601String(),
    };

    await prefs.setString(key, jsonEncode(record));

    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('保存しました')));
  }

  Future<void> _loadData() async {
    if (_selectedStore == null) return;

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
      if (data['date'] != null) {
        _selectedDate = DateTime.tryParse(data['date']) ?? DateTime.now();
      }
    });
  }

  String _generateKey(String suffix) {
    final dateString =
        '${_selectedDate.year}-${_selectedDate.month}-${_selectedDate.day}';
    return 'jiro_${dateString}_${_selectedStore}_$suffix';
  }

  @override
  void dispose() {
    _menuController.dispose();
    _callController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedStore == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('今日のラーメン'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: '保存する',
            onPressed: _saveData,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('🏪 店舗名', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            DropdownButton<String>(
              value: _selectedStore,
              isExpanded: true,
              onChanged: (value) {
                setState(() {
                  _selectedStore = value;
                  _loadData();
                });
              },
              items: _storeNames.map((name) {
                return DropdownMenuItem(value: name, child: Text(name));
              }).toList(),
            ),
            const SizedBox(height: 16),

            const Text('📅 訪問日', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            InkWell(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${_selectedDate.year}/${_selectedDate.month}/${_selectedDate.day}',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 16),

            ElevatedButton(onPressed: _pickImage, child: const Text('写真を追加')),
            const SizedBox(height: 12),

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
                  child: kIsWeb
                      ? Image.network(
                          xfile.path,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        )
                      : Image.file(
                          File(xfile.path),
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

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
