import 'package:flutter/material.dart';
import 'pages/home_page.dart'; // ← ここ重要！

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ラーメン二郎データベース',
      theme: ThemeData(
        primarySwatch: Colors.yellow,
        scaffoldBackgroundColor: const Color(0xFFFFFBE6), // 薄黄色の背景にしても◎
        useMaterial3: true, // Material3を使う場合（好みで調整）
      ),
      home: const HomePage(), // ← ここをホームページに変更
    );
  }
}
