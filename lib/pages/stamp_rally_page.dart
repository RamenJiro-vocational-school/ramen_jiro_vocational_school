import 'package:flutter/material.dart';
import '../models/jiro_store.dart';
import '../utils/visit_service.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class StampRallyPage extends StatefulWidget {
  const StampRallyPage({super.key});

  @override
  State<StampRallyPage> createState() => _StampRallyPageState();
}

class _StampRallyPageState extends State<StampRallyPage> {
  List<JiroStore> _stores = [];
  Future<void> _loadStores() async {
    final data = await rootBundle.loadString('assets/json/jiro_stores.json');
    final jsonList = json.decode(data) as List;

    final stores = jsonList.map((e) => JiroStore.fromJson(e)).toList();

    final counts = <String, int>{};
    for (final store in stores) {
      final count = await VisitService.getVisitCount(store.name);
      counts[store.name] = count;
    }

    setState(() {
      _stores = stores;
      _visitCounts = counts;
    });
  }

  Map<String, int> _visitCounts = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadStores();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('スタンプラリー')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: GridView.builder(
          itemCount: _stores.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
          ),
          itemBuilder: (context, index) {
            final store = _stores[index];
            final count = _visitCounts[store.name] ?? 0;

            return Container(
              decoration: BoxDecoration(
                color: Colors.yellow.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Stack(
                children: [
                  Center(
                    child: Text(
                      store.name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (count > 0)
                    Positioned(
                      right: 4,
                      top: 4,
                      child: CircleAvatar(
                        radius: 12,
                        backgroundColor: Colors.red,
                        child: Text(
                          '$count',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
