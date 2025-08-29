import 'package:flutter/material.dart';
import '../models/jiro_store.dart';
import '../utils/visit_service.dart';

class StampRallyPage extends StatefulWidget {
  const StampRallyPage({super.key});

  @override
  State<StampRallyPage> createState() => _StampRallyPageState();
}

class _StampRallyPageState extends State<StampRallyPage> {
  // 仮データ（あとで全部の店舗データ読み込むようにする）
  final List<JiroStore> _dummyStores = [
    JiroStore(
      name: '三田本店',
      area: '東京',
      address: '',
      openDays: [1, 2, 3, 4, 5],
      businessHours: {'1': '11:00-14:00'},
    ),
    JiroStore(
      name: '目黒',
      area: '東京',
      address: '',
      openDays: [1, 2, 3, 4, 5],
      businessHours: {'1': '11:00-15:00'},
    ),
    JiroStore(
      name: '仙川',
      area: '東京',
      address: '',
      openDays: [1, 2, 3, 4, 5],
      businessHours: {'1': '11:00-16:00'},
    ),
  ];

  Map<String, int> _visitCounts = {};

  @override
  void initState() {
    super.initState();
    _loadVisitData();
  }

  Future<void> _loadVisitData() async {
    final counts = <String, int>{};
    for (final store in _dummyStores) {
      final count = await VisitService.getVisitCount(store.name);
      counts[store.name] = count;
    }
    setState(() => _visitCounts = counts);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('スタンプラリー')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: GridView.builder(
          itemCount: _dummyStores.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
          ),
          itemBuilder: (context, index) {
            final store = _dummyStores[index];
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
