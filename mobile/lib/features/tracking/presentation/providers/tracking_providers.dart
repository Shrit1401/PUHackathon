import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/geo_math.dart';
import '../../../../models/rescue_unit.dart';
import '../../../../models/sos_report.dart';
import '../../../../services/emergency_repository.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';

final trackedReportProvider = Provider.family<SosReport?, String>((ref, reportId) {
  final peek = ref.read(emergencyRepositoryProvider).peekReport(reportId);
  if (peek != null) return peek;
  final reports = ref.watch(mySosReportsProvider).valueOrNull;
  if (reports == null) return null;
  for (final report in reports) {
    if (report.id == reportId) return report;
  }
  return null;
});

final trackedUnitProvider = Provider.family<RescueUnit?, String>((ref, reportId) {
  final report = ref.watch(trackedReportProvider(reportId));
  final units = ref.watch(rescueUnitsProvider).valueOrNull;
  if (report == null || units == null || units.isEmpty) return null;

  final candidates = units.where((u) => u.status == 'busy').toList();
  final list = candidates.isEmpty ? units : candidates;

  list.sort((a, b) {
    final d1 = GeoMath.haversineKm(
      lat1: report.latitude,
      lon1: report.longitude,
      lat2: a.latitude,
      lon2: a.longitude,
    );
    final d2 = GeoMath.haversineKm(
      lat1: report.latitude,
      lon1: report.longitude,
      lat2: b.latitude,
      lon2: b.longitude,
    );
    return d1.compareTo(d2);
  });

  return list.first;
});

final etaMinutesProvider = Provider.family<int?, String>((ref, reportId) {
  final report = ref.watch(trackedReportProvider(reportId));
  final unit = ref.watch(trackedUnitProvider(reportId));
  if (report == null || unit == null) return null;

  final distanceKm = GeoMath.haversineKm(
    lat1: report.latitude,
    lon1: report.longitude,
    lat2: unit.latitude,
    lon2: unit.longitude,
  );
  const averageSpeedKmh = 35.0;
  final etaHours = distanceKm / averageSpeedKmh;
  return (etaHours * 60).ceil();
});

final sosAiGuidanceStoreProvider =
    StateNotifierProvider<SosAiGuidanceStore, Map<String, SosAiGuidance>>((ref) {
  return SosAiGuidanceStore();
});

final sosAiGuidanceProvider = Provider.family<SosAiGuidance?, String>((ref, reportId) {
  final map = ref.watch(sosAiGuidanceStoreProvider);
  return map[reportId];
});

class SosAiGuidanceStore extends StateNotifier<Map<String, SosAiGuidance>> {
  SosAiGuidanceStore() : super(const {});

  void put(String reportId, SosAiGuidance? guidance) {
    if (guidance == null || reportId.trim().isEmpty) return;
    state = {...state, reportId: guidance};
  }
}
