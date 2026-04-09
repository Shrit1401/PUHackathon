import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/motion_tokens.dart';
import '../../../../core/utils/geo_math.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';
import '../../../map/presentation/providers/map_providers.dart';

class AlertsFeedScreen extends ConsumerStatefulWidget {
  const AlertsFeedScreen({super.key});

  @override
  ConsumerState<AlertsFeedScreen> createState() => _AlertsFeedScreenState();
}

class _AlertsFeedScreenState extends ConsumerState<AlertsFeedScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Color _riskColor(double confidence) {
    if (confidence >= 0.8) return const Color(0xFFFF3B30);
    if (confidence >= 0.5) return const Color(0xFFFF9F0A);
    return const Color(0xFF34C759);
  }

  @override
  Widget build(BuildContext context) {
    final events = ref.watch(disasterEventsProvider);
    final reports = ref.watch(reportsFeedProvider);
    final pos = ref.watch(currentPositionProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Intelligence Feed'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Disaster Alerts'),
            Tab(text: 'Citizen Reports'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          events.when(
            data: (items) => ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final event = items[index];
                final distance = pos == null
                    ? null
                    : GeoMath.haversineKm(
                        lat1: pos.latitude,
                        lon1: pos.longitude,
                        lat2: event.latitude,
                        lon2: event.longitude,
                      );

                return AnimatedContainer(
                  duration: MotionTokens.duration(context, MotionTokens.fast),
                  curve: MotionTokens.easeOut,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: Colors.white.withValues(alpha: 0.04),
                    border: Border.all(
                      color: _riskColor(event.confidenceScore).withValues(alpha: 0.5),
                    ),
                  ),
                  child: ListTile(
                    title: Text(event.type.toUpperCase()),
                    subtitle: Text(
                      'Confidence ${(event.confidenceScore * 100).toStringAsFixed(0)}%'
                      '${distance == null ? '' : ' • ${distance.toStringAsFixed(1)} km'}',
                    ),
                    trailing: Icon(Icons.warning_amber_rounded,
                        color: _riskColor(event.confidenceScore)),
                  ),
                );
              },
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
          reports.when(
            data: (items) => ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final report = items[index];
                final time = DateFormat('MMM d, HH:mm').format(report.createdAt.toLocal());
                return AnimatedContainer(
                  duration: MotionTokens.duration(context, MotionTokens.fast),
                  curve: MotionTokens.easeOut,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: Colors.white.withValues(alpha: 0.04),
                    border:
                        Border.all(color: const Color(0xFF0A84FF).withValues(alpha: 0.4)),
                  ),
                  child: ListTile(
                    title: Text(report.source.replaceAll('_', ' ').toUpperCase()),
                    subtitle: Text('${report.description}\n$time'),
                    isThreeLine: true,
                    trailing: const Icon(Icons.person_pin_circle,
                        color: Color(0xFF0A84FF)),
                  ),
                );
              },
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
        ],
      ),
    );
  }
}
