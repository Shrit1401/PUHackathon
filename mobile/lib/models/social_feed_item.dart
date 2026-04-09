class SocialFeedItem {
  SocialFeedItem({
    required this.id,
    required this.type,
    required this.latitude,
    required this.longitude,
    required this.confidence,
    required this.severity,
    required this.active,
    required this.createdAt,
    required this.distanceKm,
    required this.confirmations,
  });

  final String id;
  final String type;
  final double latitude;
  final double longitude;
  final double confidence;
  final String severity;
  final bool active;
  final DateTime createdAt;
  final double distanceKm;
  final int confirmations;

  factory SocialFeedItem.fromMap(Map<String, dynamic> map) {
    double parseDouble(dynamic raw) {
      if (raw is num) return raw.toDouble();
      return double.tryParse(raw?.toString() ?? '') ?? 0;
    }

    return SocialFeedItem(
      id: (map['id'] ?? '').toString(),
      type: (map['type'] ?? '').toString(),
      latitude: parseDouble(map['latitude']),
      longitude: parseDouble(map['longitude']),
      confidence: parseDouble(map['confidence']),
      severity: (map['severity'] ?? 'unknown').toString(),
      active: (map['active'] as bool?) ?? true,
      createdAt: DateTime.tryParse((map['created_at'] ?? '').toString()) ?? DateTime.now(),
      distanceKm: parseDouble(map['distance_km']),
      confirmations: (map['confirmations'] as num?)?.toInt() ?? 0,
    );
  }
}

class EventConfirmationPoint {
  EventConfirmationPoint({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.createdAt,
  });

  final String id;
  final double latitude;
  final double longitude;
  final DateTime createdAt;

  factory EventConfirmationPoint.fromMap(Map<String, dynamic> map) {
    double parseDouble(dynamic raw) {
      if (raw is num) return raw.toDouble();
      return double.tryParse(raw?.toString() ?? '') ?? 0;
    }

    return EventConfirmationPoint(
      id: (map['id'] ?? '').toString(),
      latitude: parseDouble(map['latitude']),
      longitude: parseDouble(map['longitude']),
      createdAt: DateTime.tryParse((map['created_at'] ?? '').toString()) ?? DateTime.now(),
    );
  }
}

class EventConfirmationsResponse {
  EventConfirmationsResponse({
    required this.eventId,
    required this.confirmationCount,
    required this.confirmations,
  });

  final String eventId;
  final int confirmationCount;
  final List<EventConfirmationPoint> confirmations;

  factory EventConfirmationsResponse.fromMap(Map<String, dynamic> map) {
    final raw = (map['confirmations'] as List?) ?? const [];
    return EventConfirmationsResponse(
      eventId: (map['event_id'] ?? '').toString(),
      confirmationCount: (map['confirmation_count'] as num?)?.toInt() ?? 0,
      confirmations: raw
          .map((e) => EventConfirmationPoint.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }
}
