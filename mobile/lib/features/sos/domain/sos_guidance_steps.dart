/// Post-SOS safety steps shown in-app (localized headings only where used inline).
List<String> sosStepsForType(String sosType) {
  final t = sosType.toLowerCase();
  if (t == 'disaster') {
    return [
      'Move to higher ground or sturdy shelter if flooding or shaking.',
      'Avoid elevators, glass, and damaged structures.',
      'Keep phone charged; silence non-essential apps to save battery.',
      'Text location to family if voice networks are congested.',
    ];
  }
  if (t == 'safety') {
    return [
      'Move to a visible, open area if safe to do so.',
      'Note landmarks to describe your position to responders.',
      'Stay on the line / keep the app open for live location.',
    ];
  }
  // medical (default)
  return [
    'Stay calm; do not move unnecessarily if spine injury suspected.',
    'If bleeding: apply firm pressure with clean cloth.',
    'If unconscious: check breathing; recovery position only if trained.',
    'Keep airways clear; do not give food or drink if impaired.',
  ];
}
