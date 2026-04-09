import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/press_effect.dart';
import '../../services/emergency_repository.dart';
import '../../services/location_service.dart';
import '../auth/presentation/providers/auth_controller.dart';
import '../tracking/presentation/providers/tracking_providers.dart';

class SmartwatchScreen extends ConsumerStatefulWidget {
  const SmartwatchScreen({super.key});

  @override
  ConsumerState<SmartwatchScreen> createState() => _SmartwatchScreenState();
}

class _SmartwatchScreenState extends ConsumerState<SmartwatchScreen> {
  bool _sending = false;

  Future<void> _triggerEmergency() async {
    if (_sending) return;
    setState(() => _sending = true);
    try {
      final location = await ref.read(locationServiceProvider).getCurrentPosition();
      final user = ref.read(currentUserProvider);
      final result = await ref.read(emergencyRepositoryProvider).triggerSos(
            latitude: location.latitude,
            longitude: location.longitude,
            userId: user?.id,
            source: 'smartwatch_simulation',
            description: 'Simulated fall detection from smartwatch',
          );
      ref.read(sosAiGuidanceStoreProvider.notifier).put(result.reportId, result.aiGuidance);
      if (!mounted) return;
      context.go('/tracking/${result.reportId}');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Smartwatch')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Simulate Fall Detection',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: PressEffect(
                borderRadius: BorderRadius.circular(14),
                child: FilledButton(
                  onPressed: _sending ? null : _triggerEmergency,
                  child: _sending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Trigger Emergency'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
