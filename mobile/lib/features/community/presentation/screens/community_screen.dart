import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_language.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/language_toggle.dart';
import '../../../../core/widgets/offline_status_bar.dart';
import '../../../../models/social_feed_item.dart';
import '../../../../services/emergency_repository.dart';
import '../../../../services/location_service.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';
import '../providers/community_providers.dart';

enum _CommunityTab { feed, news, photos }

class CommunityScreen extends ConsumerStatefulWidget {
  const CommunityScreen({super.key});

  @override
  ConsumerState<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends ConsumerState<CommunityScreen> {
  _CommunityTab _tab = _CommunityTab.feed;
  String _newsFilter = 'all';

  Future<void> _postQuickStatus({required bool safe}) async {
    HapticFeedback.selectionClick();
    final lang = ref.read(appLanguageProvider);
    final repo = ref.read(emergencyRepositoryProvider);
    final user = ref.read(currentUserProvider);

    try {
      final pos = await ref.read(locationServiceProvider).getCurrentPosition();
      final msg = safe
          ? switch (lang) {
              AppLanguage.hi => 'मैं सुरक्षित हूँ।',
              AppLanguage.kn => 'ನಾನು ಸುರಕ್ಷಿತವಾಗಿದ್ದೇನೆ.',
              AppLanguage.en => "I'm safe.",
            }
          : switch (lang) {
              AppLanguage.hi => 'मदद चाहिए।',
              AppLanguage.kn => 'ಸಹಾಯ ಬೇಕು.',
              AppLanguage.en => 'Need help.',
            };

      await repo.postSocialObservation(
        latitude: pos.latitude,
        longitude: pos.longitude,
        disasterType: 'other',
        observation: msg,
        userId: user?.id,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            safe
                ? switch (lang) {
                    AppLanguage.hi => 'सुरक्षित अपडेट पोस्ट हो गया।',
                    AppLanguage.kn => 'ಸುರಕ್ಷಿತ ಅಪ್ಡೇಟ್ ಪೋಸ್ಟ್ ಆಯಿತು.',
                    AppLanguage.en => 'Safety update posted.',
                  }
                : switch (lang) {
                    AppLanguage.hi => 'मदद का संदेश पोस्ट हो गया।',
                    AppLanguage.kn => 'ಸಹಾಯ ಸಂದೇಶ ಪೋಸ್ಟ್ ಆಯಿತು.',
                    AppLanguage.en => 'Help message posted.',
                  },
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _openObservationSheet({String? presetType}) async {
    final lang = ref.read(appLanguageProvider);
    final repo = ref.read(emergencyRepositoryProvider);
    final user = ref.read(currentUserProvider);
    final pos = ref.read(currentPositionProvider).valueOrNull;

    if (pos == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            switch (lang) {
              AppLanguage.hi => 'लोकेशन उपलब्ध नहीं है।',
              AppLanguage.kn => 'ಸ್ಥಳ ಲಭ್ಯವಿಲ್ಲ.',
              AppLanguage.en => 'Location not available yet.',
            },
          ),
        ),
      );
      return;
    }

    final type = ValueNotifier<String>(presetType ?? 'flood');
    final text = TextEditingController();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final bottom = MediaQuery.of(context).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.only(bottom: bottom),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0E1320),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
              border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
            ),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 48,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    switch (lang) {
                      AppLanguage.hi => 'जल्दी नोट',
                      AppLanguage.kn => 'ತ್ವರಿತ ಟಿಪ್ಪಣಿ',
                      AppLanguage.en => 'Quick Observation',
                    },
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 10),
                  ValueListenableBuilder(
                    valueListenable: type,
                    builder: (context, v, _) {
                      return Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          for (final t in const ['flood', 'fire', 'earthquake', 'landslide', 'other'])
                            ChoiceChip(
                              label: Text(t.toUpperCase()),
                              selected: v == t,
                              onSelected: (_) => type.value = t,
                              labelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                              backgroundColor: Colors.white.withValues(alpha: 0.06),
                              selectedColor: Colors.white.withValues(alpha: 0.14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                                side: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: text,
                    minLines: 2,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: switch (lang) {
                        AppLanguage.hi => 'जो दिख रहा है, 1–2 लाइन में…',
                        AppLanguage.kn => 'ನೀವು ನೋಡಿದದ್ದು 1–2 ಸಾಲುಗಳಲ್ಲಿ…',
                        AppLanguage.en => 'What you see, in 1–2 lines…',
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 56,
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () async {
                        final msg = text.text.trim();
                        if (msg.length < 6) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                switch (lang) {
                                  AppLanguage.hi => 'कृपया थोड़ा और लिखें।',
                                  AppLanguage.kn => 'ಸ್ವಲ್ಪ ಇನ್ನಷ್ಟು ಬರೆಯಿರಿ.',
                                  AppLanguage.en => 'Please add a bit more.',
                                },
                              ),
                            ),
                          );
                          return;
                        }
                        try {
                          await repo.postSocialObservation(
                            latitude: pos.latitude,
                            longitude: pos.longitude,
                            disasterType: type.value,
                            observation: msg,
                            userId: user?.id,
                          );
                          if (!context.mounted) return;
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                switch (lang) {
                                  AppLanguage.hi => 'पोस्ट हो गया। धन्यवाद।',
                                  AppLanguage.kn => 'ಪೋಸ್ಟ್ ಆಯಿತು. ಧನ್ಯವಾದಗಳು.',
                                  AppLanguage.en => 'Posted. Thank you.',
                                },
                              ),
                            ),
                          );
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(e.toString())),
                          );
                        }
                      },
                      icon: const Icon(Icons.send),
                      label: Text(
                        switch (lang) {
                          AppLanguage.hi => 'पोस्ट करें',
                          AppLanguage.kn => 'ಪೋಸ್ಟ್',
                          AppLanguage.en => 'Post',
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(appLanguageProvider);

    final feed = ref.watch(communityFeedProvider);
    final filter = _newsFilter == 'all' ? null : _newsFilter;
    final news = ref.watch(communityNewsProvider(filter));
    final media = ref.watch(mediaListProvider((disasterType: null, limit: 50)));

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const OfflineStatusBar(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      switch (lang) {
                        AppLanguage.hi => 'कम्युनिटी',
                        AppLanguage.kn => 'ಸಮುದಾಯ',
                        AppLanguage.en => 'Community',
                      },
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                  ),
                  const LanguageToggle(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: SegmentedButton<_CommunityTab>(
                segments: [
                  ButtonSegment(
                    value: _CommunityTab.feed,
                    label: Text(
                      switch (lang) {
                        AppLanguage.hi => 'फीड',
                        AppLanguage.kn => 'ಫೀಡ್',
                        AppLanguage.en => 'Feed',
                      },
                    ),
                  ),
                  ButtonSegment(
                    value: _CommunityTab.news,
                    label: Text(
                      switch (lang) {
                        AppLanguage.hi => 'समाचार',
                        AppLanguage.kn => 'ಸುದ್ದಿ',
                        AppLanguage.en => 'News',
                      },
                    ),
                  ),
                  ButtonSegment(
                    value: _CommunityTab.photos,
                    label: Text(
                      switch (lang) {
                        AppLanguage.hi => 'फोटो',
                        AppLanguage.kn => 'ಫೋಟೋ',
                        AppLanguage.en => 'Photos',
                      },
                    ),
                  ),
                ],
                selected: {_tab},
                showSelectedIcon: false,
                onSelectionChanged: (s) => setState(() => _tab = s.first),
              ),
            ),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                children: [
                  if (_tab == _CommunityTab.feed) ...[
                    GlassCard(
                      child: Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 56,
                              child: FilledButton.tonalIcon(
                                onPressed: () => _postQuickStatus(safe: true),
                                icon: const Icon(Icons.verified),
                                label: Text(tr(ref, 'quick_safe')),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: SizedBox(
                              height: 56,
                              child: FilledButton.icon(
                                style: FilledButton.styleFrom(
                                  backgroundColor:
                                      const Color(0xFFFF3B30).withValues(alpha: 0.92),
                                ),
                                onPressed: () => _postQuickStatus(safe: false),
                                icon: const Icon(Icons.sos),
                                label: Text(tr(ref, 'quick_need_help')),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 56,
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => _openObservationSheet(),
                        icon: const Icon(Icons.edit_note),
                        label: Text(
                          switch (lang) {
                            AppLanguage.hi => 'जल्दी नोट पोस्ट करें',
                            AppLanguage.kn => 'ತ್ವರಿತ ಟಿಪ್ಪಣಿ ಪೋಸ್ಟ್ ಮಾಡಿ',
                            AppLanguage.en => 'Post a quick observation',
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    feed.when(
                      data: (items) {
                        if (items.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.all(18),
                            child: Text(
                              switch (lang) {
                                AppLanguage.hi => 'अभी पास में कोई कम्युनिटी अलर्ट नहीं।',
                                AppLanguage.kn => 'ಈಗ ಹತ್ತಿರ ಯಾವುದೇ ಸಮುದಾಯ ಎಚ್ಚರಿಕೆ ಇಲ್ಲ.',
                                AppLanguage.en => 'No nearby community alerts right now.',
                              },
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.70),
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          );
                        }

                        return Column(
                          children: [
                            for (final item in items) ...[
                              _FeedCard(
                                item: item,
                                onOpen: () => context.push('/community/event/${item.id}'),
                                onQuickNote: () => _openObservationSheet(presetType: item.type),
                              ),
                              const SizedBox(height: 10),
                            ],
                          ],
                        );
                      },
                      loading: () => const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (e, _) => Text('Error: $e'),
                    ),
                  ],
                  if (_tab == _CommunityTab.news) ...[
                    GlassCard(
                      child: DropdownButtonFormField<String>(
                        initialValue: _newsFilter,
                        decoration: InputDecoration(
                          labelText: switch (lang) {
                            AppLanguage.hi => 'फ़िल्टर',
                            AppLanguage.kn => 'ಫಿಲ್ಟರ್',
                            AppLanguage.en => 'Filter',
                          },
                        ),
                        items: const [
                          DropdownMenuItem(value: 'all', child: Text('All')),
                          DropdownMenuItem(value: 'flood', child: Text('Flood')),
                          DropdownMenuItem(value: 'earthquake', child: Text('Earthquake')),
                          DropdownMenuItem(value: 'fire', child: Text('Fire')),
                          DropdownMenuItem(value: 'landslide', child: Text('Landslide')),
                          DropdownMenuItem(value: 'other', child: Text('Other')),
                        ],
                        onChanged: (v) => setState(() => _newsFilter = v ?? 'all'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    news.when(
                      data: (n) {
                        if (n.articles.isEmpty) {
                          return Text(
                            switch (lang) {
                              AppLanguage.hi => 'समाचार उपलब्ध नहीं।',
                              AppLanguage.kn => 'ಸುದ್ದಿ ಲಭ್ಯವಿಲ್ಲ.',
                              AppLanguage.en => 'No news available.',
                            },
                          );
                        }
                        return Column(
                          children: [
                            for (final a in n.articles) ...[
                              _NewsCard(article: a),
                              const SizedBox(height: 10),
                            ],
                          ],
                        );
                      },
                      loading: () => const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (e, _) => Text('Error: $e'),
                    ),
                  ],
                  if (_tab == _CommunityTab.photos) ...[
                    media.when(
                      data: (json) {
                        final files = (json['files'] as List?) ?? const [];
                        if (files.isEmpty) {
                          return Text(
                            switch (lang) {
                              AppLanguage.hi => 'कोई फोटो नहीं।',
                              AppLanguage.kn => 'ಯಾವುದೇ ಫೋಟೋ ಇಲ್ಲ.',
                              AppLanguage.en => 'No photos yet.',
                            },
                          );
                        }
                        final items = files
                            .whereType<Map>()
                            .map((m) => Map<String, dynamic>.from(m))
                            .where((m) => (m['url'] ?? '').toString().isNotEmpty)
                            .take(60)
                            .toList(growable: false);

                        return LayoutBuilder(
                          builder: (context, constraints) {
                            final w = constraints.maxWidth;
                            final crossAxisCount = w >= 520 ? 3 : 2;
                            final spacing = 10.0;
                            final tileW = (w - (spacing * (crossAxisCount - 1))) / crossAxisCount;
                            final tileH = tileW * 0.78;

                            return GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: items.length,
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: spacing,
                                mainAxisSpacing: spacing,
                                childAspectRatio: tileW / tileH,
                              ),
                              itemBuilder: (context, i) {
                                final m = items[i];
                                final url = (m['url'] ?? '').toString();
                                final name = (m['name'] ?? 'photo').toString();
                                final created = (m['created_at'] ?? '').toString();

                                return InkWell(
                                  borderRadius: BorderRadius.circular(18),
                                  onTap: () => showDialog<void>(
                                    context: context,
                                    barrierColor: Colors.black.withValues(alpha: 0.6),
                                    builder: (context) {
                                      return Dialog(
                                        backgroundColor: const Color(0xFF0E1320),
                                        insetPadding: const EdgeInsets.all(14),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(22),
                                          side: BorderSide(
                                            color: Colors.white.withValues(alpha: 0.10),
                                          ),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      name,
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .titleMedium
                                                          ?.copyWith(
                                                            fontWeight: FontWeight.w900,
                                                          ),
                                                    ),
                                                  ),
                                                  IconButton(
                                                    onPressed: () => Navigator.of(context).pop(),
                                                    icon: const Icon(Icons.close),
                                                  ),
                                                ],
                                              ),
                                              if (created.isNotEmpty) ...[
                                                Text(
                                                  created,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .labelLarge
                                                      ?.copyWith(
                                                        color: Colors.white.withValues(alpha: 0.65),
                                                        fontWeight: FontWeight.w700,
                                                      ),
                                                ),
                                                const SizedBox(height: 10),
                                              ],
                                              ClipRRect(
                                                borderRadius: BorderRadius.circular(18),
                                                child: AspectRatio(
                                                  aspectRatio: 4 / 3,
                                                  child: InteractiveViewer(
                                                    minScale: 1,
                                                    maxScale: 4,
                                                    child: Image.network(
                                                      url,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (_, __, ___) => Container(
                                                        color: Colors.white.withValues(alpha: 0.06),
                                                        alignment: Alignment.center,
                                                        child: Text(
                                                          switch (lang) {
                                                            AppLanguage.hi => 'फोटो नहीं खुल पाया',
                                                            AppLanguage.kn => 'ಫೋಟೋ ತೆರೆಯಲಿಲ್ಲ',
                                                            AppLanguage.en => 'Could not load photo',
                                                          },
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 12),
                                              SizedBox(
                                                width: double.infinity,
                                                height: 56,
                                                child: FilledButton.tonalIcon(
                                                  onPressed: () async {
                                                    await Clipboard.setData(ClipboardData(text: url));
                                                    if (!context.mounted) return;
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(content: Text(tr(ref, 'copied'))),
                                                    );
                                                  },
                                                  icon: const Icon(Icons.copy),
                                                  label: Text(
                                                    switch (lang) {
                                                      AppLanguage.hi => 'लिंक कॉपी करें',
                                                      AppLanguage.kn => 'ಲಿಂಕ್ ಕಾಪಿ',
                                                      AppLanguage.en => 'Copy link',
                                                    },
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(18),
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        Image.network(
                                          url,
                                          fit: BoxFit.cover,
                                          cacheWidth: (tileW * MediaQuery.of(context).devicePixelRatio)
                                              .round(),
                                          loadingBuilder: (context, child, progress) {
                                            if (progress == null) return child;
                                            return Container(
                                              color: Colors.white.withValues(alpha: 0.06),
                                              alignment: Alignment.center,
                                              child: const SizedBox(
                                                width: 22,
                                                height: 22,
                                                child: CircularProgressIndicator(strokeWidth: 2),
                                              ),
                                            );
                                          },
                                          errorBuilder: (_, __, ___) => Container(
                                            color: Colors.white.withValues(alpha: 0.06),
                                            alignment: Alignment.center,
                                            child: const Icon(Icons.broken_image),
                                          ),
                                        ),
                                        Positioned(
                                          left: 10,
                                          right: 10,
                                          bottom: 10,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 8),
                                            decoration: BoxDecoration(
                                              color: Colors.black.withValues(alpha: 0.45),
                                              borderRadius: BorderRadius.circular(14),
                                              border: Border.all(
                                                color: Colors.white.withValues(alpha: 0.10),
                                              ),
                                            ),
                                            child: Text(
                                              name,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .labelLarge
                                                  ?.copyWith(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                      loading: () => const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (e, _) => Text('Error: $e'),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedCard extends ConsumerWidget {
  const _FeedCard({
    required this.item,
    required this.onOpen,
    required this.onQuickNote,
  });

  final SocialFeedItem item;
  final VoidCallback onOpen;
  final VoidCallback onQuickNote;

  Color _riskColor(double confidence) {
    if (confidence >= 80) return const Color(0xFFFF3B30);
    if (confidence >= 50) return const Color(0xFFFF9F0A);
    return const Color(0xFF34C759);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(emergencyRepositoryProvider);
    final pos = ref.watch(currentPositionProvider).valueOrNull;
    final user = ref.watch(currentUserProvider);
    final lang = ref.watch(appLanguageProvider);

    final c = _riskColor(item.confidence);

    return GlassCard(
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _title(item.type),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: c.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: c.withValues(alpha: 0.45)),
                    ),
                    child: Text(
                      '${item.confidence.toStringAsFixed(0)}%',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: c,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${item.distanceKm.toStringAsFixed(1)} km • ${item.confirmations} ${tr(ref, 'confirmations')}',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Colors.white.withValues(alpha: 0.68),
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 56,
                      child: FilledButton.tonalIcon(
                        onPressed: pos == null
                            ? null
                            : () async {
                                try {
                                  await repo.confirmSocialEvent(
                                    eventId: item.id,
                                    latitude: pos.latitude,
                                    longitude: pos.longitude,
                                    userId: user?.id,
                                  );
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        switch (lang) {
                                          AppLanguage.hi => 'पुष्टि दर्ज हुई। धन्यवाद।',
                                          AppLanguage.kn => 'ದೃಢೀಕರಣ ದಾಖಲಾಗಿದೆ. ಧನ್ಯವಾದಗಳು.',
                                          AppLanguage.en => 'Confirmation recorded. Thank you.',
                                        },
                                      ),
                                    ),
                                  );
                                } catch (e) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(e.toString())),
                                  );
                                }
                              },
                        icon: const Icon(Icons.check_circle_outline),
                        label: Text(tr(ref, 'confirm')),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 56,
                      child: OutlinedButton.icon(
                        onPressed: onQuickNote,
                        icon: const Icon(Icons.edit_note),
                        label: Text(
                          switch (lang) {
                            AppLanguage.hi => 'नोट',
                            AppLanguage.kn => 'ಟಿಪ್ಪಣಿ',
                            AppLanguage.en => 'Note',
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _title(String s) {
    final t = s.trim();
    if (t.isEmpty) return 'Alert';
    return t.substring(0, 1).toUpperCase() + t.substring(1).toLowerCase();
  }
}

class _NewsCard extends ConsumerWidget {
  const _NewsCard({required this.article});
  final dynamic article;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(appLanguageProvider);
    final a = article as dynamic;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            (a.title ?? '').toString(),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            '${(a.source ?? '').toString()} • ${(a.disasterType ?? '').toString()}',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.68),
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            (a.summary ?? '').toString(),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  height: 1.25,
                ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton.tonalIcon(
              onPressed: () {
                final url = (a.url ?? '').toString();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      url.isEmpty
                          ? switch (lang) {
                              AppLanguage.hi => 'लिंक उपलब्ध नहीं।',
                              AppLanguage.kn => 'ಲಿಂಕ್ ಲಭ್ಯವಿಲ್ಲ.',
                              AppLanguage.en => 'No link available.',
                            }
                          : url,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.link),
              label: Text(
                switch (lang) {
                  AppLanguage.hi => 'लिंक कॉपी करें',
                  AppLanguage.kn => 'ಲಿಂಕ್',
                  AppLanguage.en => 'Link',
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

