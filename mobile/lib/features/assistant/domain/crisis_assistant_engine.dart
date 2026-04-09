class StructuredIncident {
  StructuredIncident({
    required this.disasterType,
    required this.severity,
    required this.peopleCount,
    required this.urgentNeeds,
  });

  final String disasterType;
  final String severity;
  final int peopleCount;
  final List<String> urgentNeeds;
}

class CrisisAssistantEngine {
  static const _panicSignals = [
    'help',
    'urgent',
    'trapped',
    'panic',
    'water rising',
    'can\'t breathe',
    'kids',
    'blood',
    'fire',
    'collapse',
  ];

  static const Map<String, Map<String, String>> _translator = {
    'en': {
      'Need rescue now': 'Need rescue now',
      'There are children and elders with me': 'There are children and elders with me',
      'Water level is rising quickly': 'Water level is rising quickly',
      'Send ambulance and rescue boat': 'Send ambulance and rescue boat',
    },
    'hi': {
      'Need rescue now': 'Mujhe abhi bachav ki zarurat hai',
      'There are children and elders with me': 'Mere saath bachche aur buzurg hain',
      'Water level is rising quickly': 'Pani ka star bahut tez badh raha hai',
      'Send ambulance and rescue boat': 'Ambulance aur rescue boat bhejiye',
    },
    'bn': {
      'Need rescue now': 'Amar ekhoni uddhar dorkar',
      'There are children and elders with me': 'Amar sathe shishu o briddho ache',
      'Water level is rising quickly': 'Panir star druto barche',
      'Send ambulance and rescue boat': 'Ambulance ebong rescue boat pathan',
    },
  };

  List<String> panicToAction(String input, {required String lang}) {
    final text = input.toLowerCase();
    final highStress = _panicSignals.any(text.contains);
    final steps = <String>[];

    if (highStress) {
      steps.addAll([
        _localize('Take 3 slow breaths. Focus on one safe action now.', lang),
        _localize('Move everyone to the highest safe point immediately.', lang),
        _localize('Share exact location, people count, and visible injuries.', lang),
        _localize('Keep phone battery low-power and flashlight ready.', lang),
      ]);
    } else {
      steps.addAll([
        _localize('Describe your location and the main hazard in one line.', lang),
        _localize('Confirm number of people and urgent medical needs.', lang),
        _localize('Stay together and keep one communication channel active.', lang),
      ]);
    }
    return steps;
  }

  StructuredIncident structureIncident(String input) {
    final t = input.toLowerCase();
    final disasterType = t.contains('flood') || t.contains('water')
        ? 'flood'
        : t.contains('fire') || t.contains('smoke')
            ? 'fire'
            : t.contains('earthquake') || t.contains('building')
                ? 'collapse'
                : 'multi_hazard';

    final severity = (t.contains('fast') || t.contains('trapped') || t.contains('can\'t breathe'))
        ? 'critical'
        : (t.contains('injury') || t.contains('urgent'))
            ? 'high'
            : 'moderate';

    final peopleCount = _extractPeopleCount(t);
    final urgentNeeds = <String>[];
    if (t.contains('breathe') || t.contains('asthma')) urgentNeeds.add('oxygen/respiratory support');
    if (t.contains('blood') || t.contains('injur')) urgentNeeds.add('medical first aid');
    if (t.contains('kids') || t.contains('child')) urgentNeeds.add('child evacuation support');
    if (t.contains('elder')) urgentNeeds.add('elder mobility support');
    if (t.contains('food') || t.contains('water')) urgentNeeds.add('safe drinking water');
    if (urgentNeeds.isEmpty) urgentNeeds.add('evacuation support');

    return StructuredIncident(
      disasterType: disasterType,
      severity: severity,
      peopleCount: peopleCount,
      urgentNeeds: urgentNeeds,
    );
  }

  int _extractPeopleCount(String t) {
    final m = RegExp(r'\\b(\\d{1,2})\\s*(people|persons|kids|adults)?\\b').firstMatch(t);
    if (m != null) return int.tryParse(m.group(1) ?? '') ?? 1;
    if (t.contains('kids') && t.contains('elder')) return 4;
    return 1;
  }

  String translateLive(String message, {required String toLang}) {
    final target = _translator[toLang] ?? _translator['en']!;
    return target[message] ?? message;
  }

  String simplifyAdvisory(String advisory, {required String lang}) {
    final compact = advisory
        .replaceAll(RegExp(r'\\s+'), ' ')
        .replaceAll('hereby', '')
        .replaceAll('therefore', '')
        .trim();
    return _localize('Plain advisory: $compact', lang);
  }

  List<String> survivalGuidance({
    required String hazard,
    required bool lowArea,
    required bool night,
  }) {
    final steps = <String>[];
    if (hazard == 'flood') {
      steps.add('Do move to upper floors or elevated roads now.');
      steps.add('Do switch off main electricity if water enters home.');
      steps.add('Do not walk or drive through moving water.');
      if (lowArea) steps.add('Low-area alert: evacuate immediately, do not wait for daylight.');
      if (night) steps.add('Use torch and reflective cloth; avoid open drains.');
    } else if (hazard == 'fire') {
      steps.add('Stay low under smoke and cover mouth with damp cloth.');
      steps.add('Use stairs, never use lifts/elevators.');
      steps.add('Close doors behind you to slow fire spread.');
    } else {
      steps.add('Move away from weak structures and broken utilities.');
      steps.add('Check for injuries and stop major bleeding first.');
      steps.add('Send your location and await responder instructions.');
    }
    return steps;
  }

  String rumorVsFact(String forwardText) {
    final t = forwardText.toLowerCase();
    final risky = t.contains('share to 10') ||
        t.contains('secret cure') ||
        t.contains('government hiding') ||
        t.contains('guaranteed');

    if (risky) {
      return 'Likely misinformation. Verify with NDMA, IMD, state disaster authority, or district collector updates before acting.';
    }
    return 'No strong misinformation signals detected, but still verify with official channels before forwarding.';
  }

  List<String> voiceCompanion(String utterance) {
    final t = utterance.toLowerCase();
    if (t.contains('can\'t breathe')) {
      return [
        'Sit upright, loosen tight clothing, take slow breaths.',
        'If inhaler exists, use as prescribed now.',
        'Send immediate medical SOS with location.',
      ];
    }
    if (t.contains('trapped')) {
      return [
        'Conserve battery and send location pin.',
        'Make periodic sound signals every 2-3 minutes.',
        'Avoid heavy movement if structure is unstable.',
      ];
    }
    if (t.contains('no network')) {
      return [
        'Move to open/high point for intermittent signal.',
        'Prepare SMS draft for quick send when signal appears.',
        'Use whistle/flashlight visual signals for nearby responders.',
      ];
    }
    return [
      'State your immediate hazard, injuries, and location.',
      'Keep group together and stay in safest nearby zone.',
    ];
  }

  String familySafetyMessage({
    required String lang,
    required String location,
    required StructuredIncident incident,
  }) {
    final base =
        'I am at $location. Hazard: ${incident.disasterType}. Severity: ${incident.severity}. ${incident.peopleCount} people with me. We need ${incident.urgentNeeds.join(', ')}. I will update every 20 minutes.';
    return translateLive(base, toLang: lang);
  }

  List<String> responderBrief({
    required String location,
    required StructuredIncident incident,
    required List<String> topActions,
  }) {
    return [
      '1) Location: $location',
      '2) Type/Severity: ${incident.disasterType} / ${incident.severity}',
      '3) People: ${incident.peopleCount}',
      '4) Urgent needs: ${incident.urgentNeeds.join(', ')}',
      '5) Citizen actions: ${topActions.take(2).join(' | ')}',
    ];
  }

  List<String> mentalFirstAid({required String lang}) {
    return [
      _localize('Name 5 things you can see right now.', lang),
      _localize('Name 4 things you can touch and feel.', lang),
      _localize('Inhale 4 sec, hold 4 sec, exhale 6 sec for 5 rounds.', lang),
      _localize('Tell yourself: I am taking one safe step at a time.', lang),
    ];
  }

  List<String> recoveryCopilot(String disasterType) {
    final common = [
      'Collect ID proof, address proof, and incident photos/videos.',
      'Keep expense receipts for emergency repair and medicines.',
      'Record FIR/DD entry number if police/fire attended.',
      'Track district compensation portal deadlines.',
    ];

    if (disasterType == 'flood') {
      return [
        ...common,
        'For flood claims: add property damage inventory and water-level photos.',
      ];
    }
    if (disasterType == 'fire') {
      return [
        ...common,
        'For fire claims: include fire department certificate and insurance intimation number.',
      ];
    }
    return common;
  }

  String _localize(String text, String lang) {
    if (lang == 'hi') return '[HI] $text';
    if (lang == 'bn') return '[BN] $text';
    return text;
  }
}
