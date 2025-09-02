import 'package:flutter/material.dart';

import 'pages/home_page.dart';
import 'pages/store_list.dart';
import 'pages/stamp_rally_page.dart';
import 'pages/photo_page.dart';
import 'pages/record_list_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // いまの FavoritesService は全て static なので初期化は不要
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ラーメン二郎アプリ',
      theme: ThemeData(
        fontFamily: 'NotoSerifJP',
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFFF000)),
        useMaterial3: true,
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          selectedItemColor: Colors.black,
          unselectedItemColor: Colors.black54, // これで薄すぎない色に
          showUnselectedLabels: true,
        ),
      ),

      home: const RootTabs(),
    );
  }
}

class RootTabs extends StatefulWidget {
  const RootTabs({super.key});

  @override
  State<RootTabs> createState() => _RootTabsState();
}

class _RootTabsState extends State<RootTabs> {
  int _index = 0;

  final _pages = const [
    HomePage(), // 本日の営業状況
    StoreListPage(), // 県別一覧＋検索
    StampRallyPage(), //スタンプラリー画面
    PhotoPage(), // ラーメン記録ページ
    RecordListPage(), // 過去の記録閲覧ページ
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'ホーム'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: '店舗一覧'),
          BottomNavigationBarItem(
            icon: Icon(Icons.emoji_events),
            label: 'スタンプラリー',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.ramen_dining),
            label: 'ラーメン記録',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: '記録一覧'),
        ],
      ),
    );
  }
}
