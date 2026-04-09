import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../models/citizen_report.dart';
import '../../../../services/emergency_repository.dart';
import '../../../../services/location_service.dart';

final reportControllerProvider =
    StateNotifierProvider<ReportController, AsyncValue<CitizenReport?>>((ref) {
  return ReportController(ref);
});

class ReportController extends StateNotifier<AsyncValue<CitizenReport?>> {
  ReportController(this._ref) : super(const AsyncData(null));

  final Ref _ref;

  Future<CitizenReport> submit({
    required String category,
    required String description,
    String? eventId,
  }) async {
    state = const AsyncLoading();

    final result = await AsyncValue.guard(() async {
      final location = await _ref.read(locationServiceProvider).getCurrentPosition();
      return _ref.read(emergencyRepositoryProvider).createCitizenReport(
            source: category,
            latitude: location.latitude,
            longitude: location.longitude,
            description: description,
            eventId: eventId,
          );
    });

    state = result;
    if (result.hasError) throw result.error!;
    return result.value!;
  }
}
