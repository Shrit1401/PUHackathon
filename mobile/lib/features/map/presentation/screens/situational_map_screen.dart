import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/theme/motion_tokens.dart';
import '../../../../core/widgets/glass_card.dart';
import '../providers/map_providers.dart';

class SituationalMapScreen extends ConsumerWidget {
  const SituationalMapScreen({super.key});

  Color _riskColor(double risk) {
    if (risk >= 0.8) return const Color(0xFFFF3B30);
    if (risk >= 0.5) return const Color(0xFFFF9F0A);
    return const Color(0xFF34C759);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final center = ref.watch(mapCenterProvider);
    final riskPoints = ref.watch(gridRiskProvider).valueOrNull ?? [];
    final events = ref.watch(hotspotEventsProvider);
    final reports = ref.watch(reportsFeedProvider).valueOrNull ?? [];

    final circles = riskPoints
        .map(
          (point) => CircleMarker(
            point: LatLng(point.gridLat, point.gridLng),
            radius: 20 + (point.riskScore.clamp(0, 1) * 45),
            color: _riskColor(point.riskScore)
                .withValues(alpha: 0.14 + (point.riskScore * 0.25)),
            borderColor: _riskColor(point.riskScore).withValues(alpha: 0.55),
            borderStrokeWidth: 1.2,
          ),
        )
        .toList();

    final markers = <Marker>[
      ...events.map(
        (event) => Marker(
          point: LatLng(event.latitude, event.longitude),
          width: 40,
          height: 40,
          child: Tooltip(
            message: '${event.type} ${(event.confidenceScore * 100).toStringAsFixed(0)}%',
            child: const Icon(Icons.warning_amber_rounded,
                color: Color(0xFFFF3B30), size: 28),
          ),
        ),
      ),
      ...reports.take(100).map(
            (report) => Marker(
              point: LatLng(report.latitude, report.longitude),
              width: 30,
              height: 30,
              child: const Icon(Icons.person_pin_circle,
                  color: Color(0xFF0A84FF), size: 24),
            ),
          ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Situational Map')),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: center,
              initialZoom: 12,
              minZoom: 4,
              maxZoom: 18,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.resqnet.app',
              ),
              CircleLayer(circles: circles),
              MarkerLayer(markers: markers),
            ],
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: GlassCard(
              child: Row(
                children: [
                  _Legend(color: const Color(0xFFFF3B30), label: 'High Risk'),
                  const SizedBox(width: 12),
                  _Legend(color: const Color(0xFFFF9F0A), label: 'Medium'),
                  const SizedBox(width: 12),
                  _Legend(color: const Color(0xFF34C759), label: 'Low'),
                  const Spacer(),
                  AnimatedSwitcher(
                    duration: MotionTokens.duration(context, MotionTokens.fast),
                    child: Text(
                      key: ValueKey(reports.length),
                      '${reports.length} reports',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 5),
        Text(label, style: Theme.of(context).textTheme.labelMedium),
      ],
    );
  }
}
