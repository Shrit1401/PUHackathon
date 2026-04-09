class SosReport {
  SosReport({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.status,
    required this.createdAt,
    this.userId,
    this.disasterId,
    this.peopleCount,
    this.injuryStatus,
    this.description,
  });

  final String id;
  final String? userId;
  final String? disasterId;
  final double latitude;
  final double longitude;
  final int? peopleCount;
  final String? injuryStatus;
  final String status;
  final String? description;
  final DateTime createdAt;

  factory SosReport.fromMap(Map<String, dynamic> map) {
    double parseDouble(dynamic raw) {
      if (raw is num) return raw.toDouble();
      return double.tryParse(raw?.toString() ?? '') ?? 0;
    }

    DateTime parseDate(dynamic raw) {
      if (raw == null) return DateTime.now();
      return DateTime.tryParse(raw.toString()) ?? DateTime.now();
    }

    return SosReport(
      id: (map['id'] ?? map['incident_id'] ?? map['report_id'] ?? '').toString(),
      userId: map['user_id']?.toString(),
      disasterId: map['disaster_id']?.toString() ?? map['event_id']?.toString(),
      latitude: parseDouble(map['latitude']),
      longitude: parseDouble(map['longitude']),
      peopleCount: (map['people_count'] as num?)?.toInt(),
      injuryStatus: map['injury_status']?.toString(),
      status: (map['status'] ?? 'pending').toString(),
      description: map['description']?.toString(),
      createdAt: parseDate(map['created_at']),
    );
  }
}
