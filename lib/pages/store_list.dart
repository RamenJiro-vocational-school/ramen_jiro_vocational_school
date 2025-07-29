class JiroStore {
  final String name;
  final String area;
  final String address;

  JiroStore({required this.name, required this.area, required this.address});

  factory JiroStore.fromJson(Map<String, dynamic> json) {
    return JiroStore(
      name: json['name'],
      area: json['area'],
      address: json['address'],
    );
  }
}
