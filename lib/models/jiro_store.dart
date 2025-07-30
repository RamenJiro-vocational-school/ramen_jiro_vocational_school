class JiroStore {
  final String name;
  final String area;
  final String address;
  final List<String> openDays; // ← これを追加

  JiroStore({
    required this.name,
    required this.area,
    required this.address,
    required this.openDays, // ← 忘れずに
  });

  factory JiroStore.fromJson(Map<String, dynamic> json) {
    return JiroStore(
      name: json['name'],
      area: json['area'],
      address: json['address'],
      openDays: List<String>.from(json['openDays']), // ← ここも追加
    );
  }
}
