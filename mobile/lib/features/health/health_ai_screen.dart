import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/motion_tokens.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/press_effect.dart';
import 'health_provider.dart';

class HealthAIScreen extends ConsumerStatefulWidget {
  const HealthAIScreen({super.key, this.initialMode = 'type'});

  final String initialMode;

  @override
  ConsumerState<HealthAIScreen> createState() => _HealthAIScreenState();
}

class _HealthAIScreenState extends ConsumerState<HealthAIScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialMode == 'speak') {
      _controller.text = 'Dizziness, chest discomfort and shortness of breath';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(healthProvider);
    final advice = state.valueOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Health AI')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Need medical guidance?',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _controller,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: widget.initialMode == 'speak'
                        ? 'Voice input (simulated)'
                        : 'Describe symptoms',
                  ),
                ),
                const SizedBox(height: 12),
                PressEffect(
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: state.isLoading
                          ? null
                          : () async {
                              final text = _controller.text.trim();
                              if (text.isEmpty) return;
                              await ref.read(healthProvider.notifier).analyze(text);
                            },
                      child: state.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Analyze'),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (advice != null) ...[
            const SizedBox(height: 12),
            AnimatedSwitcher(
              duration: MotionTokens.duration(context, MotionTokens.standard),
              switchInCurve: MotionTokens.easeOut,
              switchOutCurve: MotionTokens.easeInOut,
              child: GlassCard(
                key: ValueKey('${advice.severity}_${advice.steps.length}_${advice.medicines.length}'),
                child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Severity',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Colors.white70,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: advice.isCritical
                          ? const Color(0xFFFF3B30).withValues(alpha: 0.14)
                          : Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: advice.isCritical
                            ? const Color(0xFFFF3B30)
                            : Colors.white.withValues(alpha: 0.16),
                      ),
                    ),
                    child: Text(
                      advice.severity,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: advice.isCritical ? const Color(0xFFFF6B6B) : null,
                          ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Steps',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Colors.white70,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 8),
                  ...advice.steps.map((step) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text('• $step'),
                      )),
                  const SizedBox(height: 10),
                  Text(
                    'Medicines',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Colors.white70,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 8),
                  ...advice.medicines.map((m) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text('• $m'),
                      )),
                ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
