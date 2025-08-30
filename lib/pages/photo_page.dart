import 'package:flutter/material.dart';

class PhotoPage extends StatefulWidget {
  const PhotoPage({super.key});

  @override
  State<PhotoPage> createState() => _PhotoPageState();
}

class _PhotoPageState extends State<PhotoPage> {
  final List<Image> _images = [];
  final TextEditingController _menuController = TextEditingController();
  final TextEditingController _callController = TextEditingController();
  final TextEditingController _memoController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('訪問記録'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 写真追加セクション
            const Text('📷 ラーメン写真（最大4枚）', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ..._images.map((img) => SizedBox(width: 80, height: 80, child: img)),
                if (_images.length < 4)
                  GestureDetector(
                    onTap: () {
                      // 画像追加ロジック（後で実装）
                    },
                    child: Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey.shade300,
                      child: const Icon(Icons.add_a_photo),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),

            // メニュー入力欄
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

            // コール入力欄
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

            // メモ欄
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
