/// Модель корпуса (из mockData.ts)
class Building {
  final String id;
  final String name;
  final String address;
  final String distance;
  final String walkTime;
  final bool hasCafe;

  const Building({
    required this.id,
    required this.name,
    required this.address,
    required this.distance,
    required this.walkTime,
    required this.hasCafe,
  });

  factory Building.fromJson(Map<String, dynamic> json) {
    return Building(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
      distance: json['distance'] as String,
      walkTime: json['walkTime'] as String,
      hasCafe: json['hasCafe'] as bool,
    );
  }
}
