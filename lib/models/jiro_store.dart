class JiroStore {
  final String name;
  final String area;
  final String address;
  final List<int> openDays;
  final Map<String, String>? businessHours;

  JiroStore({
    required this.name,
    required this.area,
    required this.address,
    required this.openDays,
    this.businessHours,
  });

  factory JiroStore.fromJson(Map<String, dynamic> json) {
    return JiroStore(
      name: json['name'],
      area: json['area'],
      address: json['address'],
      openDays: List<int>.from(json['openDays']),
      businessHours: json['business_hours'] != null
          ? Map<String, String>.from(json['business_hours'])
          : null,
    );
  }
}
