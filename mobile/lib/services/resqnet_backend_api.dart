import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http_parser/http_parser.dart';

import '../core/network/api_client.dart';

final resqnetBackendApiProvider = Provider<ResqnetBackendApi>((ref) {
  return ResqnetBackendApi(ApiClient());
});

class ResqnetBackendApi {
  ResqnetBackendApi(this._api);

  final ApiClient _api;

  // 1. Authentication
  Future<Map<String, dynamic>> signup({
    required String email,
    required String password,
    required String name,
    required String role,
    required String phone,
    String? bloodGroup,
    String? allergies,
    String? emergencyContact,
  }) {
    return _api.postJson(
      '/auth/signup',
      body: {
        'email': email,
        'password': password,
        'name': name,
        'role': role,
        'phone': phone,
        if (bloodGroup != null) 'blood_group': bloodGroup,
        if (allergies != null) 'allergies': allergies,
        if (emergencyContact != null) 'emergency_contact': emergencyContact,
      },
    );
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) {
    return _api.postJson(
      '/auth/login',
      body: {'email': email, 'password': password},
    );
  }

  Future<Map<String, dynamic>> logout() => _api.postJson('/auth/logout');

  Future<Map<String, dynamic>> sendPhoneOtp(String phone) {
    return _api.postJson('/auth/phone/send-otp', body: {'phone': phone});
  }

  Future<Map<String, dynamic>> verifyPhoneOtp({
    required String phone,
    required String otp,
    String? name,
  }) {
    return _api.postJson(
      '/auth/phone/verify-otp',
      body: {
        'phone': phone,
        'otp': otp,
        if (name != null && name.isNotEmpty) 'name': name,
      },
    );
  }

  // 2. Profile / NFC
  Future<Map<String, dynamic>> getNfcProfile(String userId) {
    return _api.getJson('/nfc/profile/$userId');
  }

  /// Persists one NFC read: tag JSON, reader-phone context, merged profile snapshot.
  /// See docs/NFC_SCAN_INGEST.md — backend should expose `POST /nfc/scans`.
  Future<Map<String, dynamic>> postNfcCardScan({
    required String cardUserId,
    Map<String, dynamic>? tagPayload,
    Map<String, dynamic>? readerContext,
    String? readerContextError,
    Map<String, dynamic>? profileSnapshot,
    String? profileFetchError,
  }) {
    return _api.postJson(
      '/nfc/scans',
      body: {
        'card_user_id': cardUserId,
        if (tagPayload != null && tagPayload.isNotEmpty) 'tag_payload': tagPayload,
        if (readerContext != null && readerContext.isNotEmpty)
          'reader_context': readerContext,
        if (readerContextError != null && readerContextError.isNotEmpty)
          'reader_context_error': readerContextError,
        if (profileSnapshot != null && profileSnapshot.isNotEmpty)
          'profile_snapshot': profileSnapshot,
        if (profileFetchError != null && profileFetchError.isNotEmpty)
          'profile_fetch_error': profileFetchError,
      },
    );
  }

  // 3. SOS and Dispatch
  Future<Map<String, dynamic>> postSos({
    required String userId,
    required String type,
    required double latitude,
    required double longitude,
    required String source,
    Map<String, dynamic>? context,
  }) {
    return _api.postJson(
      '/sos',
      body: {
        'user_id': userId,
        'type': type,
        'latitude': latitude,
        'longitude': longitude,
        'source': source,
        if (context != null && context.isNotEmpty) 'context': context,
      },
    );
  }

  // 4. WhatsApp Bot
  Future<String> whatsappWebhook({
    required String from,
    required String body,
    double? latitude,
    double? longitude,
  }) {
    return _api.postFormRaw(
      '/webhook/whatsapp',
      body: {
        'From': from,
        'Body': body,
        if (latitude != null) 'Latitude': latitude.toString(),
        if (longitude != null) 'Longitude': longitude.toString(),
      },
    );
  }

  Future<Map<String, dynamic>> whatsappStatus() => _api.getJson('/whatsapp/status');

  // 5. Health Advice AI
  Future<Map<String, dynamic>> healthAdvice(String symptoms) {
    return _api.postJson('/health/advice', body: {'symptoms': symptoms});
  }

  // 6. Reports & Events
  Future<Map<String, dynamic>> createReport({
    required String source,
    required double latitude,
    required double longitude,
    required String disasterType,
    String? description,
    required int peopleCount,
    required bool injuries,
    required double weatherSeverity,
  }) {
    return _api.postJson(
      '/reports',
      body: {
        'source': source,
        'latitude': latitude,
        'longitude': longitude,
        'disaster_type': disasterType,
        'description': description,
        'people_count': peopleCount,
        'injuries': injuries,
        'weather_severity': weatherSeverity,
      },
    );
  }

  Future<List<dynamic>> listReports({
    int? limit,
    String? source,
    String? eventId,
  }) {
    return _api.getList(
      '/reports',
      query: {
        if (limit != null) 'limit': limit,
        if (source != null) 'source': source,
        if (eventId != null) 'event_id': eventId,
      },
    );
  }

  Future<Map<String, dynamic>> getReport(String reportId) => _api.getJson('/reports/$reportId');

  Future<List<dynamic>> listEvents({
    bool? activeOnly,
    int? limit,
    String? severity,
  }) {
    return _api.getList(
      '/events',
      query: {
        if (activeOnly != null) 'active_only': activeOnly,
        if (limit != null) 'limit': limit,
        if (severity != null) 'severity': severity,
      },
    );
  }

  Future<List<dynamic>> nearbyEvents({
    required double lat,
    required double lng,
    double radiusKm = 3,
  }) {
    return _api.getList(
      '/events/nearby',
      query: {'lat': lat, 'lng': lng, 'radius_km': radiusKm},
    );
  }

  Future<Map<String, dynamic>> getEvent(String eventId) => _api.getJson('/events/$eventId');

  Future<Map<String, dynamic>> resolveEvent(String eventId) {
    return _api.patchJson('/events/$eventId/resolve');
  }

  // 7. AI insights
  Future<Map<String, dynamic>> aiSummary() => _api.getJson('/ai/insights/summary');

  Future<List<dynamic>> aiActions({int limit = 10}) {
    return _api.getList('/ai/insights/actions', query: {'limit': limit});
  }

  // 8. Device & wearable ingestion
  Future<Map<String, dynamic>> registerDevice({
    required String userId,
    required String deviceType,
    required String deviceId,
    required String platform,
    String? pushToken,
  }) {
    return _api.postJson(
      '/devices/register',
      body: {
        'user_id': userId,
        'device_type': deviceType,
        'device_id': deviceId,
        'platform': platform,
        if (pushToken != null) 'push_token': pushToken,
      },
    );
  }

  Future<Map<String, dynamic>> wearableFallDetected({
    required String userId,
    required String deviceId,
    required String eventTimeIso,
    required double latitude,
    required double longitude,
    required double impactScore,
    required double heartRate,
  }) {
    return _api.postJson(
      '/wearables/fall-detected',
      body: {
        'user_id': userId,
        'device_id': deviceId,
        'event_time': eventTimeIso,
        'latitude': latitude,
        'longitude': longitude,
        'impact_score': impactScore,
        'heart_rate': heartRate,
      },
    );
  }

  Future<Map<String, dynamic>> wearableHeartAlert({
    required String userId,
    required String deviceId,
    required double heartRate,
    required double latitude,
    required double longitude,
    String? eventTimeIso,
  }) {
    return _api.postJson(
      '/wearables/heart-alert',
      body: {
        'user_id': userId,
        'device_id': deviceId,
        'heart_rate': heartRate,
        'latitude': latitude,
        'longitude': longitude,
        if (eventTimeIso != null) 'event_time': eventTimeIso,
      },
    );
  }

  // 9. Admin/controller APIs
  Future<List<dynamic>> listResponders({
    String? availability,
    String? type,
    int? limit,
  }) {
    return _api.getList(
      '/responders',
      query: {
        if (availability != null) 'availability': availability,
        if (type != null) 'type': type,
        if (limit != null) 'limit': limit,
      },
    );
  }

  Future<Map<String, dynamic>> createResponder({
    required String name,
    required String type,
    required String phone,
    required double latitude,
    required double longitude,
    String availability = 'ready',
  }) {
    return _api.postJson(
      '/responders',
      body: {
        'name': name,
        'type': type,
        'phone': phone,
        'latitude': latitude,
        'longitude': longitude,
        'availability': availability,
      },
    );
  }

  Future<Map<String, dynamic>> updateResponder({
    required String responderId,
    String? availability,
    String? currentStatus,
    int? etaMinutes,
  }) {
    return _api.patchJson(
      '/responders/$responderId',
      body: {
        if (availability != null) 'availability': availability,
        if (currentStatus != null) 'current_status': currentStatus,
        if (etaMinutes != null) 'eta_minutes': etaMinutes,
      },
    );
  }

  Future<Map<String, dynamic>> postResponderLocation({
    required String responderId,
    required double latitude,
    required double longitude,
    required double speedKmph,
  }) {
    return _api.postJson(
      '/responders/$responderId/location',
      body: {
        'latitude': latitude,
        'longitude': longitude,
        'speed_kmph': speedKmph,
      },
    );
  }

  Future<List<dynamic>> nearbyResponders({
    required double lat,
    required double lng,
    double radiusKm = 5,
  }) {
    return _api.getList(
      '/responders/nearby',
      query: {'lat': lat, 'lng': lng, 'radius_km': radiusKm},
    );
  }

  Future<List<dynamic>> liveIncidents() => _api.getList('/incidents/live');

  Future<Map<String, dynamic>> updateIncidentStatus({
    required String incidentId,
    required String status,
  }) {
    return _api.patchJson(
      '/incidents/$incidentId/status',
      body: {'status': status},
    );
  }

  Future<Map<String, dynamic>> assignIncident({
    required String incidentId,
    required String responderId,
    required String assignedBy,
    String? note,
  }) {
    return _api.postJson(
      '/incidents/$incidentId/assign',
      body: {
        'responder_id': responderId,
        'assigned_by': assignedBy,
        if (note != null) 'note': note,
      },
    );
  }

  Future<Map<String, dynamic>> optimizeDispatch({
    required String incidentId,
    required double latitude,
    required double longitude,
    required String requiredUnit,
  }) {
    return _api.postJson(
      '/dispatch/optimize',
      body: {
        'incident_id': incidentId,
        'latitude': latitude,
        'longitude': longitude,
        'required_unit': requiredUnit,
      },
    );
  }

  // 10. WhatsApp AI triage helpers
  Future<Map<String, dynamic>> whatsappTriage({
    required String phone,
    required String message,
    double? latitude,
    double? longitude,
    String language = 'en',
  }) {
    return _api.postJson(
      '/whatsapp/triage',
      body: {
        'phone': phone,
        'message': message,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        'language': language,
      },
    );
  }

  Future<Map<String, dynamic>> whatsappTriageEscalate({
    required String phone,
    required Map<String, dynamic> triageResult,
    required double latitude,
    required double longitude,
  }) {
    return _api.postJson(
      '/whatsapp/triage/escalate',
      body: {
        'phone': phone,
        'triage_result': triageResult,
        'latitude': latitude,
        'longitude': longitude,
      },
    );
  }

  // 18. Minimal confidence scoring (rule-based fallback)
  Future<Map<String, dynamic>> confidenceScore({
    String? eventId,
    Map<String, int>? reportCounts,
    double? sourceEntropy,
    double? localGridRiskScore,
    double? weatherSeverity,
    int? nearbyReadyResponders,
    int? eonetEventCount24h,
  }) {
    return _api.postJson(
      '/ml/confidence/score',
      body: {
        if (eventId != null) 'event_id': eventId,
        if (reportCounts != null) 'report_counts': reportCounts,
        if (sourceEntropy != null) 'source_entropy': sourceEntropy,
        if (localGridRiskScore != null) 'local_grid_risk_score': localGridRiskScore,
        if (weatherSeverity != null) 'weather_severity': weatherSeverity,
        if (nearbyReadyResponders != null) 'nearby_ready_responders': nearbyReadyResponders,
        if (eonetEventCount24h != null) 'eonet_event_count_24h': eonetEventCount24h,
      },
    );
  }

  // 11. Grid risk
  Future<List<dynamic>> getGrid({double? minRisk}) {
    return _api.getList(
      '/grid',
      query: {if (minRisk != null) 'min_risk': minRisk},
    );
  }

  Future<List<dynamic>> nearbyGrid({
    required double lat,
    required double lng,
    required double radiusKm,
  }) {
    return _api.getList(
      '/grid/nearby',
      query: {'lat': lat, 'lng': lng, 'radius_km': radiusKm},
    );
  }

  // 12. Predictions
  Future<List<dynamic>> getPredictions() => _api.getList('/predictions');

  // 13. Simulation
  Future<Map<String, dynamic>> simulationSpread(String eventId) {
    return _api.postJson('/simulation/spread', body: {'event_id': eventId});
  }

  Future<Map<String, dynamic>> simulationCompare(String eventId) {
    return _api.postJson('/simulation/compare', body: {'event_id': eventId});
  }

  // 14. Dashboard
  Future<Map<String, dynamic>> dashboardStats() => _api.getJson('/dashboard/stats');

  Future<Map<String, dynamic>> dashboardFeed() => _api.getJson('/dashboard/feed');

  // 15. External ingestion
  Future<Map<String, dynamic>> externalIngest({
    required String source,
    required double latitude,
    required double longitude,
    required String disasterType,
    required double severityScore,
    String? description,
  }) {
    return _api.postJson(
      '/external/ingest',
      body: {
        'source': source,
        'latitude': latitude,
        'longitude': longitude,
        'disaster_type': disasterType,
        'severity_score': severityScore,
        if (description != null) 'description': description,
      },
    );
  }

  Future<Map<String, dynamic>> externalIngestBulk({
    required List<Map<String, dynamic>> signals,
  }) async {
    final response = await _api.postJsonDynamic('/external/ingest/bulk', body: signals);
    if (response is Map<String, dynamic>) {
      return response;
    }
    throw Exception('Expected object response for /external/ingest/bulk');
  }

  // 16. Media uploads
  Future<Map<String, dynamic>> mediaUpload({
    required Uint8List fileBytes,
    required String filename,
    required double latitude,
    required double longitude,
    required String disasterType,
    String? reportId,
    String? userId,
  }) {
    final ext = filename.toLowerCase().split('.').last;
    final MediaType contentType = switch (ext) {
      'jpg' || 'jpeg' => MediaType('image', 'jpeg'),
      'png' => MediaType('image', 'png'),
      'webp' => MediaType('image', 'webp'),
      _ => MediaType('image', 'jpeg'),
    };

    return _api.postMultipart(
      '/media/upload',
      fileField: 'file',
      fileBytes: fileBytes,
      filename: filename,
      fileContentType: contentType,
      fields: {
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'disaster_type': disasterType,
        if (reportId != null) 'report_id': reportId,
        if (userId != null) 'user_id': userId,
      },
    );
  }

  Future<Map<String, dynamic>> mediaList({
    String? disasterType,
    int limit = 10,
  }) {
    return _api.getJson(
      '/media/list',
      query: {
        if (disasterType != null) 'disaster_type': disasterType,
        'limit': limit,
      },
    );
  }

  // 17. News
  Future<Map<String, dynamic>> getNews({String? disasterType}) {
    return _api.getJson(
      '/news',
      query: {if (disasterType != null) 'disaster_type': disasterType},
    );
  }
}
