import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/section_header.dart';
import '../../data/crisis_assistant_api_service.dart';
import '../../domain/crisis_assistant_engine.dart';

class CrisisAssistantScreen extends StatefulWidget {
  const CrisisAssistantScreen({super.key});

  @override
  State<CrisisAssistantScreen> createState() => _CrisisAssistantScreenState();
}

class _CrisisAssistantScreenState extends State<CrisisAssistantScreen> {
  final _engine = CrisisAssistantEngine();
  final _api = CrisisAssistantApiService();
  final _panicInput = TextEditingController();
  final _forwardInput = TextEditingController();
  final _voiceInput = TextEditingController();
  final _advisoryInput = TextEditingController();
  final _locationInput = TextEditingController(text: 'Unknown location');

  String _lang = 'en';
  String _hazard = 'flood';
  bool _lowArea = true;
  bool _night = false;

  StructuredIncident? _incident;
  List<String> _actions = [];
  List<String> _survival = [];
  List<String> _voice = [];
  String _factCheck = '';
  String _plainAdvisory = '';
  String _familyMessage = '';
  List<String> _brief = [];
  List<String> _mentalAid = [];
  List<String> _recovery = [];
  String _translated = '';
  bool _isGenerating = false;

  @override
  void dispose() {
    _panicInput.dispose();
    _forwardInput.dispose();
    _voiceInput.dispose();
    _advisoryInput.dispose();
    _locationInput.dispose();
    super.dispose();
  }

  Future<void> _runAll() async {
    final input = _panicInput.text.trim();
    final incident = _engine.structureIncident(input);
    final actions = _engine.panicToAction(input, lang: _lang);
    final survival = _engine.survivalGuidance(
      hazard: _hazard,
      lowArea: _lowArea,
      night: _night,
    );

    setState(() {
      _isGenerating = true;
    });

    try {
      final ai = await _api.generateAll(
        language: _lang,
        location: _locationInput.text.trim(),
        panicInput: input,
        hazard: _hazard,
        lowArea: _lowArea,
        night: _night,
        forwardedText: _forwardInput.text.trim(),
        voiceText: _voiceInput.text.trim(),
        advisoryText: _advisoryInput.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _incident = StructuredIncident(
          disasterType: (((ai['incident'] as Map?) ?? const {})['disaster_type'] ?? incident.disasterType).toString(),
          severity: (((ai['incident'] as Map?) ?? const {})['severity'] ?? incident.severity).toString(),
          peopleCount: int.tryParse(
                (((ai['incident'] as Map?) ?? const {})['people_count'] ?? incident.peopleCount).toString(),
              ) ??
              incident.peopleCount,
          urgentNeeds: _toStringList((((ai['incident'] as Map?) ?? const {})['urgent_needs'])) ?? incident.urgentNeeds,
        );
        _actions = _toStringList(ai['panic_to_action']) ?? actions;
        _survival = _toStringList(ai['survival_guidance']) ?? survival;
        _factCheck = (ai['rumor_check'] ?? _engine.rumorVsFact(_forwardInput.text.trim())).toString();
        _voice = _toStringList(ai['voice_companion']) ?? _engine.voiceCompanion(_voiceInput.text.trim());
        _plainAdvisory = (ai['plain_advisory'] ?? _engine.simplifyAdvisory(_advisoryInput.text.trim(), lang: _lang))
            .toString();
        _familyMessage = (ai['family_message'] ??
                _engine.familySafetyMessage(
                  lang: _lang,
                  location: _locationInput.text.trim(),
                  incident: incident,
                ))
            .toString();
        _brief = _toStringList(ai['responder_brief']) ??
            _engine.responderBrief(
              location: _locationInput.text.trim(),
              incident: incident,
              topActions: actions,
            );
        _mentalAid = _toStringList(ai['mental_first_aid']) ?? _engine.mentalFirstAid(lang: _lang);
        _recovery = _toStringList(ai['recovery_copilot']) ?? _engine.recoveryCopilot(incident.disasterType);
        _translated = (ai['translated_phrase'] ?? _engine.translateLive('Need rescue now', toLang: _lang)).toString();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _incident = incident;
        _actions = actions;
        _survival = survival;
        _factCheck = _engine.rumorVsFact(_forwardInput.text.trim());
        _voice = _engine.voiceCompanion(_voiceInput.text.trim());
        _plainAdvisory = _engine.simplifyAdvisory(_advisoryInput.text.trim(), lang: _lang);
        _familyMessage = _engine.familySafetyMessage(
          lang: _lang,
          location: _locationInput.text.trim(),
          incident: incident,
        );
        _brief = _engine.responderBrief(
          location: _locationInput.text.trim(),
          incident: incident,
          topActions: actions,
        );
        _mentalAid = _engine.mentalFirstAid(lang: _lang);
        _recovery = _engine.recoveryCopilot(incident.disasterType);
        _translated = _engine.translateLive('Need rescue now', toLang: _lang);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  List<String>? _toStringList(dynamic value) {
    if (value is! List) return null;
    return value.map((e) => e.toString()).where((e) => e.trim().isNotEmpty).toList();
  }

  Widget _bullets(List<String> lines) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final line in lines)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text('- $line'),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Panic-to-Action Assistant')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(title: 'Input'),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: _lang,
                  decoration: const InputDecoration(labelText: 'Language'),
                  items: const [
                    DropdownMenuItem(value: 'en', child: Text('English')),
                    DropdownMenuItem(value: 'hi', child: Text('Hindi')),
                    DropdownMenuItem(value: 'bn', child: Text('Bengali')),
                  ],
                  onChanged: (v) => setState(() => _lang = v ?? 'en'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _locationInput,
                  decoration: const InputDecoration(labelText: 'Current location summary'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _panicInput,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Panic voice/text',
                    hintText: 'water rising fast, kids here, can\'t breathe...',
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _hazard,
                        decoration: const InputDecoration(labelText: 'Hazard type'),
                        items: const [
                          DropdownMenuItem(value: 'flood', child: Text('Flood')),
                          DropdownMenuItem(value: 'fire', child: Text('Fire')),
                          DropdownMenuItem(value: 'collapse', child: Text('Collapse')),
                        ],
                        onChanged: (v) => setState(() => _hazard = v ?? 'flood'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        children: [
                          SwitchListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Low area'),
                            value: _lowArea,
                            onChanged: (v) => setState(() => _lowArea = v),
                          ),
                          SwitchListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Night'),
                            value: _night,
                            onChanged: (v) => setState(() => _night = v),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _isGenerating ? null : _runAll,
                  icon: _isGenerating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.crisis_alert),
                  label: Text(_isGenerating ? 'Generating...' : 'Generate all outputs'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (_incident != null)
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(title: 'Auto Incident Structuring'),
                  const SizedBox(height: 8),
                  Text('Disaster type: ${_incident!.disasterType}'),
                  Text('Severity: ${_incident!.severity}'),
                  Text('People count: ${_incident!.peopleCount}'),
                  Text('Urgent needs: ${_incident!.urgentNeeds.join(', ')}'),
                ],
              ),
            ),
          const SizedBox(height: 12),
          if (_actions.isNotEmpty)
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(title: 'Panic-to-Action'),
                  const SizedBox(height: 8),
                  _bullets(_actions),
                ],
              ),
            ),
          const SizedBox(height: 12),
          if (_translated.isNotEmpty || _plainAdvisory.isNotEmpty)
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(title: 'Multilingual Live Translator'),
                  const SizedBox(height: 8),
                  Text('Rescue phrase: $_translated'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _advisoryInput,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Official advisory text',
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(_plainAdvisory),
                ],
              ),
            ),
          const SizedBox(height: 12),
          if (_survival.isNotEmpty)
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(title: 'Personalized Survival Guidance'),
                  const SizedBox(height: 8),
                  _bullets(_survival),
                ],
              ),
            ),
          const SizedBox(height: 12),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(title: 'Rumor vs Fact Checker'),
                const SizedBox(height: 8),
                TextField(
                  controller: _forwardInput,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Paste forwarded message',
                  ),
                  onChanged: (_) => setState(() {
                    _factCheck = _engine.rumorVsFact(_forwardInput.text.trim());
                  }),
                ),
                const SizedBox(height: 8),
                Text(_factCheck),
              ],
            ),
          ),
          const SizedBox(height: 12),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(title: 'Voice Companion Mode'),
                const SizedBox(height: 8),
                TextField(
                  controller: _voiceInput,
                  decoration: const InputDecoration(labelText: 'Voice transcript'),
                  onChanged: (_) => setState(() {
                    _voice = _engine.voiceCompanion(_voiceInput.text.trim());
                  }),
                ),
                const SizedBox(height: 8),
                _bullets(_voice),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (_familyMessage.isNotEmpty)
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(title: 'Family Safety Message Generator'),
                  const SizedBox(height: 8),
                  Text(_familyMessage),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _familyMessage));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Family message copied.')),
                      );
                    },
                    icon: const Icon(Icons.copy),
                    label: const Text('Copy message'),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          if (_brief.isNotEmpty)
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(title: 'Responder Handover Brief'),
                  const SizedBox(height: 8),
                  _bullets(_brief),
                ],
              ),
            ),
          const SizedBox(height: 12),
          if (_mentalAid.isNotEmpty)
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(title: 'Mental First Aid Micro-Coach'),
                  const SizedBox(height: 8),
                  _bullets(_mentalAid),
                ],
              ),
            ),
          const SizedBox(height: 12),
          if (_recovery.isNotEmpty)
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(title: 'Post-Disaster Recovery Copilot'),
                  const SizedBox(height: 8),
                  _bullets(_recovery),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
