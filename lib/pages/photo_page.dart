import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('今日のラーメン')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 📸 写真追加ボタン
            ElevatedButton(
              onPressed: _pickImage,
              child: const Text('写真を追加'),
            ),
            const SizedBox(height: 12),

            // 📷 選択済み画像たち
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _images
                  .map((xfile) => Image.file(
                        File(xfile.path),
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      ))
                  .toList(),
            ),
            const SizedBox(height: 24),

            // 🍜 メニュー入力
            const Text('🍜 食べたメニュー', style: TextStyle(fontWeight: FontWeight.bold)),
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
