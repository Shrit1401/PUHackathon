import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Persisted SOS attempts when the device is offline; processed by [EmergencyRepository.processOfflineSosQueue].
class PendingSosPayload {
  PendingSosPayload({
    required this.id,
    required this.latitude,
    required this.longitude,
    this.userId,
    required this.source,
    required this.description,
    required this.sosType,
    required this.context,
    required this.createdAt,
  });

  final String id;
  final double latitude;
  final double longitude;
  final String? userId;
  final String source;
  final String description;
  final String sosType;
  final Map<String, dynamic> context;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'latitude': latitude,
        'longitude': longitude,
        'user_id': userId,
        'source': source,
        'description': description,
        'sos_type': sosType,
        'context': context,
        'created_at': createdAt.toUtc().toIso8601String(),
      };

  static PendingSosPayload fromJson(Map<String, dynamic> m) {
    return PendingSosPayload(
      id: (m['id'] ?? '').toString(),
      latitude: (m['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (m['longitude'] as num?)?.toDouble() ?? 0,
      userId: m['user_id']?.toString(),
      source: (m['source'] ?? 'app').toString(),
      description: (m['description'] ?? '').toString(),
      sosType: (m['sos_type'] ?? 'medical').toString(),
      context: Map<String, dynamic>.from(m['context'] as Map? ?? {}),
      createdAt: DateTime.tryParse((m['created_at'] ?? '').toString()) ?? DateTime.now(),
    );
  }
}

class SosOfflineQueueStore {
  static const _key = 'sos_offline_queue_v1';

  static Future<List<PendingSosPayload>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) => PendingSosPayload.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> save(List<PendingSosPayload> items) async {
    final prefs = await SharedPreferences.getInstance();
    if (items.isEmpty) {
      await prefs.remove(_key);
      return;
    }
    await prefs.setString(
      _key,
      jsonEncode(items.map((e) => e.toJson()).toList()),
    );
  }

  static Future<void> enqueue(PendingSosPayload item) async {
    final all = await load()..add(item);
    await save(all);
  }

  static Future<void> replaceAll(List<PendingSosPayload> items) => save(items);
}
