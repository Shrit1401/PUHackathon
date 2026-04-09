import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../dashboard/presentation/providers/dashboard_providers.dart';
import '../providers/report_controller.dart';

class ReportIncidentScreen extends ConsumerStatefulWidget {
  const ReportIncidentScreen({super.key});

  @override
  ConsumerState<ReportIncidentScreen> createState() => _ReportIncidentScreenState();
}

class _ReportIncidentScreenState extends ConsumerState<ReportIncidentScreen> {
  final _description = TextEditingController();
  String _category = 'citizen_report';
  String? _eventId;

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_description.text.trim().length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add more detail (min 8 chars).')),
      );
      return;
    }

    try {
      final report = await ref.read(reportControllerProvider.notifier).submit(
            category: _category,
            description: _description.text.trim(),
            eventId: _eventId,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Report submitted: ${report.id.substring(0, 8)}')),
      );
      _description.clear();
      setState(() => _eventId = null);
    } catch (err) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reportControllerProvider);
    final events = ref.watch(disasterEventsProvider).valueOrNull ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text('Report Incident')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Community intelligence report',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _category,
            decoration: const InputDecoration(labelText: 'Category'),
            items: const [
              DropdownMenuItem(value: 'citizen_report', child: Text('General report')),
              DropdownMenuItem(value: 'fire_report', child: Text('Fire sighting')),
              DropdownMenuItem(value: 'flood_report', child: Text('Flood sighting')),
              DropdownMenuItem(value: 'medical_report', child: Text('Medical emergency')),
            ],
            onChanged: (value) => setState(() => _category = value ?? _category),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String?>(
            initialValue: _eventId,
            decoration: const InputDecoration(labelText: 'Link to disaster event (optional)'),
            items: [
              const DropdownMenuItem<String?>(value: null, child: Text('None')),
              ...events.map(
                (event) => DropdownMenuItem<String?>(
                  value: event.id,
                  child: Text('${event.type.toUpperCase()} ${event.id.substring(0, 6)}'),
                ),
              ),
            ],
            onChanged: (value) => setState(() => _eventId = value),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _description,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'What do you see?',
              hintText: 'Road blocked, water level rising, people trapped, etc.',
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: state.isLoading ? null : _submit,
            icon: const Icon(Icons.send),
            label: state.isLoading
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Submit Report with GPS'),
          ),
        ],
      ),
    );
  }
}
