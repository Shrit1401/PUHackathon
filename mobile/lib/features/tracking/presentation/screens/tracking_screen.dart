import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/theme/motion_tokens.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../services/emergency_repository.dart';
import '../../../sos/domain/sos_guidance_steps.dart';
import '../providers/tracking_providers.dart';

class TrackingScreen extends ConsumerWidget {
  const TrackingScreen({
    super.key,
    required this.reportId,
    this.sosType,
  });

  final String reportId;
  final String? sosType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final report = ref.watch(trackedReportProvider(reportId));
    final unit = ref.watch(trackedUnitProvider(reportId));
    final eta = ref.watch(etaMinutesProvider(reportId));
    final aiGuidance = ref.watch(sosAiGuidanceProvider(reportId));
    final effectiveType = sosType ?? 'medical';

    if (report == null) {
      return const Scaffold(
        body: Center(child: Text('No active case found for this ID.')),
      );
    }

    final userPoint = LatLng(report.latitude, report.longitude);
    final unitPoint = unit == null
        ? LatLng(report.latitude, report.longitude)
        : LatLng(unit.latitude, unit.longitude);

    final markers = <Marker>{
      Marker(
        markerId: const MarkerId('user'),
        position: userPoint,
        infoWindow: const InfoWindow(title: 'Your Location'),
      ),
      if (unit != null)
        Marker(
          markerId: const MarkerId('unit'),
          position: unitPoint,
          infoWindow: InfoWindow(title: unit.name),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        ),
    };

    final polyline = Polyline(
      polylineId: const PolylineId('route'),
      points: [userPoint, unitPoint],
      width: 5,
      color: Theme.of(context).colorScheme.primary,
    );

    final steps = _buildTimelineSteps(report.status, unit != null);
    final guidance = sosStepsForType(effectiveType);

    return Scaffold(
      appBar: AppBar(title: Text('Live Tracking — ${report.id.length > 8 ? report.id.substring(0, 8) : report.id}')),
      body: Column(
        children: [
          Expanded(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(target: userPoint, zoom: 13),
              markers: markers,
              polylines: {polyline},
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonalIcon(
                    onPressed: () => context.push('/map'),
                    icon: const Icon(Icons.alt_route),
                    label: const Text('Safe corridor — open area map'),
                  ),
                ),
                const SizedBox(height: 10),
                _TrackingInfoPanel(
                  reportStatus: report.status,
                  unitName: unit?.name,
                  eta: eta,
                  aiGuidance: aiGuidance,
                  timeline: steps,
                  queuedOffline: report.status == 'queued_offline',
                ),
                const SizedBox(height: 10),
                GlassCard(
                  child: Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      title: Text(
                        'While you wait — quick steps',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      children: [
                        const SizedBox(height: 6),
                        ...guidance.map(
                          (line) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('• ', style: TextStyle(color: Colors.white70)),
                                Expanded(
                                  child: Text(
                                    line,
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.35),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
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

List<_TimelineStep> _buildTimelineSteps(String status, bool hasUnit) {
  final s = status.toLowerCase();
  final assigned = hasUnit || s == 'assigned' || s.contains('assign');
  final resolved = s == 'resolved' || s == 'closed';
  return [
    _TimelineStep('Received', true),
    _TimelineStep('Assigned', assigned),
    _TimelineStep('Responder en route', assigned),
    _TimelineStep('On scene / resolved', resolved),
  ];
}

class _TimelineStep {
  _TimelineStep(this.label, this.done);
  final String label;
  final bool done;
}

class _TrackingInfoPanel extends StatelessWidget {
  const _TrackingInfoPanel({
    required this.reportStatus,
    required this.unitName,
    required this.eta,
    required this.aiGuidance,
    required this.timeline,
    required this.queuedOffline,
  });

  final String reportStatus;
  final String? unitName;
  final int? eta;
  final SosAiGuidance? aiGuidance;
  final List<_TimelineStep> timeline;
  final bool queuedOffline;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (queuedOffline)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    'Pending network — your SOS is saved and will send automatically.',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Colors.orange.shade200,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
              Text('Dispatch timeline', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              ...timeline.map(
                (t) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Icon(
                        t.done ? Icons.check_circle : Icons.radio_button_unchecked,
                        size: 18,
                        color: t.done ? Colors.greenAccent : Colors.white38,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          t.label,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: t.done ? Colors.white : Colors.white54,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 20),
              Text('Case Status: ${reportStatus.toUpperCase()}'),
              const SizedBox(height: 6),
              Text('Assigned Unit: ${unitName ?? (queuedOffline ? 'Waiting for network' : 'Allocating...')}'),
              const SizedBox(height: 6),
              Text('ETA: ${eta == null ? '--' : '$eta min'}'),
            ],
          ),
        ),
        AnimatedSwitcher(
          duration: MotionTokens.duration(context, MotionTokens.fast),
          switchInCurve: MotionTokens.easeOut,
          child: aiGuidance == null
              ? const SizedBox.shrink()
              : Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: GlassCard(
                    key: ValueKey('${aiGuidance!.priority}_${aiGuidance!.instructions}'),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI Guidance',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text('Priority: ${aiGuidance!.priority}'),
                        const SizedBox(height: 4),
                        Text(
                          aiGuidance!.instructions.isEmpty
                              ? 'Follow official emergency updates and stay reachable.'
                              : aiGuidance!.instructions,
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}
