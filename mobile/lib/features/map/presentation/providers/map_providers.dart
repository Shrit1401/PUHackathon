import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../../models/citizen_report.dart';
import '../../../../models/disaster_event.dart';
import '../../../../models/grid_risk_point.dart';
import '../../../../services/emergency_repository.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';

final gridRiskProvider = StreamProvider<List<GridRiskPoint>>((ref) {
  return ref.read(emergencyRepositoryProvider).streamGridRisk();
});

final reportsFeedProvider = StreamProvider<List<CitizenReport>>((ref) {
  return ref.read(emergencyRepositoryProvider).streamReports();
});

final mapCenterProvider = Provider<LatLng>((ref) {
  final pos = ref.watch(currentPositionProvider).valueOrNull;
  if (pos != null) {
    return LatLng(pos.latitude, pos.longitude);
  }

  final events = ref.watch(disasterEventsProvider).valueOrNull;
  if (events != null && events.isNotEmpty) {
    final e = events.first;
    return LatLng(e.latitude, e.longitude);
  }

  return const LatLng(37.7749, -122.4194);
});

final hotspotEventsProvider = Provider<List<DisasterEvent>>((ref) {
  final events = ref.watch(disasterEventsProvider).valueOrNull ?? [];
  return events.take(20).toList();
});
