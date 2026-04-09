import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http_parser/http_parser.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/network/api_client.dart';
import '../core/network/supabase_provider.dart';
import '../core/utils/geo_math.dart';
import '../models/citizen_report.dart';
import '../models/disaster_event.dart';
import '../models/grid_risk_point.dart';
import '../models/news_article.dart';
import '../models/rescue_unit.dart';
import '../models/social_feed_item.dart';
import '../models/sos_report.dart';
import '../features/sos/data/sos_offline_queue.dart';

final emergencyRepositoryProvider = Provider<EmergencyRepository>((ref) {
  return EmergencyRepository(
    ref.read(supabaseClientProvider),
    ApiClient(),
  );
});

class SosAiGuidance {
  SosAiGuidance({
    required this.priority,
    required this.instructions,
  });

  final String priority;
  final String instructions;
}

class SosDispatchResult {
  SosDispatchResult({
    required this.reportId,
    this.aiGuidance,
    this.queued = false,
  });

  final String reportId;
  final SosAiGuidance? aiGuidance;
  final bool queued;
}

class EmergencyRepository {
  EmergencyRepository(this._client, this._api);

  final SupabaseClient _client;
  final ApiClient _api;
  final Map<String, SosReport> _localSosReportsById = {};
  final Map<String, RescueUnit> _assignedUnitsByIncident = {};
  final Map<String, SosReport> _queuedSosById = {};
  bool _queueHydrated = false;

  Stream<List<DisasterEvent>> streamDisasterEvents() {
    // Dashboard events feed from REST API `/events`.
    return Stream.periodic(const Duration(seconds: 5)).asyncMap((_) async {
      final list = await _api.getList('/events');
      return list
          .map(
            (e) => DisasterEvent.fromMap(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList();
    });
  }

  Stream<List<GridRiskPoint>> streamGridRisk() {
    // Heatmap grid from `/grid`.
    return Stream.periodic(const Duration(seconds: 7)).asyncMap((_) async {
      final list = await _api.getList('/grid');
      return list
          .map(
            (e) => GridRiskPoint.fromMap(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList();
    });
  }

  Stream<List<RescueUnit>> streamRescueUnits() {
    // Backend does not expose a public rescue-units endpoint.
    // Build a lightweight list from responders returned by `/sos`.
    return Stream.periodic(const Duration(seconds: 5)).asyncMap((_) async {
      return _assignedUnitsByIncident.values.toList(growable: false);
    });
  }

  Stream<List<CitizenReport>> streamReports() {
    // Reports feed from `/reports`.
    return Stream.periodic(const Duration(seconds: 6)).asyncMap((_) async {
      final list = await _api.getList('/reports', query: {'limit': 100});
      return list
          .map(
            (e) => CitizenReport.fromMap(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList();
    });
  }

  Stream<List<SocialFeedItem>> streamSocialFeed({
    required double latitude,
    required double longitude,
    double radiusKm = 10,
  }) {
    return Stream.periodic(const Duration(seconds: 6)).asyncMap((_) async {
      final list = await _api.getList(
        '/events/nearby',
        query: {'lat': latitude, 'lng': longitude, 'radius_km': radiusKm},
      );
      return list
          .map(
            (e) => SocialFeedItem.fromMap(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList();
    });
  }

  Future<Map<String, dynamic>> confirmSocialEvent({
    required String eventId,
    required double latitude,
    required double longitude,
    String? userId,
  }) async {
    return _api.postJson(
      '/reports',
      body: {
        'source': 'app_confirmation',
        'event_id': eventId,
        'latitude': latitude,
        'longitude': longitude,
        'disaster_type': 'other',
        'description': 'community_confirmation${userId == null ? '' : ';user=$userId'}',
        'people_count': 1,
        'injuries': false,
        'weather_severity': 0.2,
        if (userId != null) 'user_id': userId,
      },
    );
  }

  Future<Map<String, dynamic>> postSocialObservation({
    required double latitude,
    required double longitude,
    required String disasterType,
    required String observation,
    String? userId,
  }) async {
    return _api.postJson(
      '/external/ingest',
      body: {
        'source': 'social',
        'latitude': latitude,
        'longitude': longitude,
        'disaster_type': disasterType,
        'severity_score': 0.5,
        'description': userId == null ? observation : '$observation;user=$userId',
      },
    );
  }

  Future<EventConfirmationsResponse> getEventConfirmations(String eventId) async {
    final rows = await _api.getList('/reports', query: {'event_id': eventId, 'limit': 100});
    final confirmations = rows
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .where((row) => (row['latitude'] is num) && (row['longitude'] is num))
        .map(
          (row) => EventConfirmationPoint(
            id: (row['id'] ?? '').toString(),
            latitude: (row['latitude'] as num).toDouble(),
            longitude: (row['longitude'] as num).toDouble(),
            createdAt: DateTime.tryParse((row['created_at'] ?? '').toString()) ?? DateTime.now(),
          ),
        )
        .toList(growable: false);
    return EventConfirmationsResponse(
      eventId: eventId,
      confirmationCount: confirmations.length,
      confirmations: confirmations,
    );
  }

  Future<NewsResponse> getNews({String? disasterType}) async {
    final json = await _api.getJson(
      '/news',
      query: disasterType == null ? null : {'disaster_type': disasterType},
    );
    return NewsResponse.fromMap(json);
  }

  Future<Map<String, dynamic>> getMediaList({
    String? disasterType,
    int limit = 50,
  }) async {
    return _api.getJson(
      '/media/list',
      query: {
        'limit': limit,
        if (disasterType != null) 'disaster_type': disasterType,
      },
    );
  }

  Future<Map<String, dynamic>> uploadMedia({
    required Uint8List bytes,
    required String filename,
    required double latitude,
    required double longitude,
    String disasterType = 'other',
    String? reportId,
    String? userId,
  }) async {
    final ext = filename.toLowerCase().split('.').last;
    final MediaType contentType = switch (ext) {
      'jpg' || 'jpeg' => MediaType('image', 'jpeg'),
      'png' => MediaType('image', 'png'),
      'webp' => MediaType('image', 'webp'),
      'heic' => MediaType('image', 'heic'),
      _ => MediaType('image', 'jpeg'),
    };

    return _api.postMultipart(
      '/media/upload',
      fileField: 'file',
      fileBytes: bytes,
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

  Stream<List<SosReport>> streamCurrentUserReports(String userId) {
    return Stream.periodic(const Duration(seconds: 5)).asyncMap((_) async {
      await _ensureQueueHydrated();
      final list = await _api.getList('/reports', query: {'limit': 100});
      final apiReports = list
          .whereType<Map>()
          .map((e) => SosReport.fromMap(Map<String, dynamic>.from(e)))
          .where((r) => (r.description ?? '').contains('user=$userId'))
          .toList();
      final localReports = _localSosReportsById.values.where((r) => r.userId == userId).toList();
      final queuedForUser =
          _queuedSosById.values.where((r) => r.userId == userId).toList();
      final merged = <String, SosReport>{
        for (final r in apiReports) r.id: r,
        for (final r in localReports) r.id: r,
        for (final r in queuedForUser) r.id: r,
      };
      final reports = merged.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return reports;
    });
  }

  Future<void> _ensureQueueHydrated() async {
    if (_queueHydrated) return;
    final items = await SosOfflineQueueStore.load();
    for (final p in items) {
      _queuedSosById[p.id] = SosReport(
        id: p.id,
        userId: p.userId,
        latitude: p.latitude,
        longitude: p.longitude,
        status: 'queued_offline',
        description: p.description,
        createdAt: p.createdAt,
      );
    }
    _queueHydrated = true;
  }

  /// Load offline queue from disk (call early, e.g. dashboard mount).
  Future<void> ensureSosStateLoaded() => _ensureQueueHydrated();

  SosReport? peekReport(String reportId) {
    return _localSosReportsById[reportId] ?? _queuedSosById[reportId];
  }

  bool _isLikelyNetworkError(Object e) {
    if (e is SocketException || e is TimeoutException) return true;
    final s = e.toString().toLowerCase();
    return s.contains('socket') ||
        s.contains('connection') ||
        s.contains('failed host lookup') ||
        s.contains('network') ||
        s.contains('timed out');
  }

  Map<String, dynamic> _sosPostBody({
    String? userId,
    required String sosType,
    required double latitude,
    required double longitude,
    required String source,
    Map<String, dynamic>? context,
  }) {
    return {
      if (userId != null) 'user_id': userId,
      'type': sosType,
      'latitude': latitude,
      'longitude': longitude,
      'source': _normalizedSosSource(source),
      if (context != null && context.isNotEmpty) 'context': context,
    };
  }

  Future<SosDispatchResult> _enqueueOfflineSos({
    required double latitude,
    required double longitude,
    String? userId,
    required String source,
    required String description,
    required String sosType,
    required Map<String, dynamic> context,
  }) async {
    await _ensureQueueHydrated();
    final id = 'queued_${DateTime.now().millisecondsSinceEpoch}';
    final payload = PendingSosPayload(
      id: id,
      latitude: latitude,
      longitude: longitude,
      userId: userId,
      source: source,
      description: description,
      sosType: sosType,
      context: context,
      createdAt: DateTime.now(),
    );
    await SosOfflineQueueStore.enqueue(payload);
    _queuedSosById[id] = SosReport(
      id: id,
      userId: userId,
      latitude: latitude,
      longitude: longitude,
      status: 'queued_offline',
      description: description,
      createdAt: DateTime.now(),
    );
    return SosDispatchResult(
      reportId: id,
      queued: true,
      aiGuidance: SosAiGuidance(
        priority: 'QUEUED',
        instructions: 'No network — SOS is saved and will send when you are back online.',
      ),
    );
  }

  /// Retry pending SOS payloads (e.g. on app start or when connectivity returns).
  Future<void> processOfflineSosQueue() async {
    await _ensureQueueHydrated();
    var list = await SosOfflineQueueStore.load();
    if (list.isEmpty) return;

    final remaining = <PendingSosPayload>[];
    for (final p in list) {
      try {
        final json = await _api.postJson(
          '/sos',
          body: _sosPostBody(
            userId: p.userId,
            sosType: p.sosType,
            latitude: p.latitude,
            longitude: p.longitude,
            source: p.source,
            context: p.context,
          ),
        );
        final newId = (json['incident_id'] ?? json['report_id'] ?? '').toString().trim();
        final effectiveId =
            newId.isEmpty ? 'incident_${DateTime.now().millisecondsSinceEpoch}' : newId;
        _queuedSosById.remove(p.id);
        final status = (json['status'] ?? 'pending').toString();
        _localSosReportsById[effectiveId] = SosReport(
          id: effectiveId,
          userId: p.userId,
          latitude: p.latitude,
          longitude: p.longitude,
          status: status,
          description: p.description,
          createdAt: DateTime.now(),
        );
        final responderRaw = json['responder'];
        if (responderRaw is Map) {
          final responder = Map<String, dynamic>.from(responderRaw);
          _assignedUnitsByIncident[effectiveId] = RescueUnit(
            id: (responder['id'] ?? 'assigned-$effectiveId').toString(),
            name: (responder['name'] ?? 'Assigned Responder').toString(),
            latitude: p.latitude,
            longitude: p.longitude,
            status: 'busy',
            capacity: 1,
          );
        }
      } catch (e) {
        if (_isLikelyNetworkError(e)) {
          remaining.add(p);
        } else {
          remaining.add(p);
        }
      }
    }
    await SosOfflineQueueStore.replaceAll(remaining);
  }

  Future<SosReport> createSosReport({
    required String userId,
    required String disasterId,
    required double latitude,
    required double longitude,
    required int peopleCount,
    required String injuryStatus,
  }) async {
    final created = await _api.postJson(
      '/reports',
      body: {
        'source': 'citizen_mobile',
        'event_id': disasterId,
        'latitude': latitude,
        'longitude': longitude,
        'disaster_type': 'medical',
        'description': 'people_count=$peopleCount;injury_status=$injuryStatus;user=$userId',
        'people_count': peopleCount,
        'injuries': injuryStatus.toLowerCase() == 'yes',
        'weather_severity': 0.5,
      },
    );
    final reportId = (created['report_id'] ?? '').toString();
    if (reportId.isEmpty) {
      return SosReport(
        id: 'local_${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        disasterId: disasterId,
        latitude: latitude,
        longitude: longitude,
        peopleCount: peopleCount,
        injuryStatus: injuryStatus,
        status: 'pending',
        description: 'people_count=$peopleCount;injury_status=$injuryStatus;user=$userId',
        createdAt: DateTime.now(),
      );
    }
    final row = await _api.getJson('/reports/$reportId');
    return SosReport.fromMap(row);
  }

  Future<SosDispatchResult> triggerSos({
    required double latitude,
    required double longitude,
    String? userId,
    String source = 'citizen_mobile',
    String description = 'Emergency request from app',
    String sosType = 'medical',
    Map<String, dynamic>? context,
  }) async {
    await _ensureQueueHydrated();

    if (!kIsWeb) {
      try {
        final cx = await Connectivity().checkConnectivity();
        final offline =
            cx.isEmpty || !cx.any((c) => c != ConnectivityResult.none);
        if (offline) {
          return _enqueueOfflineSos(
            latitude: latitude,
            longitude: longitude,
            userId: userId,
            source: source,
            description: description,
            sosType: sosType,
            context: context ?? {},
          );
        }
      } catch (_) {
        // Continue and try POST.
      }
    }

    try {
      final json = await _api.postJson(
        '/sos',
        body: _sosPostBody(
          userId: userId,
          sosType: sosType,
          latitude: latitude,
          longitude: longitude,
          source: source,
          context: context,
        ),
      );

      final reportId = (json['incident_id'] ?? json['report_id'] ?? '').toString().trim();
      final effectiveReportId =
          reportId.isEmpty ? 'incident_${DateTime.now().millisecondsSinceEpoch}' : reportId;
      final status = (json['status'] ?? 'pending').toString();
      final local = SosReport(
        id: effectiveReportId,
        userId: userId,
        latitude: latitude,
        longitude: longitude,
        status: status,
        description: description,
        createdAt: DateTime.now(),
      );
      _localSosReportsById[effectiveReportId] = local;

      final responderRaw = json['responder'];
      if (responderRaw is Map) {
        final responder = Map<String, dynamic>.from(responderRaw);
        _assignedUnitsByIncident[effectiveReportId] = RescueUnit(
          id: (responder['id'] ?? 'assigned-$effectiveReportId').toString(),
          name: (responder['name'] ?? 'Assigned Responder').toString(),
          latitude: latitude,
          longitude: longitude,
          status: 'busy',
          capacity: 1,
        );
      }

      return SosDispatchResult(
        reportId: effectiveReportId,
        aiGuidance: _parseAiGuidance(json['ai']),
      );
    } catch (e) {
      if (_isLikelyNetworkError(e)) {
        return _enqueueOfflineSos(
          latitude: latitude,
          longitude: longitude,
          userId: userId,
          source: source,
          description: description,
          sosType: sosType,
          context: context ?? {},
        );
      }
      try {
        final report = await createCitizenReport(
          source: source,
          latitude: latitude,
          longitude: longitude,
          description: description,
        );
        return SosDispatchResult(
          reportId: report.id,
          aiGuidance: SosAiGuidance(
            priority: 'HIGH',
            instructions: 'Move to a safe open area and keep phone location ON.',
          ),
        );
      } catch (_) {
        rethrow;
      }
    }
  }

  SosAiGuidance? _parseAiGuidance(dynamic raw) {
    if (raw is! Map) return null;
    final map = Map<String, dynamic>.from(raw);
    final priority = (map['priority'] ?? '').toString().trim();
    final instructions = (map['instructions'] ?? '').toString().trim();
    if (priority.isEmpty && instructions.isEmpty) return null;
    return SosAiGuidance(
      priority: priority.isEmpty ? 'UNKNOWN' : priority,
      instructions: instructions,
    );
  }

  Future<CitizenReport> createCitizenReport({
    required String source,
    required double latitude,
    required double longitude,
    required String description,
    String? eventId,
  }) async {
    final created = await _api.postJson(
      '/reports',
      body: {
        'source': source,
        'event_id': eventId,
        'latitude': latitude,
        'longitude': longitude,
        'disaster_type': _disasterTypeForSource(source),
        'description': description,
        'people_count': 1,
        'injuries': false,
        'weather_severity': 0.3,
      },
    );
    final reportId = (created['report_id'] ?? '').toString().trim();
    if (reportId.isNotEmpty) {
      final row = await _api.getJson('/reports/$reportId');
      return CitizenReport.fromMap(row);
    }
    return CitizenReport(
      id: 'local_${DateTime.now().millisecondsSinceEpoch}',
      source: source,
      eventId: eventId,
      latitude: latitude,
      longitude: longitude,
      description: description,
      createdAt: DateTime.now(),
    );
  }

  String _disasterTypeForSource(String source) {
    final s = source.toLowerCase();
    if (s.contains('flood')) return 'flood';
    if (s.contains('fire')) return 'fire';
    if (s.contains('earthquake')) return 'earthquake';
    return 'other';
  }

  String _normalizedSosSource(String source) {
    final s = source.trim().toLowerCase();
    if (s.contains('watch')) return 'watch';
    if (s.contains('whatsapp')) return 'whatsapp';
    if (s.contains('nfc')) return 'nfc';
    return 'app';
  }

  Future<void> markRescueUnitBusy(String unitId) async {
    await _client.from('rescue_units').update({'status': 'busy'}).eq('id', unitId);
  }

  Future<RescueUnit?> nearestAvailableUnit({
    required double latitude,
    required double longitude,
  }) async {
    final rows = await _client
        .from('rescue_units')
        .select()
        .eq('status', 'available') as List<dynamic>;

    if (rows.isEmpty) return null;

    final units = rows
        .map((e) => RescueUnit.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
    units.sort((a, b) {
      final d1 = GeoMath.haversineKm(
        lat1: latitude,
        lon1: longitude,
        lat2: a.latitude,
        lon2: a.longitude,
      );
      final d2 = GeoMath.haversineKm(
        lat1: latitude,
        lon1: longitude,
        lat2: b.latitude,
        lon2: b.longitude,
      );
      return d1.compareTo(d2);
    });

    return units.first;
  }
}
