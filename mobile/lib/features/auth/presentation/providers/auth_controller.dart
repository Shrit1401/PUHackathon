import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/auth_repository.dart';

final authStateChangesProvider = StreamProvider<DashboardUser?>((ref) {
  return ref.read(authRepositoryProvider).authState;
});

final currentUserProvider = Provider<DashboardUser?>((ref) {
  ref.watch(authStateChangesProvider);
  return ref.read(authRepositoryProvider).currentUser;
});

final authActionProvider =
    StateNotifierProvider<AuthActionController, AsyncValue<void>>((ref) {
  return AuthActionController(ref.read(authRepositoryProvider));
});

class AuthActionController extends StateNotifier<AsyncValue<void>> {
  AuthActionController(this._repository) : super(const AsyncData(null));

  final AuthRepository _repository;

  Future<void> sendPhoneOtp(String phone) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _repository.sendPhoneOtp(phone);
    });
  }

  Future<void> verifyPhoneOtp({
    required String phone,
    required String token,
    String? fullName,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _repository.verifyPhoneOtp(
        phone: phone,
        token: token,
        fullName: fullName,
      );
    });
  }

  Future<void> logout() => _repository.signOut();
}
