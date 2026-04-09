import 'dart:convert';

import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/localization/app_language.dart';
import 'nfc_linkage_store.dart';

/// Rich context sent with SOS (and mirrored in [docs/BACKEND_SOS_EXTENSIONS.md]).
class SosContextCollector {
  SosContextCollector._();

  static Future<Map<String, dynamic>> collect({
    required Position position,
    required AppLanguage appLanguage,
    required String descriptionSummary,
    required int peopleCount,
    required bool injured,
    String? nearestEventId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final nfc = await NfcLinkageStore.read(prefs);

    int? batteryPct;
    String connectivity = 'unknown';
    try {
      if (!kIsWeb) {
        batteryPct = await Battery().batteryLevel;
        final list = await Connectivity().checkConnectivity();
        connectivity = list.isEmpty ? 'none' : list.first.name;
      }
    } catch (_) {
      // Best-effort only.
    }

    return {
      'location_accuracy_m': position.accuracy,
      'altitude_m': position.altitude,
      'heading': position.heading,
      'speed_mps': position.speed,
      'battery_percent': batteryPct,
      'connectivity': connectivity,
      'app_language': appLanguage.name,
      'description_summary': descriptionSummary,
      'people_count': peopleCount,
      'injured': injured,
      'nearest_event_id': nearestEventId,
      'nfc_user_id_recent': nfc?.userId,
      'nfc_linked_seconds_ago': nfc?.secondsAgo(),
      'client': 'resqnet_flutter',
      'client_ts': DateTime.now().toUtc().toIso8601String(),
    };
  }

  /// Snapshot when someone scans an emergency NFC card (SOS `context` shape + reader GPS for dispatch).
  static Future<Map<String, dynamic>> collectForNfcCardScan({
    required Position position,
    required AppLanguage appLanguage,
  }) async {
    final m = await collect(
      position: position,
      appLanguage: appLanguage,
      descriptionSummary: 'nfc_emergency_card_scan',
      peopleCount: 0,
      injured: false,
      nearestEventId: null,
    );
    m['reader_latitude'] = position.latitude;
    m['reader_longitude'] = position.longitude;
    return m;
  }

  /// Compact string for fallback when API ignores `context` object.
  static String encodeFallback(Map<String, dynamic> ctx) {
    try {
      return 'ctx=${base64Url.encode(utf8.encode(jsonEncode(ctx)))}';
    } catch (_) {
      return '';
    }
  }
}
