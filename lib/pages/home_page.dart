// lib/pages/home_page.dart
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('本日の営業店舗')),
      body: Center(child: Text('ここに今日営業中の店舗一覧を表示')),
    );
  }
}
