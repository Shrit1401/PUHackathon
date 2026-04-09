import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../models/news_article.dart';
import '../../../../models/social_feed_item.dart';
import '../../../../services/emergency_repository.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';

final socialFeedProvider = StreamProvider<List<SocialFeedItem>>((ref) {
  final pos = ref.watch(currentPositionProvider).valueOrNull;
  if (pos == null) return const Stream.empty();
  return ref.read(emergencyRepositoryProvider).streamSocialFeed(
        latitude: pos.latitude,
        longitude: pos.longitude,
      );
});

final newsProvider = FutureProvider.family<NewsResponse, String?>((ref, disasterType) {
  return ref.read(emergencyRepositoryProvider).getNews(disasterType: disasterType);
});

final socialActionControllerProvider = StateNotifierProvider<SocialActionController, AsyncValue<void>>((ref) {
  return SocialActionController(ref);
});

class SocialActionController extends StateNotifier<AsyncValue<void>> {
  SocialActionController(this._ref) : super(const AsyncData(null));

  final Ref _ref;

  Future<void> confirmEvent(String eventId) async {
    final pos = _ref.read(currentPositionProvider).valueOrNull;
    if (pos == null) throw Exception('Location not available yet.');

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _ref.read(emergencyRepositoryProvider).confirmSocialEvent(
        eventId: eventId,
        latitude: pos.latitude,
        longitude: pos.longitude,
      );
    });
  }

  Future<void> postObservation({
    required String disasterType,
    required String observation,
  }) async {
    final pos = _ref.read(currentPositionProvider).valueOrNull;
    if (pos == null) throw Exception('Location not available yet.');

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _ref.read(emergencyRepositoryProvider).postSocialObservation(
        latitude: pos.latitude,
        longitude: pos.longitude,
        disasterType: disasterType,
        observation: observation,
      );
    });
  }
}
