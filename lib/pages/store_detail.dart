import 'package:flutter/material.dart';
import '../models/jiro_store.dart';

class StoreDetailPage extends StatelessWidget {
  const StoreDetailPage({super.key, required this.store});
  final JiroStore store;

  static const _weekdayJp = ['月', '火', '水', '木', '金', '土', '日'];

  /// 営業時間テーブル（曜日ごと）
  Widget _buildHoursTable() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(7, (i) {
        final weekday = i + 1; // 1..7
        final hours = store.hoursOf(weekday);
        final display = (hours.isEmpty) ? '休' : hours;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              SizedBox(
                width: 28,
                child: Text(
                  _weekdayJp[i],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(display)),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildChipRow() {
    final chips = <Widget>[];

    if (store.hasRenge != null) {
      chips.add(Chip(label: Text('レンゲ: ${store.hasRenge! ? 'あり' : 'なし'}')));
    }
    if (store.boilAdjustable != null) {
      chips.add(
        Chip(label: Text('麺かため可: ${store.boilAdjustable! ? '可' : '不可'}')),
      );
    }
    if ((store.seasonings ?? []).isNotEmpty) {
      chips.add(Chip(label: Text('卓上: ${store.seasonings!.join(' / ')}')));
    }
    if (store.customCall != null && store.customCall!.isNotEmpty) {
      chips.add(Chip(label: Text('マイコール: ${store.customCall}')));
    }

    if (chips.isEmpty) return const SizedBox.shrink();
    return Wrap(spacing: 8, runSpacing: 8, children: chips);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8D9),
      appBar: AppBar(title: Text(store.name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 店名
            Text(
              store.name,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // 基本情報
            _InfoRow(label: 'エリア', value: store.area),
            const SizedBox(height: 4),
            _InfoRow(label: '住所', value: store.address),
            if ((store.access ?? '').isNotEmpty) ...[
              const SizedBox(height: 4),
              _InfoRow(label: 'アクセス', value: store.access!),
            ],
            if ((store.holidayNote ?? '').isNotEmpty) ...[
              const SizedBox(height: 4),
              _InfoRow(label: '休業メモ', value: store.holidayNote!),
            ],
            const SizedBox(height: 16),

            // 営業時間
            const Text(
              '営業時間（曜日別）',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildHoursTable(),
            const SizedBox(height: 16),

            // 駐車場・メモなど
            if ((store.parkingInfo ?? '').isNotEmpty) ...[
              const SizedBox(height: 4),
              _InfoRow(label: '駐車/駐輪', value: store.parkingInfo!),
            ],
            if ((store.menu ?? '').isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'メニュー',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(store.menu!),
            ],
            const SizedBox(height: 12),

            // チップ群（レンゲ/麺硬め/卓上調味料 など）
            _buildChipRow(),
            const SizedBox(height: 16),

            // SNS
            if ((store.sns ?? {}).isNotEmpty) ...[
              const Text(
                '公式/SNS',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: (store.sns!.entries)
                    .where((e) => (e.value).toString().isNotEmpty)
                    .map((e) => Text('${e.key}: ${e.value}'))
                    .toList(),
              ),
            ],

            // 備考
            if ((store.memo ?? '').isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'メモ',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(store.memo!),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 72,
          child: Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(value)),
      ],
    );
  }
}
