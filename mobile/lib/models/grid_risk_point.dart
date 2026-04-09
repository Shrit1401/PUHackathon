class GridRiskPoint {
  GridRiskPoint({
    required this.id,
    required this.gridLat,
    required this.gridLng,
    required this.riskScore,
    required this.updatedAt,
  });

  final String id;
  final double gridLat;
  final double gridLng;
  final double riskScore;
  final DateTime updatedAt;

  factory GridRiskPoint.fromMap(Map<String, dynamic> map) {
    return GridRiskPoint(
      id: map['id'] as String,
      gridLat: (map['grid_lat'] as num).toDouble(),
      gridLng: (map['grid_lng'] as num).toDouble(),
      riskScore: ((map['risk_score'] ?? 0) as num).toDouble(),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}
