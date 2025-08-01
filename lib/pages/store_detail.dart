import 'package:flutter/material.dart';
import '../models/jiro_store.dart';

class StoreDetailPage extends StatelessWidget {
  final JiroStore store;

  const StoreDetailPage({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(store.name)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              store.name,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text("エリア: ${store.area}"),
            const SizedBox(height: 8),
            Text("住所: ${store.address}"),
            const SizedBox(height: 8),
            if (store.businessHours != null)
              Text("営業時間: ${store.businessHours}"),
          ],
        ),
      ),
    );
  }
}
