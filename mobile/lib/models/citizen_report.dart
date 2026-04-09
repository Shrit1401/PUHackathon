class CitizenReport {
  CitizenReport({
    required this.id,
    required this.source,
    required this.latitude,
    required this.longitude,
    required this.description,
    required this.createdAt,
    this.eventId,
  });

  final String id;
  final String source;
  final String? eventId;
  final double latitude;
  final double longitude;
  final String description;
  final DateTime createdAt;

  factory CitizenReport.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic raw) {
      if (raw == null) return DateTime.now();
      return DateTime.tryParse(raw.toString()) ?? DateTime.now();
    }

    double parseDouble(dynamic raw) {
      if (raw is num) return raw.toDouble();
      return double.tryParse(raw?.toString() ?? '') ?? 0;
    }

    return CitizenReport(
      id: (map['id'] ?? map['report_id'] ?? '').toString(),
      source: (map['source'] ?? 'unknown').toString(),
      eventId: map['event_id']?.toString(),
      latitude: parseDouble(map['latitude']),
      longitude: parseDouble(map['longitude']),
      description: (map['description'] ?? '') as String,
      createdAt: parseDate(map['created_at']),
    );
  }
}
