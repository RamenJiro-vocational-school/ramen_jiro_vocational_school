class JiroStore {
  final String name;
  final String? kana;
  final String area;
  final String address;

  /// 月:1〜日:7
  final List<int> openDays;

  /// 例: { "1": "11:00-14:30, 17:00-21:00", ... }
  final Map<String, String>? businessHours;

  final String? holidayNote;
  final double? lat;
  final double? lng;
  final String? access;

  /// 例: { "twitter": "...", "instagram": "...", "official": "..." }
  final Map<String, String>? sns;

  final String? menu;
  final String? image;
  final bool? hasRenge;
  final List<String>? seasonings;
  final bool? boilAdjustable;
  final String? parkingInfo;
  final String? memo;
  final bool? stamp;
  final bool? visited;
  final String? customCall;

  JiroStore({
    required this.name,
    this.kana,
    required this.area,
    required this.address,
    required this.openDays,
    this.businessHours,
    this.holidayNote,
    this.lat,
    this.lng,
    this.access,
    this.sns,
    this.menu,
    this.image,
    this.hasRenge,
    this.seasonings,
    this.boilAdjustable,
    this.parkingInfo,
    this.memo,
    this.stamp,
    this.visited,
    this.customCall,
  });

  factory JiroStore.fromJson(Map<String, dynamic> json) {
    Map<String, String>? _hours;
    if (json['business_hours'] != null) {
      // 動的 → Map<String, String> へ安全に変換
      _hours = (json['business_hours'] as Map).map(
        (k, v) => MapEntry(k.toString(), v?.toString() ?? ''),
      );
    }

    return JiroStore(
      name: json['name'] ?? '',
      kana: json['kana'],
      area: json['area'] ?? '',
      address: json['address'] ?? '',
      openDays: (json['openDays'] as List<dynamic>? ?? [])
          .map((e) => int.tryParse(e.toString()) ?? 0)
          .where((e) => e >= 1 && e <= 7)
          .toList(),
      businessHours: _hours,
      holidayNote: json['holidayNote'],
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
      access: json['access'],
      sns: (json['sns'] as Map?)?.map(
        (k, v) => MapEntry(k.toString(), v?.toString() ?? ''),
      ),
      menu: json['menu'],
      image: json['image'],
      hasRenge: json['hasRenge'] as bool?,
      seasonings: (json['seasonings'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      boilAdjustable: json['boilAdjustable'] as bool?,
      parkingInfo: json['parkingInfo'],
      memo: json['memo'],
      stamp: json['stamp'] as bool?,
      visited: json['visited'] as bool?,
      customCall: json['customCall'],
    );
  }

  /// 指定曜日(1〜7)の営業時間（なければ空文字）
  String hoursOf(int weekday) => businessHours?['$weekday'] ?? '';
}