import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_controller.dart';
import '../../../../models/sos_report.dart';
import '../../../../services/emergency_repository.dart';
import '../../../../services/location_service.dart';

final sosControllerProvider =
    StateNotifierProvider<SosController, AsyncValue<SosReport?>>((ref) {
  return SosController(ref);
});

class SosController extends StateNotifier<AsyncValue<SosReport?>> {
  SosController(this._ref) : super(const AsyncData(null));

  final Ref _ref;

  Future<SosReport> submitSos({
    required String disasterId,
    required int peopleCount,
    required String injuryStatus,
  }) async {
    state = const AsyncLoading();

    final result = await AsyncValue.guard(() async {
      final user = _ref.read(currentUserProvider);
      if (user == null) {
        throw Exception('You must be logged in to send SOS.');
      }

      final location = await _ref.read(locationServiceProvider).getCurrentPosition();
      final repository = _ref.read(emergencyRepositoryProvider);

      final report = await repository.createSosReport(
        userId: user.id,
        disasterId: disasterId,
        latitude: location.latitude,
        longitude: location.longitude,
        peopleCount: peopleCount,
        injuryStatus: injuryStatus,
      );

      final unit = await repository.nearestAvailableUnit(
        latitude: location.latitude,
        longitude: location.longitude,
      );

      if (unit != null) {
        await repository.markRescueUnitBusy(unit.id);
      }

      return report;
    });

    state = result;
    if (result.hasError) throw result.error!;
    return result.value!;
  }
}
