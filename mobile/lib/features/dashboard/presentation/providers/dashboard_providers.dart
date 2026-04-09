import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/utils/geo_math.dart';
import '../../../../models/citizen_report.dart';
import '../../../../models/disaster_event.dart';
import '../../../../models/grid_risk_point.dart';
import '../../../../models/rescue_unit.dart';
import '../../../../models/social_feed_item.dart';
import '../../../../models/sos_report.dart';
import '../../../../services/emergency_repository.dart';
import '../../../../services/location_service.dart';
import '../../../auth/presentation/providers/auth_controller.dart';

final currentPositionProvider = FutureProvider<Position>((ref) async {
  return ref.read(locationServiceProvider).getCurrentPosition();
});

final disasterEventsProvider = StreamProvider<List<DisasterEvent>>((ref) {
  return ref.read(emergencyRepositoryProvider).streamDisasterEvents();
});

/// Mobile-app home feed: use this instead of `/events/nearby`.
final socialFeedProvider = StreamProvider<List<SocialFeedItem>>((ref) {
  final pos = ref.watch(currentPositionProvider).valueOrNull;
  if (pos == null) return const Stream.empty();
  return ref.read(emergencyRepositoryProvider).streamSocialFeed(
        latitude: pos.latitude,
        longitude: pos.longitude,
        radiusKm: 10,
      );
});

final nearestSocialFeedItemProvider = Provider<SocialFeedItem?>((ref) {
  final items = ref.watch(socialFeedProvider).valueOrNull;
  if (items == null || items.isEmpty) return null;
  final sorted = [...items]..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
  return sorted.first;
});

final rescueUnitsProvider = StreamProvider<List<RescueUnit>>((ref) {
  return ref.read(emergencyRepositoryProvider).streamRescueUnits();
});

final reportsProvider = StreamProvider<List<CitizenReport>>((ref) {
  return ref.read(emergencyRepositoryProvider).streamReports();
});

final gridRiskProvider = StreamProvider<List<GridRiskPoint>>((ref) {
  return ref.read(emergencyRepositoryProvider).streamGridRisk();
});

final mySosReportsProvider = StreamProvider<List<SosReport>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    return const Stream.empty();
  }
  return ref.read(emergencyRepositoryProvider).streamCurrentUserReports(user.id);
});

final nearestRiskEventProvider = Provider<DisasterEvent?>((ref) {
  final events = ref.watch(disasterEventsProvider).valueOrNull;
  final pos = ref.watch(currentPositionProvider).valueOrNull;
  if (events == null || events.isEmpty || pos == null) return null;

  final sorted = [...events]
    ..sort((a, b) {
      final d1 = GeoMath.haversineKm(
        lat1: pos.latitude,
        lon1: pos.longitude,
        lat2: a.latitude,
        lon2: a.longitude,
      );
      final d2 = GeoMath.haversineKm(
        lat1: pos.latitude,
        lon1: pos.longitude,
        lat2: b.latitude,
        lon2: b.longitude,
      );
      return d1.compareTo(d2);
    });

  return sorted.first;
});

final nearestAvailableRescueUnitsProvider = Provider<List<RescueUnit>>((ref) {
  final units = ref.watch(rescueUnitsProvider).valueOrNull;
  final pos = ref.watch(currentPositionProvider).valueOrNull;
  if (units == null || pos == null) return [];

  final available = units.where((u) => u.status == 'available').toList();
  final ranked = available.isEmpty ? [...units] : available;

  ranked.sort((a, b) {
    final d1 = GeoMath.haversineKm(
      lat1: pos.latitude,
      lon1: pos.longitude,
      lat2: a.latitude,
      lon2: a.longitude,
    );
    final d2 = GeoMath.haversineKm(
      lat1: pos.latitude,
      lon1: pos.longitude,
      lat2: b.latitude,
      lon2: b.longitude,
    );
    return d1.compareTo(d2);
  });

  return ranked.take(3).toList();
});

final activeReportProvider = Provider<SosReport?>((ref) {
  final reports = ref.watch(mySosReportsProvider).valueOrNull;
  if (reports == null || reports.isEmpty) return null;
  return reports.first;
});

final activeAlertsCountProvider = Provider<int>((ref) {
  final events = ref.watch(disasterEventsProvider).valueOrNull ?? [];
  return events.length;
});

final currentDisasterConfidenceProvider = Provider<double>((ref) {
  final events = ref.watch(disasterEventsProvider).valueOrNull ?? [];
  if (events.isEmpty) return 0;
  final maxConfidence = events
      .map((e) => e.confidenceScore <= 1 ? e.confidenceScore * 100 : e.confidenceScore)
      .reduce((a, b) => a > b ? a : b);
  return maxConfidence.clamp(0, 100);
});

final weatherSeverityProvider = Provider<double>((ref) {
  final risks = ref.watch(gridRiskProvider).valueOrNull ?? [];
  if (risks.isEmpty) return 0;
  final maxRisk = risks
      .map((r) => r.riskScore <= 1 ? r.riskScore * 100 : r.riskScore)
      .reduce((a, b) => a > b ? a : b);
  return maxRisk.clamp(0, 100);
});

final socialSignalCountProvider = Provider<int>((ref) {
  final reports = ref.watch(reportsProvider).valueOrNull ?? [];
  return reports.where((r) => r.source.toLowerCase() == 'social').length;
});

final newsHeadlinesProvider = Provider<List<String>>((ref) {
  final reports = ref.watch(reportsProvider).valueOrNull ?? [];
  final fromNews = reports
      .where((r) => r.source.toLowerCase() == 'news')
      .map((r) => r.description.trim())
      .where((d) => d.isNotEmpty)
      .take(8)
      .toList();
  if (fromNews.isNotEmpty) return fromNews;

  final events = ref.watch(disasterEventsProvider).valueOrNull ?? [];
  return events
      .take(5)
      .map((e) => 'Field update: ${e.type.toUpperCase()} risk escalated in monitored grid.')
      .toList();
});

final citizenSosReportsProvider = Provider<List<CitizenReport>>((ref) {
  final reports = ref.watch(reportsProvider).valueOrNull ?? [];
  return reports
      .where((r) {
        final source = r.source.toLowerCase();
        return source == 'app' || source == 'citizen_mobile' || source == 'whatsapp';
      })
      .toList();
});
