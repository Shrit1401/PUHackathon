class DisasterEvent {
  DisasterEvent({
    required this.id,
    required this.type,
    required this.latitude,
    required this.longitude,
    required this.confidenceScore,
    required this.createdAt,
  });

  final String id;
  final String type;
  final double latitude;
  final double longitude;
  final double confidenceScore;
  final DateTime createdAt;

  factory DisasterEvent.fromMap(Map<String, dynamic> map) {
    double parseDouble(dynamic raw) {
      if (raw is num) return raw.toDouble();
      return double.tryParse(raw?.toString() ?? '') ?? 0;
    }

    return DisasterEvent(
      id: (map['id'] ?? '').toString(),
      type: (map['type'] ?? 'unknown').toString(),
      latitude: parseDouble(map['latitude']),
      longitude: parseDouble(map['longitude']),
      confidenceScore: parseDouble(map['confidence'] ?? map['confidence_score']),
      createdAt: DateTime.tryParse((map['created_at'] ?? '').toString()) ?? DateTime.now(),
    );
  }
}
