import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../models/news_article.dart';
import '../../../../models/social_feed_item.dart';
import '../../../../services/emergency_repository.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';

final communityFeedProvider = StreamProvider<List<SocialFeedItem>>((ref) {
  final pos = ref.watch(currentPositionProvider).valueOrNull;
  if (pos == null) return const Stream.empty();
  return ref.read(emergencyRepositoryProvider).streamSocialFeed(
        latitude: pos.latitude,
        longitude: pos.longitude,
        radiusKm: 10,
      );
});

final communityNewsProvider =
    FutureProvider.family<NewsResponse, String?>((ref, disasterType) async {
  return ref.read(emergencyRepositoryProvider).getNews(disasterType: disasterType);
});

final eventConfirmationsProvider =
    FutureProvider.family<EventConfirmationsResponse, String>((ref, eventId) async {
  return ref.read(emergencyRepositoryProvider).getEventConfirmations(eventId);
});

final mediaListProvider =
    FutureProvider.family<Map<String, dynamic>, ({String? disasterType, int limit})>(
        (ref, args) async {
  return ref
      .read(emergencyRepositoryProvider)
      .getMediaList(disasterType: args.disasterType, limit: args.limit);
});

