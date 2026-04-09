import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/branding.dart';
import '../../../../core/localization/app_language.dart';
import '../../../../core/utils/geo_math.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/language_toggle.dart';
import '../../../../core/widgets/offline_status_bar.dart';
import '../../../../core/widgets/press_effect.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../models/social_feed_item.dart';
import '../../../../services/emergency_repository.dart';
import '../../../../services/location_service.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../../sos/data/sos_context_collector.dart';
import '../../../sos/presentation/widgets/sos_hold_to_send_button.dart';
import '../../../tracking/presentation/providers/tracking_providers.dart';
import '../providers/dashboard_providers.dart';

enum _RiskLevel { safe, moderate, high }

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
      lowerBound: 0.98,
      upperBound: 1.02,
    )..repeat(reverse: true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final repo = ref.read(emergencyRepositoryProvider);
      repo.ensureSosStateLoaded();
      repo.processOfflineSosQueue();
    });
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  _RiskLevel _riskFrom(SocialFeedItem? item) {
    if (item == null) return _RiskLevel.safe;
    final confidence = item.confidence;
    final d = item.distanceKm;
    if (confidence >= 80 && d <= 10) return _RiskLevel.high;
    if (confidence >= 50 && d <= 25) return _RiskLevel.moderate;
    return _RiskLevel.safe;
  }

  Color _riskColor(_RiskLevel level) {
    switch (level) {
      case _RiskLevel.high:
        return const Color(0xFFFF3B30);
      case _RiskLevel.moderate:
        return const Color(0xFFFF9F0A);
      case _RiskLevel.safe:
        return const Color(0xFF34C759);
    }
  }

  String _riskLabel(_RiskLevel level, WidgetRef ref) {
    switch (level) {
      case _RiskLevel.high:
        return tr(ref, 'high');
      case _RiskLevel.moderate:
        return tr(ref, 'moderate');
      case _RiskLevel.safe:
        return tr(ref, 'safe');
    }
  }

  Future<void> _openSosSheet() async {
    HapticFeedback.heavyImpact();

    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return const _SosBottomSheet();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(appLanguageProvider);
    final feed = ref.watch(socialFeedProvider).valueOrNull;
    final clusterNearby =
        feed != null && feed.where((e) => e.distanceKm <= 5).length >= 3;
    final nearest = ref.watch(nearestSocialFeedItemProvider);
    final distanceKm = nearest?.distanceKm;
    final risk = _riskFrom(nearest);
    final riskColor = _riskColor(risk);
    final shouldPulse = risk == _RiskLevel.high;

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
                  Image.asset(
                    BrandingAssets.appLogo,
                    width: 36,
                    height: 36,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      tr(ref, 'app_title'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Semantics(
                    button: true,
                    label: tr(ref, 'nfc_scan_top'),
                    child: PressEffect(
                      borderRadius: BorderRadius.circular(14),
                      child: FilledButton.tonalIcon(
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          visualDensity: VisualDensity.compact,
                          backgroundColor: const Color(0xFF0D9488).withValues(alpha: 0.28),
                          foregroundColor: Colors.white,
                          iconColor: Colors.white,
                        ),
                        onPressed: () => context.push('/nfc'),
                        icon: const Icon(Icons.contactless_rounded, size: 22),
                        label: Text(
                          tr(ref, 'nfc_scan_top'),
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.2,
                              ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const LanguageToggle(),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                children: [
                  GlassCard(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: riskColor.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: riskColor.withValues(alpha: 0.38)),
                          ),
                          child: Icon(Icons.shield_rounded, color: riskColor, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            switch (risk) {
                              _RiskLevel.high => tr(ref, 'status_risk_high'),
                              _RiskLevel.moderate => tr(ref, 'status_risk_moderate'),
                              _RiskLevel.safe => tr(ref, 'status_risk_safe'),
                            },
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  height: 1.35,
                                  color: Colors.white.withValues(alpha: 0.92),
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (clusterNearby) ...[
                    const SizedBox(height: 10),
                    GlassCard(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(Icons.groups_3_rounded, color: Colors.orange.shade200, size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              tr(ref, 'cluster_incidents_nearby'),
                              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white.withValues(alpha: 0.9),
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  _RiskStatusCard(
                    areaRiskLabel: tr(ref, 'area_risk'),
                    riskLabel: _riskLabel(risk, ref),
                    color: riskColor,
                    disasterType: nearest?.type,
                    sentence: nearest == null
                        ? tr(ref, 'no_active_alert_nearby')
                        : _localizedDetectedNearby(lang, nearest.type),
                    distanceLine: distanceKm != null
                        ? '${distanceKm.toStringAsFixed(1)} ${tr(ref, 'distance_km_suffix')}'
                        : null,
                    confirmations: nearest?.confirmations,
                    confirmationsLabel: tr(ref, 'confirmations'),
                    onTap: () => context.push('/map'),
                  ),
                  const SizedBox(height: 14),
                  SectionHeader(title: tr(ref, 'section_emergency')),
                  const SizedBox(height: 8),
                  ScaleTransition(
                    scale: shouldPulse ? _pulse : const AlwaysStoppedAnimation(1.0),
                    child: _SosButton(
                      title: tr(ref, 'sos_title'),
                      subtitle: tr(ref, 'sos_subtitle'),
                      semanticsLabel: tr(ref, 'sos_semantics_label'),
                      onTap: _openSosSheet,
                    ),
                  ),
                  const SizedBox(height: 14),
                  SectionHeader(title: tr(ref, 'section_immediate_actions')),
                  const SizedBox(height: 8),
                  _PrimaryActionGrid(
                    onShelter: () => context.push('/map'),
                    onHealth: () => context.push('/health-ai?mode=type'),
                    onReport: () => context.push('/report'),
                    onAlerts: () => context.push('/alerts'),
                    safeRouteTitle: tr(ref, 'action_safe_route_title'),
                    safeRouteSub: tr(ref, 'action_safe_route_sub'),
                    healthAiTitle: tr(ref, 'action_health_ai_title'),
                    healthAiSub: tr(ref, 'action_health_ai_sub'),
                    reportTitle: tr(ref, 'action_report_title'),
                    reportSub: tr(ref, 'action_report_sub'),
                    alertsTitle: tr(ref, 'action_alerts_title'),
                    alertsSub: tr(ref, 'action_alerts_sub'),
                  ),
                  const SizedBox(height: 12),
                  SectionHeader(title: tr(ref, 'section_live_updates')),
                  const SizedBox(height: 8),
                  _LiveAlertsCard(onTap: () => context.push('/alerts')),
                  const SizedBox(height: 12),
                  _ShelterFinderCard(
                    onViewRoute: () => context.push('/map'),
                  ),
                  const SizedBox(height: 12),
                  _AssistantCard(
                    onSpeak: () => context.push('/health-ai?mode=speak'),
                    onType: () => context.push('/health-ai?mode=type'),
                  ),
                  const SizedBox(height: 12),
                  _ActionCard(
                    icon: Icons.groups_2,
                    title: tr(ref, 'community_title'),
                    subtitle: tr(ref, 'community_subtitle'),
                    onTap: () => context.push('/community'),
                  ),
                  const SizedBox(height: 12),
                  SectionHeader(title: tr(ref, 'section_tools')),
                  const SizedBox(height: 8),
                  _MoreToolsCard(
                    onSmartwatch: () => context.push('/smartwatch'),
                    onOpenAiToolkit: () => context.push('/assistant-lab'),
                    onOpenDetailedReport: () => context.push('/report-form'),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    tr(ref, 'footer_sos_reminder'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.55),
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
}

String _localizedDetectedNearby(AppLanguage lang, String type) {
  final t = type.trim().isEmpty ? '' : type.trim();
  switch (lang) {
    case AppLanguage.hi:
      return t.isEmpty ? 'पास में जोखिम' : '$t पास में';
    case AppLanguage.kn:
      return t.isEmpty ? 'ಹತ್ತಿರ ಅಪಾಯ' : '$t ಹತ್ತಿರ';
    case AppLanguage.en:
      return t.isEmpty ? 'Risk detected nearby' : '${_titleCase(t)} detected nearby';
  }
}

String _titleCase(String s) {
  if (s.isEmpty) return s;
  return s.substring(0, 1).toUpperCase() + s.substring(1).toLowerCase();
}

class _RiskStatusCard extends StatelessWidget {
  const _RiskStatusCard({
    required this.areaRiskLabel,
    required this.riskLabel,
    required this.color,
    required this.sentence,
    required this.onTap,
    this.disasterType,
    this.distanceLine,
    this.confirmations,
    required this.confirmationsLabel,
  });

  final String areaRiskLabel;
  final String riskLabel;
  final Color color;
  final String sentence;
  final String? disasterType;
  /// Pre-formatted, e.g. "2.4 km away" in the current language.
  final String? distanceLine;
  final int? confirmations;
  final String confirmationsLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasIncidentTitle = (disasterType ?? '').trim().isNotEmpty;
    final incidentTitle =
        hasIncidentTitle ? _titleCase(disasterType!.trim()) : null;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: color.withValues(alpha: 0.05),
            border: Border.all(color: color.withValues(alpha: 0.22)),
          ),
          child: Stack(
            children: [
              _CardToneBackground(
                tone: color,
                borderRadius: 18,
                intensity: 0.5,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                areaRiskLabel,
                                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                      color: Colors.white.withValues(alpha: 0.7),
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(color: color.withValues(alpha: 0.42)),
                                ),
                                child: Text(
                                  riskLabel,
                                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.5,
                                        color: color,
                                      ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (hasIncidentTitle) ...[
                            Text(
                              incidentTitle!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.2,
                                  ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              sentence,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    height: 1.35,
                                    color: Colors.white.withValues(alpha: 0.86),
                                  ),
                            ),
                          ] else
                            Text(
                              sentence,
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    height: 1.35,
                                    color: Colors.white.withValues(alpha: 0.94),
                                  ),
                            ),
                          if (distanceLine != null) ...[
                            const SizedBox(height: 10),
                            Text(
                              distanceLine!,
                              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.58),
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ],
                          if (confirmations != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              '${confirmations!} $confirmationsLabel',
                              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.58),
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: color.withValues(alpha: 0.35)),
                      ),
                      child: Icon(Icons.map_rounded, color: color, size: 26),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SosButton extends StatelessWidget {
  const _SosButton({
    required this.title,
    required this.subtitle,
    required this.semanticsLabel,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String semanticsLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticsLabel,
      child: SizedBox(
        width: double.infinity,
        child: PressEffect(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                colors: [
                  const Color(AppConstants.emergencyRed),
                  const Color(AppConstants.emergencyRed).withValues(alpha: 0.85),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(AppConstants.emergencyRed).withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
                    ),
                    child: const Icon(Icons.crisis_alert_rounded, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.35,
                                color: Colors.white,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: Colors.white.withValues(alpha: 0.92),
                                fontWeight: FontWeight.w600,
                                height: 1.28,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: Colors.white.withValues(alpha: 0.95), size: 28),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AssistantCard extends ConsumerWidget {
  const _AssistantCard({
    required this.onSpeak,
    required this.onType,
  });

  final VoidCallback onSpeak;
  final VoidCallback onType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
                ),
                child: const Icon(Icons.medical_services_outlined, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  tr(ref, 'need_help_now'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            tr(ref, 'assistant_symptoms_detail'),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 56,
                  child: FilledButton.tonalIcon(
                    onPressed: onSpeak,
                    icon: const Icon(Icons.mic),
                    label: Text(tr(ref, 'speak')),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 56,
                  child: FilledButton.tonalIcon(
                    onPressed: onType,
                    icon: const Icon(Icons.keyboard),
                    label: Text(tr(ref, 'type')),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => GoRouter.of(context).push('/assistant-lab'),
              icon: const Icon(Icons.tune, size: 18),
              label: Text(
                tr(ref, 'ai_toolkit'),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: InkWell(
        child: PressEffect(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              minVerticalPadding: 14,
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
                ),
                child: Icon(icon, color: Colors.white, size: 26),
              ),
              title: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              subtitle: Text(
                subtitle,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Colors.white.withValues(alpha: 0.68),
                      fontWeight: FontWeight.w600,
                    ),
              ),
              trailing: const Icon(Icons.chevron_right, size: 26),
            ),
          ),
        ),
      ),
    );
  }
}

class _ShelterFinderCard extends ConsumerWidget {
  const _ShelterFinderCard({required this.onViewRoute});
  final VoidCallback onViewRoute;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pos = ref.watch(currentPositionProvider).valueOrNull;
    final nearest = _nearestShelter(pos);

    return GlassCard(
      child: Stack(
        children: [
          const _CardToneBackground(
            tone: Color(0xFF4F46E5),
          ),
          Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
                ),
                child: const Icon(Icons.home_work, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  tr(ref, 'shelter_finder'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            pos == null ? tr(ref, 'shelter_nearest_fallback') : nearest.name,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                pos == null ? tr(ref, 'distance_unknown') : nearest.distanceText,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Colors.white.withValues(alpha: 0.68),
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF34C759),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '${nearest.availableSlots} ${tr(ref, 'shelter_slots_suffix')}',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Colors.white.withValues(alpha: 0.68),
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton.icon(
              onPressed: onViewRoute,
              icon: const Icon(Icons.route),
              label: Text(tr(ref, 'view_safe_route')),
            ),
          ),
        ],
          ),
        ],
      ),
    );
  }
}

class _ShelterUi {
  const _ShelterUi({
    required this.name,
    required this.distanceText,
    required this.availableSlots,
  });

  final String name;
  final String distanceText;
  final int availableSlots;
}

_ShelterUi _nearestShelter(Position? pos) {
  // Lightweight placeholder list (works offline). Can be replaced by API later.
  const shelters = <({String name, double lat, double lng, int slots})>[
    (name: 'Relief Shelter – Govt School', lat: 28.6139, lng: 77.2090, slots: 24),
    (name: 'Community Hall Shelter', lat: 19.0760, lng: 72.8777, slots: 18),
    (name: 'PHC Shelter Point', lat: 12.9716, lng: 77.5946, slots: 12),
  ];

  if (pos == null) {
    return const _ShelterUi(
      name: 'Nearest Shelter',
      distanceText: '--',
      availableSlots: 12,
    );
  }

  final ranked = shelters
      .map((s) {
        final d = GeoMath.haversineKm(
          lat1: pos.latitude,
          lon1: pos.longitude,
          lat2: s.lat,
          lon2: s.lng,
        );
        return (s: s, d: d);
      })
      .toList()
    ..sort((a, b) => a.d.compareTo(b.d));

  final best = ranked.first;
  return _ShelterUi(
    name: best.s.name,
    distanceText: '${best.d.toStringAsFixed(1)} km',
    availableSlots: best.s.slots,
  );
}

class _LiveAlertsCard extends ConsumerWidget {
  const _LiveAlertsCard({required this.onTap});
  final VoidCallback onTap;

  Color _riskColor(double confidence) {
    if (confidence >= 0.8) return const Color(0xFFFF3B30);
    if (confidence >= 0.5) return const Color(0xFFFF9F0A);
    return const Color(0xFF34C759);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(socialFeedProvider).valueOrNull ?? [];
    final pos = ref.watch(currentPositionProvider).valueOrNull;
    final repo = ref.read(emergencyRepositoryProvider);
    final user = ref.watch(currentUserProvider);

    final top = [...items]..sort((a, b) => b.confidence.compareTo(a.confidence));
    final view = top.take(4).toList();

    return GlassCard(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 8, 4),
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4FD1C5).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF4FD1C5).withValues(alpha: 0.28)),
                    ),
                    child: const Icon(Icons.campaign_rounded, color: Color(0xFF4FD1C5), size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr(ref, 'live_alerts'),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.2,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          tr(ref, 'live_feed_subtitle'),
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                color: Colors.white.withValues(alpha: 0.55),
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: Colors.white.withValues(alpha: 0.65), size: 26),
                ],
              ),
              const SizedBox(height: 12),
              if (items.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 4),
                  child: Text(
                    tr(ref, 'no_active_alert_nearby'),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.62),
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                  ),
                )
              else
                SizedBox(
                  height: 168,
                  child: ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    itemCount: view.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final e = view[i];
                      final d = e.distanceKm;
                      final c = _riskColor((e.confidence / 100).clamp(0, 1));
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: c.withValues(alpha: 0.45)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, color: c, size: 22),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '⚠ ${_titleCase(e.type)}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.w800,
                                        ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${tr(ref, 'feed_nearby_label')} • ${d.toStringAsFixed(1)} km • ${e.confirmations}',
                                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                          color: Colors.white.withValues(alpha: 0.65),
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ],
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
                                e.confidence >= 80
                                    ? tr(ref, 'high')
                                    : (e.confidence >= 50 ? tr(ref, 'moderate') : tr(ref, 'safe')),
                                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                      color: c,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.5,
                                    ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              height: 44,
                              child: Semantics(
                                button: true,
                                label: tr(ref, 'confirm_sighting'),
                                child: FilledButton.tonalIcon(
                                onPressed: pos == null
                                    ? null
                                    : () async {
                                        try {
                                          final res = await repo.confirmSocialEvent(
                                            eventId: e.id,
                                            latitude: pos.latitude,
                                            longitude: pos.longitude,
                                            userId: user?.id,
                                          );
                                          if (!context.mounted) return;
                                          final msg = (res['message'] ?? '').toString();
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text(msg.isEmpty ? tr(ref, 'confirm_sighting') : msg)),
                                          );
                                        } catch (err) {
                                          if (!context.mounted) return;
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text(err.toString())),
                                          );
                                        }
                                      },
                                icon: const Icon(Icons.check_circle_outline),
                                label: Text(tr(ref, 'confirm')),
                              ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
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
}

class _SosBottomSheet extends ConsumerStatefulWidget {
  const _SosBottomSheet();

  @override
  ConsumerState<_SosBottomSheet> createState() => _SosBottomSheetState();
}

class _SosBottomSheetState extends ConsumerState<_SosBottomSheet> {
  int _people = 1;
  bool _injured = false;
  bool _sending = false;
  String _sosType = 'medical';
  bool _stealth = false;

  Future<void> _submit() async {
    if (_sending) return;
    setState(() => _sending = true);

    try {
      final lang = ref.read(appLanguageProvider);
      final location = await ref.read(locationServiceProvider).getCurrentPosition();
      final nearest = ref.read(nearestSocialFeedItemProvider);
      final user = ref.read(currentUserProvider);
      final repo = ref.read(emergencyRepositoryProvider);

      final desc =
          'SOS people=$_people;injury=${_injured ? 'yes' : 'no'};event=${nearest?.id ?? 'none'}';
      final ctx = await SosContextCollector.collect(
        position: location,
        appLanguage: lang,
        descriptionSummary: desc,
        peopleCount: _people,
        injured: _injured,
        nearestEventId: nearest?.id,
      );

      final result = await repo.triggerSos(
        latitude: location.latitude,
        longitude: location.longitude,
        userId: user?.id,
        source: 'sos',
        description: desc,
        sosType: _sosType,
        context: ctx,
      );
      ref.read(sosAiGuidanceStoreProvider.notifier).put(result.reportId, result.aiGuidance);

      if (!mounted) return;
      Navigator.of(context).pop();
      final msg = result.queued
          ? switch (lang) {
              AppLanguage.hi => 'ऑफ़लाइन — SOS सहेजा गया; नेटवर्क मिलते ही भेजा जाएगा।',
              AppLanguage.kn => 'ಆಫ್‌ಲೈನ್ — SOS ಉಳಿಸಲಾಗಿದೆ; ನೆಟ್‌ವರ್ಕ್ ಬಂದಾಗ ಕಳುಹಿಸಲಾಗುತ್ತದೆ.',
              AppLanguage.en => 'Offline — SOS saved; will send when you are back online.',
            }
          : switch (lang) {
              AppLanguage.hi => 'SOS भेजा गया। मदद आ रही है।',
              AppLanguage.kn => 'SOS ಕಳುಹಿಸಲಾಗಿದೆ. ಸಹಾಯ ಬರುತ್ತಿದೆ.',
              AppLanguage.en => 'SOS sent. Help is on the way.',
            };
      if (!_stealth || result.queued) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
      context.go('/tracking/${result.reportId}?type=$_sosType');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final lang = ref.watch(appLanguageProvider);

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF0E1320),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: SafeArea(
          top: false,
          child: Column(
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
                '🚨 ${tr(ref, 'sos_title')}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                tr(ref, 'sos_subtitle'),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withValues(alpha: 0.70),
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                switch (lang) {
                  AppLanguage.hi => 'SOS प्रकार',
                  AppLanguage.kn => 'SOS ವಿಧ',
                  AppLanguage.en => 'SOS type',
                },
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Colors.white70,
                    ),
              ),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: [
                  ButtonSegment(
                    value: 'medical',
                    label: Text(switch (lang) {
                      AppLanguage.hi => 'चिकित्सा',
                      AppLanguage.kn => 'ವೈದ್ಯಕೀಯ',
                      AppLanguage.en => 'Medical',
                    }),
                    icon: const Icon(Icons.medical_services_outlined, size: 18),
                  ),
                  ButtonSegment(
                    value: 'disaster',
                    label: Text(switch (lang) {
                      AppLanguage.hi => 'आपदा',
                      AppLanguage.kn => 'ವಿಪತ್ತು',
                      AppLanguage.en => 'Disaster',
                    }),
                    icon: const Icon(Icons.flood_outlined, size: 18),
                  ),
                  ButtonSegment(
                    value: 'safety',
                    label: Text(switch (lang) {
                      AppLanguage.hi => 'सुरक्षा',
                      AppLanguage.kn => 'ಸುರಕ್ಷತೆ',
                      AppLanguage.en => 'Safety',
                    }),
                    icon: const Icon(Icons.health_and_safety_outlined, size: 18),
                  ),
                ],
                selected: {_sosType},
                onSelectionChanged: _sending
                    ? null
                    : (Set<String> s) => setState(() => _sosType = s.first),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  switch (lang) {
                    AppLanguage.hi => 'चुपचाप मोड (कम प्रतिक्रिया)',
                    AppLanguage.kn => 'ನಿಶ್ಶಬ್ದ ಮೋಡ್ (ಕಡಿಮೆ ಪ್ರತಿಕ್ರಿಯೆ)',
                    AppLanguage.en => 'Stealth (minimal feedback)',
                  },
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                subtitle: Text(
                  switch (lang) {
                    AppLanguage.hi => 'कम कंपन और कम सूचनाएँ।',
                    AppLanguage.kn => 'ಕಡಿಮೆ ವೈಬ್ರೇಶನ್ ಮತ್ತು ಸೂಚನೆಗಳು.',
                    AppLanguage.en => 'Less vibration and fewer toasts after send.',
                  },
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Colors.white54,
                      ),
                ),
                value: _stealth,
                onChanged: _sending ? null : (v) => setState(() => _stealth = v),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _CounterCard(
                              label: tr(ref, 'people_count'),
                              value: _people.toString(),
                              onMinus: _people <= 1 || _sending
                                  ? null
                                  : () => setState(() => _people -= 1),
                              onPlus: _people >= 10 || _sending
                                  ? null
                                  : () => setState(() => _people += 1),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _YesNoCard(
                              label: tr(ref, 'injury'),
                              value: _injured,
                              yesLabel: tr(ref, 'yes'),
                              noLabel: tr(ref, 'no'),
                              onChanged: (v) {
                                if (_sending) return;
                                setState(() => _injured = v);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        switch (lang) {
                          AppLanguage.hi => 'भेजने के लिए बटन दबाकर रखें।',
                          AppLanguage.kn => 'ಕಳುಹಿಸಲು ಬಟನ್ ಒತ್ತಿ ಹಿಡಿಯಿರಿ.',
                          AppLanguage.en => 'Hold the button to send (reduces accidents).',
                        },
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: Colors.white70,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 8),
                      SosHoldToSendButton(
                        label: tr(ref, 'send_sos'),
                        enabled: !_sending,
                        stealth: _stealth,
                        onConfirmed: _submit,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: _sending ? null : () => Navigator.of(context).pop(),
                  child: Text(tr(ref, 'cancel')),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                switch (lang) {
                  AppLanguage.hi =>
                    'स्थान, बैटरी और नेटवर्क संदर्भ आपातकालीन अनुरोध के साथ जोड़ा जाएगा।',
                  AppLanguage.kn =>
                    'ಸ್ಥಳ, ಬ್ಯಾಟರಿ ಮತ್ತು ನೆಟ್‌ವರ್ಕ್ ಸಂದರ್ಭ ತುರ್ತು ವಿನಂತಿಯೊಂದಿಗೆ ಸೇರಿಸಲಾಗುತ್ತದೆ.',
                  AppLanguage.en =>
                    'Location, battery, and network context are attached to the SOS request.',
                },
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Colors.white.withValues(alpha: 0.62),
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionsRow extends ConsumerWidget {
  const _QuickActionsRow({required this.onSmartwatch});

  final VoidCallback onSmartwatch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: FilledButton.tonalIcon(
        onPressed: onSmartwatch,
        icon: const Icon(Icons.watch_outlined),
        label: Text(tr(ref, 'smartwatch')),
      ),
    );
  }
}

class _PrimaryActionGrid extends StatelessWidget {
  const _PrimaryActionGrid({
    required this.onShelter,
    required this.onHealth,
    required this.onReport,
    required this.onAlerts,
    required this.safeRouteTitle,
    required this.safeRouteSub,
    required this.healthAiTitle,
    required this.healthAiSub,
    required this.reportTitle,
    required this.reportSub,
    required this.alertsTitle,
    required this.alertsSub,
  });

  final VoidCallback onShelter;
  final VoidCallback onHealth;
  final VoidCallback onReport;
  final VoidCallback onAlerts;
  final String safeRouteTitle;
  final String safeRouteSub;
  final String healthAiTitle;
  final String healthAiSub;
  final String reportTitle;
  final String reportSub;
  final String alertsTitle;
  final String alertsSub;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.12,
      children: [
        _PrimaryActionTile(
          icon: Icons.route,
          title: safeRouteTitle,
          subtitle: safeRouteSub,
          onTap: onShelter,
        ),
        _PrimaryActionTile(
          icon: Icons.health_and_safety,
          title: healthAiTitle,
          subtitle: healthAiSub,
          onTap: onHealth,
        ),
        _PrimaryActionTile(
          icon: Icons.add_a_photo,
          title: reportTitle,
          subtitle: reportSub,
          onTap: onReport,
        ),
        _PrimaryActionTile(
          icon: Icons.notifications_active,
          title: alertsTitle,
          subtitle: alertsSub,
          onTap: onAlerts,
        ),
      ],
    );
  }
}

class _PrimaryActionTile extends StatelessWidget {
  const _PrimaryActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tone = _toneForActionIcon(icon);
    return GlassCard(
      padding: EdgeInsets.zero,
      child: PressEffect(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                tone.withValues(alpha: 0.14),
                const Color(0xFF121D31).withValues(alpha: 0.92),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: tone.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: tone.withValues(alpha: 0.35)),
                  ),
                  child: Icon(icon, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.1,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.72),
                              fontWeight: FontWeight.w600,
                              height: 1.3,
                              fontSize: 12.5,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Color _toneForActionIcon(IconData icon) {
  if (icon == Icons.route) return const Color(0xFF2563EB);
  if (icon == Icons.health_and_safety) return const Color(0xFF0F766E);
  if (icon == Icons.add_a_photo) return const Color(0xFF9333EA);
  if (icon == Icons.notifications_active) return const Color(0xFFB91C1C);
  return const Color(0xFF334155);
}

class _MoreToolsCard extends ConsumerWidget {
  const _MoreToolsCard({
    required this.onSmartwatch,
    required this.onOpenAiToolkit,
    required this.onOpenDetailedReport,
  });

  final VoidCallback onSmartwatch;
  final VoidCallback onOpenAiToolkit;
  final VoidCallback onOpenDetailedReport;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: ExpansionTile(
        collapsedIconColor: Colors.white,
        iconColor: Colors.white,
        title: Text(
          tr(ref, 'more_tools_title'),
          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          tr(ref, 'more_tools_subtitle'),
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.7),
              ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
            child: Column(
              children: [
                _QuickActionsRow(onSmartwatch: onSmartwatch),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonalIcon(
                    onPressed: onOpenDetailedReport,
                    icon: const Icon(Icons.description),
                    label: Text(tr(ref, 'detailed_report')),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonalIcon(
                    onPressed: onOpenAiToolkit,
                    icon: const Icon(Icons.psychology_alt),
                    label: Text(tr(ref, 'ai_toolkit')),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CardToneBackground extends StatelessWidget {
  const _CardToneBackground({
    required this.tone,
    this.borderRadius = 16,
    this.intensity = 1.0,
  });

  final Color tone;
  final double borderRadius;
  /// 1 = full wash; lower = subtler (e.g. 0.5 for dashboard risk card).
  final double intensity;

  @override
  Widget build(BuildContext context) {
    final i = intensity.clamp(0.15, 1.0);
    return Positioned.fill(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    tone.withValues(alpha: 0.28 * i),
                    tone.withValues(alpha: 0.14 * i),
                    Colors.black.withValues(alpha: 0.35 + 0.19 * (1 - i)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CounterCard extends StatelessWidget {
  const _CounterCard({
    required this.label,
    required this.value,
    required this.onMinus,
    required this.onPlus,
  });

  final String label;
  final String value;
  final VoidCallback? onMinus;
  final VoidCallback? onPlus;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white.withValues(alpha: 0.04),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.70),
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _SquareIconButton(
                icon: Icons.remove,
                onPressed: onMinus,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Center(
                  child: Text(
                    value,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _SquareIconButton(
                icon: Icons.add,
                onPressed: onPlus,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _YesNoCard extends StatelessWidget {
  const _YesNoCard({
    required this.label,
    required this.value,
    required this.yesLabel,
    required this.noLabel,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final String yesLabel;
  final String noLabel;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white.withValues(alpha: 0.04),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.70),
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 44,
            width: double.infinity,
            child: SegmentedButton<bool>(
              segments: [
                ButtonSegment(value: false, label: Text(noLabel)),
                ButtonSegment(value: true, label: Text(yesLabel)),
              ],
              selected: {value},
              showSelectedIcon: false,
              onSelectionChanged: (s) => onChanged(s.first),
              style: ButtonStyle(
                padding: WidgetStateProperty.all(
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                ),
                backgroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return Colors.white.withValues(alpha: 0.14);
                  }
                  return Colors.white.withValues(alpha: 0.06);
                }),
                foregroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) return Colors.white;
                  return Colors.white.withValues(alpha: 0.78);
                }),
                side: WidgetStateProperty.all(
                  BorderSide(color: Colors.white.withValues(alpha: 0.10)),
                ),
                shape: WidgetStateProperty.all(
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SquareIconButton extends StatelessWidget {
  const _SquareIconButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}
