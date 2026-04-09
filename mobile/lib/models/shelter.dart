class Shelter {
  Shelter({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.capacity,
    required this.availableSlots,
  });

  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final int capacity;
  final int availableSlots;

  factory Shelter.fromMap(Map<String, dynamic> map) {
    return Shelter(
      id: map['id'] as String,
      name: map['name'] as String,
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      capacity: map['capacity'] as int,
      availableSlots: map['available_slots'] as int,
    );
  }
}
