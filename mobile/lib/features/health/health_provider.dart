import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/health_service.dart';

final healthProvider =
    StateNotifierProvider<HealthController, AsyncValue<HealthAdvice?>>((ref) {
  return HealthController(ref);
});

class HealthController extends StateNotifier<AsyncValue<HealthAdvice?>> {
  HealthController(this._ref) : super(const AsyncData(null));

  final Ref _ref;

  Future<void> analyze(String symptoms) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final advice = await _ref.read(healthServiceProvider).getHealthAdvice(symptoms);
      return advice;
    });
  }
}
