import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/jiro_store.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<JiroStore>> todayOpenStoresFuture;

  @override
  void initState() {
    super.initState();
    todayOpenStoresFuture = loadTodayOpenStores();
  }

  Future<List<JiroStore>> loadTodayOpenStores() async {
    final String jsonString = await rootBundle.loadString(
      'assets/json/jiro_stores.json',
    );
    final List<dynamic> jsonList = json.decode(jsonString);
    final List<JiroStore> allStores = jsonList
        .map((json) => JiroStore.fromJson(json))
        .toList();

    // 今日の曜日（例：Monday）
    final String today = DateTime.now().weekday.toString(); // 1〜7（月〜日）

    return allStores.where((store) {
      return store.openDays.contains(today);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ラーメン二郎データベース')),
      body: FutureBuilder<List<JiroStore>>(
        future: todayOpenStoresFuture,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final stores = snapshot.data!;
            if (stores.isEmpty) {
              return const Center(child: Text('本日営業している店舗はありません'));
            }
            return ListView.builder(
              itemCount: stores.length,
              itemBuilder: (context, index) {
                final store = stores[index];
                return Card(
                  child: ListTile(
                    title: Text(store.name),
                    subtitle: Text(store.address),
                  ),
                );
              },
            );
          } else if (snapshot.hasError) {
            return Center(child: Text('エラー発生: ${snapshot.error}'));
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}
