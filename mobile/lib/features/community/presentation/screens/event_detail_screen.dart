import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/localization/app_language.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/offline_status_bar.dart';
import '../../../../models/social_feed_item.dart';
import '../../../../services/emergency_repository.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';
import '../providers/community_providers.dart';

class EventDetailScreen extends ConsumerWidget {
  const EventDetailScreen({super.key, required this.eventId});

  final String eventId;

  Color _riskColor(double confidence) {
    if (confidence >= 80) return const Color(0xFFFF3B30);
    if (confidence >= 50) return const Color(0xFFFF9F0A);
    return const Color(0xFF34C759);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(appLanguageProvider);
    final repo = ref.read(emergencyRepositoryProvider);
    final pos = ref.watch(currentPositionProvider).valueOrNull;
    final user = ref.watch(currentUserProvider);

    final feed = ref.watch(communityFeedProvider).valueOrNull ?? [];
    final item = feed.cast<SocialFeedItem?>().firstWhere(
          (e) => e?.id == eventId,
          orElse: () => null,
        );

    final conf = ref.watch(eventConfirmationsProvider(eventId));

    final center = LatLng(
      (item?.latitude ?? pos?.latitude ?? 20.5937),
      (item?.longitude ?? pos?.longitude ?? 78.9629),
    );

    final confidence = item?.confidence ?? 0;
    final c = _riskColor(confidence);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const OfflineStatusBar(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      item == null ? 'Event' : _title(item.type),
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                children: [
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                switch (lang) {
                                  AppLanguage.hi => 'स्थिति',
                                  AppLanguage.kn => 'ಸ್ಥಿತಿ',
                                  AppLanguage.en => 'Status',
                                },
                                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                      color: Colors.white.withValues(alpha: 0.70),
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ),
                            Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: c.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(color: c.withValues(alpha: 0.45)),
                              ),
                              child: Text(
                                '${confidence.toStringAsFixed(0)}%',
                                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                      color: c,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.5,
                                    ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          item == null
                              ? switch (lang) {
                                  AppLanguage.hi => 'पास में अलर्ट',
                                  AppLanguage.kn => 'ಹತ್ತಿರ ಎಚ್ಚರಿಕೆ',
                                  AppLanguage.en => 'Nearby alert',
                                }
                              : '${item.distanceKm.toStringAsFixed(1)} km • ${item.confirmations} ${tr(ref, 'confirmations')}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 56,
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: pos == null
                                ? null
                                : () async {
                                    try {
                                      await repo.confirmSocialEvent(
                                        eventId: eventId,
                                        latitude: pos.latitude,
                                        longitude: pos.longitude,
                                        userId: user?.id,
                                      );
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            switch (lang) {
                                              AppLanguage.hi =>
                                                'पुष्टि दर्ज हुई। धन्यवाद।',
                                              AppLanguage.kn =>
                                                'ದೃಢೀಕರಣ ದಾಖಲಾಗಿದೆ. ಧನ್ಯವಾದಗಳು.',
                                              AppLanguage.en =>
                                                'Confirmation recorded. Thank you.',
                                            },
                                          ),
                                        ),
                                      );
                                      ref.invalidate(communityFeedProvider);
                                      ref.invalidate(eventConfirmationsProvider(eventId));
                                    } catch (e) {
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text(e.toString())),
                                      );
                                    }
                                  },
                            icon: const Icon(Icons.check_circle_outline),
                            label: Text(tr(ref, 'confirm_sighting')),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  GlassCard(
                    padding: EdgeInsets.zero,
                    child: SizedBox(
                      height: 220,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: FlutterMap(
                          options: MapOptions(
                            initialCenter: center,
                            initialZoom: 13,
                            interactionOptions:
                                const InteractionOptions(flags: InteractiveFlag.none),
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.resqnet.app',
                            ),
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: center,
                                  width: 44,
                                  height: 44,
                                  child: Icon(Icons.warning_amber_rounded,
                                      color: c, size: 34),
                                ),
                              ],
                            ),
                            conf.when(
                              data: (r) => MarkerLayer(
                                markers: r.confirmations
                                    .take(40)
                                    .map(
                                      (p) => Marker(
                                        point: LatLng(p.latitude, p.longitude),
                                        width: 18,
                                        height: 18,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(alpha: 0.85),
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: c.withValues(alpha: 0.7),
                                              width: 2,
                                            ),
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                              loading: () => const SizedBox.shrink(),
                              error: (_, __) => const SizedBox.shrink(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          switch (lang) {
                            AppLanguage.hi => 'पुष्टियाँ',
                            AppLanguage.kn => 'ದೃಢೀಕರಣಗಳು',
                            AppLanguage.en => 'Confirmations',
                          },
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        const SizedBox(height: 10),
                        conf.when(
                          data: (r) {
                            if (r.confirmations.isEmpty) {
                              return Text(
                                switch (lang) {
                                  AppLanguage.hi => 'अभी कोई पुष्टि नहीं।',
                                  AppLanguage.kn => 'ಇನ್ನೂ ದೃಢೀಕರಣ ಇಲ್ಲ.',
                                  AppLanguage.en => 'No confirmations yet.',
                                },
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: Colors.white.withValues(alpha: 0.70),
                                      fontWeight: FontWeight.w600,
                                    ),
                              );
                            }
                            return Column(
                              children: [
                                for (final p in r.confirmations.take(6)) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.04),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.08),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 10,
                                          height: 10,
                                          decoration: BoxDecoration(
                                            color: c,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            '${p.latitude.toStringAsFixed(4)}, ${p.longitude.toStringAsFixed(4)}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelLarge
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w700,
                                                ),
                                          ),
                                        ),
                                        Text(
                                          _timeShort(p.createdAt.toLocal()),
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelLarge
                                              ?.copyWith(
                                                color:
                                                    Colors.white.withValues(alpha: 0.6),
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                ],
                              ],
                            );
                          },
                          loading: () => const Center(
                            child: Padding(
                              padding: EdgeInsets.all(12),
                              child: CircularProgressIndicator(),
                            ),
                          ),
                          error: (e, _) => Text('Error: $e'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _title(String s) {
    final t = s.trim();
    if (t.isEmpty) return 'Alert';
    return t.substring(0, 1).toUpperCase() + t.substring(1).toLowerCase();
  }

  static String _timeShort(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

