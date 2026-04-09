class RescueUnit {
  RescueUnit({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.status,
    required this.capacity,
  });

  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final String status;
  final int capacity;

  factory RescueUnit.fromMap(Map<String, dynamic> map) {
    return RescueUnit(
      id: map['id'] as String,
      name: map['name'] as String,
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      status: map['status'] as String,
      capacity: map['capacity'] as int,
    );
  }
}
