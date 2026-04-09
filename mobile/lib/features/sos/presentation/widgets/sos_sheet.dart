import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../models/disaster_event.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';
import 'sos_controller.dart';

Future<void> showSosSheet(BuildContext context, WidgetRef ref) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF121212),
    builder: (_) => const _SosSheetBody(),
  );
}

class _SosSheetBody extends ConsumerStatefulWidget {
  const _SosSheetBody();

  @override
  ConsumerState<_SosSheetBody> createState() => _SosSheetBodyState();
}

class _SosSheetBodyState extends ConsumerState<_SosSheetBody> {
  final _formKey = GlobalKey<FormState>();
  final _people = TextEditingController(text: '1');
  String _injuryStatus = 'none';

  @override
  void dispose() {
    _people.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final events = ref.watch(disasterEventsProvider).valueOrNull ?? [];
    final selected = events.isNotEmpty ? events.first : null;
    final state = ref.watch(sosControllerProvider);

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Send SOS',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 14),
            _DisasterTypeField(event: selected),
            const SizedBox(height: 10),
            TextFormField(
              controller: _people,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'People count'),
              validator: (v) {
                final value = int.tryParse(v ?? '');
                if (value == null || value < 1) return 'Enter valid people count';
                return null;
              },
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: _injuryStatus,
              decoration: const InputDecoration(labelText: 'Injury status'),
              items: const [
                DropdownMenuItem(value: 'none', child: Text('No injuries')),
                DropdownMenuItem(value: 'minor', child: Text('Minor injuries')),
                DropdownMenuItem(value: 'critical', child: Text('Critical injuries')),
              ],
              onChanged: (value) => setState(() => _injuryStatus = value ?? 'none'),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: state.isLoading || selected == null
                    ? null
                    : () async {
                        if (!_formKey.currentState!.validate()) return;
                        try {
                          final report = await ref
                              .read(sosControllerProvider.notifier)
                              .submitSos(
                                disasterId: selected.id,
                                peopleCount: int.parse(_people.text),
                                injuryStatus: _injuryStatus,
                              );
                          if (!context.mounted) return;
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Case ID: ${report.id}')),
                          );
                          context.go('/tracking/${report.id}');
                        } catch (error) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(error.toString())),
                          );
                        }
                      },
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: state.isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Confirm SOS'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DisasterTypeField extends StatelessWidget {
  const _DisasterTypeField({required this.event});

  final DisasterEvent? event;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: const InputDecoration(labelText: 'Detected disaster type'),
      child: Text(event?.type.toUpperCase() ?? 'No active disaster event'),
    );
  }
}
