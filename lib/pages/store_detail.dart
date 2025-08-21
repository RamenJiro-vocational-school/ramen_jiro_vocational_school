import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/jiro_store.dart';

class StoreDetailPage extends StatelessWidget {
  const StoreDetailPage({super.key, required this.store});
  final JiroStore store;

  static const _weekdayJp = ['月', '火', '水', '木', '金', '土', '日'];

  // --- URL起動共通 ---
  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(
      uri,
      mode: LaunchMode.externalApplication, // Web: 新しいタブ / 他: 外部アプリ
    )) {
      // 失敗してもアプリが落ちないように
      debugPrint('Could not launch $url');
    }
  }

  /// Googleマップ（検索）を開く
  void _openGoogleMaps() {
    if (store.lat != null && store.lng != null) {
      final url =
          'https://www.google.com/maps/search/?api=1&query=${store.lat},${store.lng}';
      _launchUrl(url);
    } else if ((store.address).isNotEmpty) {
      final url =
          'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(store.address)}';
      _launchUrl(url);
    }
  }

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

  /// レンゲ/麺固め/卓上調味料/マイコールなど
  Widget _buildChipRow() {
    final chips = <Widget>[];

    if (store.hasRenge != null) {
      chips.add(Chip(label: Text('レンゲ: ${store.hasRenge! ? 'あり' : 'なし'}')));
    }
    if (store.boilAdjustable != null) {
      chips.add(
        Chip(label: Text('麺湯で加減調整: ${store.boilAdjustable! ? '可' : '不可'}')),
      );
    }
    if ((store.seasonings ?? []).isNotEmpty) {
      chips.add(Chip(label: Text('卓上: ${store.seasonings!.join(' / ')}')));
    }
    if ((store.customCall ?? '').isNotEmpty) {
      chips.add(Chip(label: Text('マイコール: ${store.customCall}')));
    }

    if (chips.isEmpty) return const SizedBox.shrink();
    return Wrap(spacing: 8, runSpacing: 8, children: chips);
  }

  /// ミニ地図（OSM）※タップでGoogleマップを開く
  Widget _buildMiniMap() {
    if (store.lat == null || store.lng == null) return const SizedBox.shrink();

    final center = LatLng(store.lat!, store.lng!);

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        children: [
          SizedBox(
            height: 180,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: center,
                initialZoom: 16,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c'],
                  userAgentPackageName: 'com.example.app',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: center,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.location_on,
                        size: 36,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // 右下に「Googleマップで開く」ボタン
          Positioned(
            right: 8,
            bottom: 8,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black87,
                shadowColor: Colors.black26,
                elevation: 3,
              ),
              onPressed: _openGoogleMaps,
              icon: const Icon(Icons.map),
              label: const Text('Googleマップで開く'),
            ),
          ),
        ],
      ),
    );
  }

  /// SNS/公式リンク（存在するものだけボタン表示）
  Widget _buildLinks() {
    final links = <Widget>[];
    final sns = store.sns ?? {};
    void add(String label, String? url) {
      if (url != null && url.trim().isNotEmpty) {
        links.add(
          OutlinedButton.icon(
            onPressed: () => _launchUrl(url),
            icon: const Icon(Icons.open_in_new),
            label: Text(label),
          ),
        );
      }
    }

    add('公式サイト', sns['official']);
    add('X (Twitter)', sns['twitter']);
    add('Instagram', sns['instagram']);

    if (links.isEmpty) return const Text('（リンク情報なし）');
    return Wrap(spacing: 8, runSpacing: 8, children: links);
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

            // ミニ地図
            _buildMiniMap(),
            const SizedBox(height: 16),

            // 営業時間
            const Text(
              '営業時間',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildHoursTable(),
            const SizedBox(height: 16),

            // 駐車場・メモなど
            if ((store.parkingInfo ?? '').isNotEmpty) ...[
              _InfoRow(label: '駐車/駐輪', value: store.parkingInfo!),
              const SizedBox(height: 12),
            ],
            if ((store.menu ?? '').isNotEmpty) ...[
              const Text(
                'メニュー',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(store.menu!),
              const SizedBox(height: 12),
            ],

            // チップ群
            _buildChipRow(),
            const SizedBox(height: 20),

            // SNS/公式リンク
            const Text(
              '公式/SNS',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            _buildLinks(),
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
