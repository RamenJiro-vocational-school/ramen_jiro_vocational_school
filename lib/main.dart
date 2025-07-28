import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'models/jiro_store.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'ラーメン二郎アプリ', home: const StoreListPage());
  }
}

class StoreListPage extends StatefulWidget {
  const StoreListPage({super.key});

  @override
  State<StoreListPage> createState() => _StoreListPageState();
}

class _StoreListPageState extends State<StoreListPage> {
  late Future<List<JiroStore>> storesFuture;

  @override
  void initState() {
    super.initState();
    storesFuture = loadJiroStores();
  }

  Future<List<JiroStore>> loadJiroStores() async {
    final String jsonString = await rootBundle.loadString(
      'assets/json/jiro_stores.json',
    );
    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.map((json) => JiroStore.fromJson(json)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ラーメン二郎店舗一覧')),
      body: FutureBuilder<List<JiroStore>>(
        future: storesFuture,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final stores = snapshot.data!;
            return ListView.builder(
              itemCount: stores.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(stores[index].name),
                  subtitle: Text(
                    '${stores[index].area} - ${stores[index].address}',
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
