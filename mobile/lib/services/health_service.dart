import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/api_client.dart';

final healthServiceProvider = Provider<HealthService>((ref) {
  return HealthService(ApiClient());
});

class HealthAdvice {
  HealthAdvice({
    required this.severity,
    required this.steps,
    required this.medicines,
  });

  final String severity;
  final List<String> steps;
  final List<String> medicines;

  bool get isCritical {
    final normalized = severity.toLowerCase();
    return normalized.contains('critical') ||
        normalized.contains('high') ||
        normalized.contains('severe');
  }
}

class HealthService {
  HealthService(this._api);

  final ApiClient _api;

  Future<HealthAdvice> getHealthAdvice(String symptoms) async {
    try {
      final json = await _api.postJson(
        '/health/advice',
        body: {'symptoms': symptoms},
      );
      return _parseAdvice(json);
    } catch (_) {
      return HealthAdvice(
        severity: 'Moderate',
        steps: const [
          'Move to a safe and ventilated area.',
          'Hydrate and monitor symptoms for 30 minutes.',
          'Contact local support if symptoms worsen.',
        ],
        medicines: const [
          'Paracetamol (if fever is present)',
          'ORS for dehydration',
        ],
      );
    }
  }

  HealthAdvice _parseAdvice(Map<String, dynamic> json) {
    final stepsRaw = json['steps'];
    final medicinesRaw = json['medicines'];

    return HealthAdvice(
      severity: (json['severity'] ?? 'Unknown').toString(),
      steps: _toStringList(stepsRaw),
      medicines: _toStringList(medicinesRaw),
    );
  }

  List<String> _toStringList(dynamic raw) {
    if (raw is List) {
      return raw.map((e) => e.toString()).where((e) => e.trim().isNotEmpty).toList();
    }
    return const [];
  }
}
