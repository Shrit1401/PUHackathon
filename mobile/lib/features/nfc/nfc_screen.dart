import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/nfc_manager_android.dart';
import 'package:nfc_manager/nfc_manager_ios.dart';
import 'package:nfc_manager/ndef_record.dart';

import '../../core/constants/app_constants.dart';
import '../../core/localization/app_language.dart';
import '../../core/network/supabase_provider.dart';
import '../../core/theme/motion_tokens.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/press_effect.dart';
import '../../services/location_service.dart';
import '../../services/nfc_service.dart';
import '../../services/resqnet_backend_api.dart';
import '../sos/data/nfc_linkage_store.dart';
import '../sos/data/sos_context_collector.dart';

final nfcProvider = FutureProvider.family<NfcProfile, String>((ref, userId) async {
  return ref.read(nfcServiceProvider).fetchProfile(userId);
});

/// Accent used only on this screen for NFC / medical cues (cyan on navy reads “clinical + tech”).
const _nfcAccent = Color(0xFF4FD1C5);
const _nfcAccentDim = Color(0xFF2D8A7F);
const _warnAmber = Color(0xFFFFB84D);

class NFCScanScreen extends ConsumerStatefulWidget {
  const NFCScanScreen({super.key});

  @override
  ConsumerState<NFCScanScreen> createState() => _NFCScanScreenState();
}

class _NFCScanScreenState extends ConsumerState<NFCScanScreen>
    with SingleTickerProviderStateMixin {
  bool _isScanning = false;
  String? _scannedUserId;
  Map<String, dynamic>? _cardExtras;
  String? _errorMessage;
  Map<String, dynamic>? _readerContext;
  Object? _readerContextError;

  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _pulse = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    NfcManager.instance.stopSession().catchError((_) {});
    super.dispose();
  }

  void _setPulse(bool scanning) {
    final reduce = MotionTokens.reduceMotion(context);
    if (reduce) return;
    if (scanning) {
      _pulseCtrl.repeat(reverse: true);
    } else {
      _pulseCtrl.stop();
      _pulseCtrl.reset();
    }
  }

  Future<void> _startScan() async {
    setState(() {
      _isScanning = true;
      _scannedUserId = null;
      _cardExtras = null;
      _errorMessage = null;
      _readerContext = null;
      _readerContextError = null;
    });
    _setPulse(true);

    final availability = await NfcManager.instance.checkAvailability();
    if (availability != NfcAvailability.enabled) {
      if (!mounted) return;
      setState(() {
        _isScanning = false;
        _errorMessage = 'NFC is not enabled on this device.';
      });
      _setPulse(false);
      return;
    }

    await NfcManager.instance.startSession(
      pollingOptions: {
        NfcPollingOption.iso14443,
        NfcPollingOption.iso15693,
        NfcPollingOption.iso18092,
      },
      onDiscovered: (tag) async {
        try {
          final parsed = _parseCard(tag);
          if (parsed == null || parsed.$1.isEmpty) {
            throw const FormatException('No user_id found on card.');
          }
          await NfcManager.instance.stopSession();
          if (!mounted) return;
          setState(() {
            _scannedUserId = parsed.$1;
            _cardExtras = parsed.$2;
            _isScanning = false;
            _errorMessage = null;
          });
          _setPulse(false);
          final prefs = await SharedPreferences.getInstance();
          await NfcLinkageStore.recordLink(prefs, parsed.$1);
          if (!mounted) return;
          unawaited(_ingestScan(parsed.$1, parsed.$2));
        } catch (_) {
          await NfcManager.instance.stopSession(
            errorMessageIos: 'Card format invalid. Write a user_id to this card.',
          );
          if (!mounted) return;
          setState(() {
            _isScanning = false;
            _errorMessage = 'Invalid NFC card. Missing user_id.';
          });
          _setPulse(false);
        }
      },
    );
  }

  (String, Map<String, dynamic>?)? _parseCard(NfcTag tag) {
    final message = _readNdefMessage(tag);
    if (message == null || message.records.isEmpty) return null;

    for (final record in message.records) {
      final decoded = _decodeRecordPayload(record);
      final parsed = _tryParseCardString(decoded);
      if (parsed != null) return parsed;
    }
    return null;
  }

  (String, Map<String, dynamic>?)? _tryParseCardString(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is Map<String, dynamic>) {
        final id = (decoded['user_id'] ?? '').toString().trim();
        if (id.isNotEmpty) return (id, decoded);
      }
    } catch (_) {}

    final uri = Uri.tryParse(trimmed);
    if (uri != null) {
      final fromQuery = uri.queryParameters['user_id']?.trim();
      if (fromQuery != null && fromQuery.isNotEmpty) return (fromQuery, null);
      final segments = uri.pathSegments.where((e) => e.trim().isNotEmpty).toList();
      if (segments.isNotEmpty) return (segments.last.trim(), null);
    }

    if (trimmed.contains('user_id=')) {
      final match = RegExp(r'user_id=([^&\s]+)').firstMatch(trimmed);
      if (match != null) {
        final id = match.group(1)?.trim();
        if (id != null && id.isNotEmpty) return (id, null);
      }
    }

    return (trimmed, null);
  }

  NdefMessage? _readNdefMessage(NfcTag tag) {
    final androidNdef = NdefAndroid.from(tag);
    if (androidNdef?.cachedNdefMessage != null) {
      return androidNdef!.cachedNdefMessage;
    }
    final iosNdef = NdefIos.from(tag);
    if (iosNdef?.cachedNdefMessage != null) {
      return iosNdef!.cachedNdefMessage;
    }
    return null;
  }

  String? _decodeRecordPayload(NdefRecord record) {
    final payload = record.payload;
    if (payload.isEmpty) return null;

    final type = ascii.decode(record.type, allowInvalid: true);
    if (type == 'T') {
      final langCodeLength = payload.first & 0x3F;
      if (payload.length <= 1 + langCodeLength) return null;
      return utf8.decode(payload.sublist(1 + langCodeLength), allowMalformed: true);
    }

    if (type == 'U') {
      if (payload.length < 2) return null;
      const prefixes = <String>[
        '',
        'http://www.',
        'https://www.',
        'http://',
        'https://',
      ];
      final prefixCode = payload.first;
      final prefix = prefixCode < prefixes.length ? prefixes[prefixCode] : '';
      final uriPart = utf8.decode(payload.sublist(1), allowMalformed: true);
      return '$prefix$uriPart';
    }

    return utf8.decode(payload, allowMalformed: true);
  }

  Map<String, dynamic> _profileSnapshotMap(NfcProfile p) {
    return {
      'name': p.name,
      'blood_group': p.bloodGroup,
      'allergies': p.allergies,
      'emergency_contact': p.emergencyContact,
      if (p.age != null) 'age': p.age,
      if (p.healthSummary != null && p.healthSummary!.trim().isNotEmpty)
        'health_summary': p.healthSummary,
    };
  }

  Future<void> _insertNfcScanToSupabase({
    required String cardUserId,
    Map<String, dynamic>? tagPayload,
    Map<String, dynamic>? readerContext,
    Object? readerErr,
    Map<String, dynamic>? profileSnapshot,
    String? profileFetchErr,
  }) async {
    DateTime? clientReported;
    final ts = readerContext?['client_ts'];
    if (ts is String) {
      clientReported = DateTime.tryParse(ts);
    }

    final row = <String, dynamic>{
      'card_user_id': cardUserId,
      if (tagPayload != null && tagPayload.isNotEmpty) 'tag_payload': tagPayload,
      if (readerContext != null && readerContext.isNotEmpty) 'reader_context': readerContext,
      if (readerErr != null) 'reader_context_error': readerErr.toString(),
      if (profileSnapshot != null && profileSnapshot.isNotEmpty) 'profile_snapshot': profileSnapshot,
      if (profileFetchErr != null && profileFetchErr.isNotEmpty) 'profile_fetch_error': profileFetchErr,
      if (clientReported != null) 'client_reported_at': clientReported.toUtc().toIso8601String(),
    };

    await ref.read(supabaseClientProvider).from('nfc_card_scans').insert(row);
  }

  /// Collects reader context for the UI, loads profile for merge, then persists the scan (API or Supabase).
  Future<void> _ingestScan(String cardUserId, Map<String, dynamic>? cardExtras) async {
    if (!mounted) return;
    setState(() {
      _readerContext = null;
      _readerContextError = null;
    });

    Map<String, dynamic>? readerContext;
    Object? readerErr;
    try {
      final pos = await ref.read(locationServiceProvider).getCurrentPosition();
      final lang = ref.read(appLanguageProvider);
      readerContext = await SosContextCollector.collectForNfcCardScan(
        position: pos,
        appLanguage: lang,
      );
      readerErr = null;
      if (mounted) {
        setState(() {
          _readerContext = readerContext;
          _readerContextError = null;
        });
      }
    } catch (e) {
      readerErr = e;
      if (mounted) {
        setState(() {
          _readerContext = null;
          _readerContextError = e;
        });
      }
    }

    NfcProfile? profile;
    String? profileFetchErr;
    try {
      profile = await ref.read(nfcServiceProvider).fetchProfile(cardUserId);
    } catch (e) {
      profileFetchErr = e.toString();
    }

    final merged = profile != null ? NfcProfile.mergeWithCard(profile, cardExtras) : null;
    final profileSnapshot = merged != null ? _profileSnapshotMap(merged) : null;

    try {
      if (AppConstants.nfcScansSupabaseInsert) {
        await _insertNfcScanToSupabase(
          cardUserId: cardUserId,
          tagPayload: cardExtras,
          readerContext: readerContext,
          readerErr: readerErr,
          profileSnapshot: profileSnapshot,
          profileFetchErr: profileFetchErr,
        );
      } else {
        await ref.read(resqnetBackendApiProvider).postNfcCardScan(
              cardUserId: cardUserId,
              tagPayload: cardExtras,
              readerContext: readerContext,
              readerContextError: readerErr?.toString(),
              profileSnapshot: profileSnapshot,
              profileFetchError: profileFetchErr,
            );
      }
    } catch (e) {
      debugPrint('NFC scan ingest failed: $e');
    }
  }

  static const _readerContextKeyOrder = <String>[
    'client_ts',
    'reader_latitude',
    'reader_longitude',
    'location_accuracy_m',
    'altitude_m',
    'heading',
    'speed_mps',
    'battery_percent',
    'connectivity',
    'app_language',
    'description_summary',
    'people_count',
    'injured',
    'nearest_event_id',
    'nfc_user_id_recent',
    'nfc_linked_seconds_ago',
    'client',
  ];

  static const _ctxLocationKeys = <String>{
    'reader_latitude',
    'reader_longitude',
    'location_accuracy_m',
    'altitude_m',
    'heading',
    'speed_mps',
  };
  static const _ctxDeviceKeys = <String>{
    'client_ts',
    'battery_percent',
    'connectivity',
    'app_language',
  };
  static const _ctxNfcKeys = <String>{
    'nfc_user_id_recent',
    'nfc_linked_seconds_ago',
  };
  static const _ctxMetaKeys = <String>{
    'description_summary',
    'people_count',
    'injured',
    'nearest_event_id',
    'client',
  };

  String _formatContextValue(dynamic v) {
    if (v == null) return '—';
    if (v is double) {
      if (v.isNaN || v.isInfinite) return v.toString();
      if (v == 0.0) return '0';
      if (v.abs() < 0.01 || v.abs() > 1e5) return v.toStringAsFixed(2);
      return v.toStringAsFixed(v.abs() < 10 ? 2 : 1);
    }
    return v.toString();
  }

  String _labelForContextKey(String key) {
    return switch (key) {
      'client_ts' => 'Time (UTC)',
      'reader_latitude' => 'Latitude',
      'reader_longitude' => 'Longitude',
      'location_accuracy_m' => 'GPS accuracy',
      'altitude_m' => 'Altitude',
      'heading' => 'Heading',
      'speed_mps' => 'Speed',
      'battery_percent' => 'Battery',
      'connectivity' => 'Network',
      'app_language' => 'Language',
      'description_summary' => 'Session',
      'people_count' => 'People',
      'injured' => 'Injured',
      'nearest_event_id' => 'Event id',
      'nfc_user_id_recent' => 'Last card user',
      'nfc_linked_seconds_ago' => 'Since last tap',
      'client' => 'Client',
      _ => key,
    };
  }

  IconData _iconForContextKey(String key) {
    return switch (key) {
      'reader_latitude' => Icons.explore_rounded,
      'reader_longitude' => Icons.explore_rounded,
      'location_accuracy_m' => Icons.gps_fixed_rounded,
      'altitude_m' => Icons.terrain_rounded,
      'heading' => Icons.navigation_rounded,
      'speed_mps' => Icons.speed_rounded,
      'battery_percent' => Icons.battery_charging_full_rounded,
      'connectivity' => Icons.wifi_rounded,
      'app_language' => Icons.language_rounded,
      'client_ts' => Icons.schedule_rounded,
      'nfc_user_id_recent' => Icons.nfc_rounded,
      'nfc_linked_seconds_ago' => Icons.nfc_rounded,
      'description_summary' => Icons.emergency_rounded,
      'people_count' => Icons.groups_rounded,
      'injured' => Icons.healing_rounded,
      'nearest_event_id' => Icons.event_rounded,
      'client' => Icons.phone_android_rounded,
      _ => Icons.info_outline_rounded,
    };
  }

  List<MapEntry<String, dynamic>> _orderedEntries(Map<String, dynamic> m, Set<String> keys) {
    final out = <MapEntry<String, dynamic>>[];
    for (final k in _readerContextKeyOrder) {
      if (keys.contains(k) && m.containsKey(k)) {
        out.add(MapEntry(k, m[k]));
      }
    }
    for (final k in m.keys) {
      if (keys.contains(k) && !out.any((e) => e.key == k)) {
        out.add(MapEntry(k, m[k]));
      }
    }
    return out;
  }

  Widget _dispatchContextBody(BuildContext context, Map<String, dynamic> m) {
    final sections = <({String title, IconData icon, List<MapEntry<String, dynamic>> entries})>[];

    final loc = _orderedEntries(m, _ctxLocationKeys);
    if (loc.isNotEmpty) {
      sections.add((title: 'Reader location', icon: Icons.pin_drop_rounded, entries: loc));
    }
    final dev = _orderedEntries(m, _ctxDeviceKeys);
    if (dev.isNotEmpty) {
      sections.add((title: 'This device', icon: Icons.smartphone_rounded, entries: dev));
    }
    final nfc = _orderedEntries(m, _ctxNfcKeys);
    if (nfc.isNotEmpty) {
      sections.add((title: 'NFC linkage', icon: Icons.nfc_rounded, entries: nfc));
    }
    final meta = _orderedEntries(m, _ctxMetaKeys);
    if (meta.isNotEmpty) {
      sections.add((title: 'Dispatch meta', icon: Icons.shield_rounded, entries: meta));
    }

    final used = <String>{
      ...loc.map((e) => e.key),
      ...dev.map((e) => e.key),
      ...nfc.map((e) => e.key),
      ...meta.map((e) => e.key),
    };
    final rest = <MapEntry<String, dynamic>>[];
    for (final k in _readerContextKeyOrder) {
      if (!used.contains(k) && m.containsKey(k)) {
        rest.add(MapEntry(k, m[k]));
      }
    }
    for (final k in m.keys) {
      if (!used.contains(k) && !rest.any((e) => e.key == k)) {
        rest.add(MapEntry(k, m[k]));
      }
    }
    if (rest.isNotEmpty) {
      sections.add((title: 'Other', icon: Icons.more_horiz_rounded, entries: rest));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < sections.length; i++) ...[
          if (i > 0) const SizedBox(height: 16),
          _DispatchSubsection(
            title: sections[i].title,
            icon: sections[i].icon,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final w = constraints.maxWidth;
                final col = w >= 340 ? (w - 8) / 2 : w;
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: sections[i].entries.map((e) {
                    return SizedBox(
                      width: col,
                      child: _MetricTile(
                        icon: _iconForContextKey(e.key),
                        label: _labelForContextKey(e.key),
                        value: _formatContextValue(e.value),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _readerContextSection(BuildContext context) {
    if (_readerContextError != null) {
      return GlassCard(
        padding: const EdgeInsets.all(18),
        child: _InlineAlert(
          icon: Icons.location_off_rounded,
          iconColor: _warnAmber,
          title: 'Could not capture reader context',
          body: _readerContextError.toString(),
          dense: true,
        ),
      );
    }
    if (_readerContext == null) {
      return GlassCard(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.6,
                color: _nfcAccent.withValues(alpha: 0.9),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Capturing dispatch context',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Location, battery, network — same bundle as SOS.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white60,
                          height: 1.35,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return GlassCard(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel(
            icon: Icons.radar_rounded,
            title: 'This phone',
            subtitle: 'Live reader snapshot for responders',
            accent: _nfcAccent,
          ),
          const SizedBox(height: 18),
          _dispatchContextBody(context, _readerContext!),
        ],
      ),
    );
  }

  Widget? _tagPayloadSection(BuildContext context) {
    final raw = _cardExtras;
    if (raw == null || raw.isEmpty) return null;

    String pretty;
    try {
      pretty = const JsonEncoder.withIndent('  ').convert(raw);
    } catch (_) {
      pretty = raw.toString();
    }

    return GlassCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.zero,
          childrenPadding: EdgeInsets.zero,
          initiallyExpanded: false,
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _nfcAccent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.data_object_rounded, color: _nfcAccent, size: 22),
          ),
          title: Text(
            'Raw tag payload',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Full JSON on the physical card — extras, SOS fields, experiments.',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.white54,
                    height: 1.35,
                  ),
            ),
          ),
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: pretty));
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Tag JSON copied'),
                      behavior: SnackBarBehavior.floating,
                      margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                },
                icon: const Icon(Icons.copy_rounded, size: 18),
                label: const Text('Copy JSON'),
                style: TextButton.styleFrom(
                  foregroundColor: _nfcAccent,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: SelectableText(
                pretty,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                      height: 1.45,
                      color: Colors.white.withValues(alpha: 0.88),
                      fontSize: 11.5,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).take(2).toList();
    if (parts.isEmpty) return '?';
    return parts.map((p) => p.isNotEmpty ? p[0].toUpperCase() : '').join();
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync =
        _scannedUserId == null ? null : ref.watch(nfcProvider(_scannedUserId!));

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Emergency NFC',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
            ),
            Text(
              'Card reader · dispatch context',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.white54,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0.0, 0.45, 1.0],
            colors: [
              Color(0xFF070B14),
              Color(0xFF0B1220),
              Color(0xFF101A2C),
            ],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            children: [
              _ScanHeroCard(
                isScanning: _isScanning,
                pulse: _pulse,
                onScan: _startScan,
                scannedId: _scannedUserId,
                errorText: _errorMessage,
              ),
              if (_isScanning) ...[
                const SizedBox(height: 14),
                const _ScanningHintCard(),
              ],
              if (profileAsync != null) ...[
                const SizedBox(height: 18),
                AnimatedSwitcher(
                  duration: MotionTokens.duration(context, MotionTokens.standard),
                  switchInCurve: MotionTokens.easeOut,
                  child: profileAsync.when(
                    data: (profile) {
                      final merged = NfcProfile.mergeWithCard(profile, _cardExtras);
                      return GlassCard(
                        key: ValueKey('ok_${merged.name}_${merged.emergencyContact}'),
                        padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
                        child: _ProfilePanel(
                          profile: merged,
                          initials: _initials(merged.name),
                        ),
                      );
                    },
                    loading: () => GlassCard(
                      key: const ValueKey('loading'),
                      padding: const EdgeInsets.all(20),
                      child: const _ProfileSkeleton(),
                    ),
                    error: (err, __) => GlassCard(
                      key: ValueKey('err_$err'),
                      padding: const EdgeInsets.all(18),
                      child: _InlineAlert(
                        icon: Icons.cloud_off_rounded,
                        iconColor: Colors.redAccent.shade100,
                        title: 'Profile unavailable',
                        body: err.toString(),
                      ),
                    ),
                  ),
                ),
              ],
              if (_scannedUserId != null) ...[
                const SizedBox(height: 18),
                _readerContextSection(context),
                if (_tagPayloadSection(context) != null) ...[
                  const SizedBox(height: 14),
                  _tagPayloadSection(context)!,
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ——— Presentation widgets ———

class _ScanHeroCard extends StatelessWidget {
  const _ScanHeroCard({
    required this.isScanning,
    required this.pulse,
    required this.onScan,
    this.scannedId,
    this.errorText,
  });

  final bool isScanning;
  final Animation<double> pulse;
  final VoidCallback onScan;
  final String? scannedId;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Scan emergency card',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Hold the card to the back of the phone until it reads.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white60,
                            height: 1.4,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              AnimatedBuilder(
                animation: pulse,
                builder: (context, child) {
                  return Transform.scale(
                    scale: isScanning ? pulse.value : 1.0,
                    child: child,
                  );
                },
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isScanning
                          ? [
                              _nfcAccent.withValues(alpha: 0.35),
                              _nfcAccentDim.withValues(alpha: 0.25),
                            ]
                          : [
                              Colors.white.withValues(alpha: 0.12),
                              Colors.white.withValues(alpha: 0.06),
                            ],
                    ),
                    border: Border.all(
                      color: isScanning
                          ? _nfcAccent.withValues(alpha: 0.55)
                          : Colors.white.withValues(alpha: 0.14),
                      width: 1.2,
                    ),
                    boxShadow: isScanning
                        ? [
                            BoxShadow(
                              color: _nfcAccent.withValues(alpha: 0.25),
                              blurRadius: 18,
                              spreadRadius: 0,
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    Icons.nfc_rounded,
                    size: 30,
                    color: isScanning ? _nfcAccent : Colors.white70,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: PressEffect(
              borderRadius: BorderRadius.circular(16),
              child: FilledButton(
                onPressed: isScanning ? null : onScan,
                style: FilledButton.styleFrom(
                  elevation: isScanning ? 0 : 2,
                  shadowColor: Colors.red.withValues(alpha: 0.45),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isScanning) ...[
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Text(
                      isScanning ? 'Listening for NFC…' : 'Scan emergency card',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (scannedId != null) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Row(
                children: [
                  Icon(Icons.badge_rounded, size: 18, color: _nfcAccent.withValues(alpha: 0.9)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CARD ID',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: Colors.white54,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.6,
                              ),
                        ),
                        const SizedBox(height: 2),
                        SelectableText(
                          scannedId!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withValues(alpha: 0.92),
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (errorText != null) ...[
            const SizedBox(height: 14),
            _InlineAlert(
              icon: Icons.error_outline_rounded,
              iconColor: Colors.redAccent.shade100,
              title: 'Scan issue',
              body: errorText!,
              dense: true,
            ),
          ],
        ],
      ),
    );
  }
}

class _ScanningHintCard extends StatelessWidget {
  const _ScanningHintCard();

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _nfcAccent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.touch_app_rounded, color: _nfcAccent, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Keep the card steady',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  'Move slowly; most phones read best near the camera bump.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white60,
                        height: 1.35,
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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: accent, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.58),
                      height: 1.35,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DispatchSubsection extends StatelessWidget {
  const _DispatchSubsection({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.white54),
            const SizedBox(width: 8),
            Text(
              title.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        child,
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white.withValues(alpha: 0.05),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: _nfcAccent.withValues(alpha: 0.85)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.white54,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        height: 1.25,
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

class _ProfilePanel extends StatelessWidget {
  const _ProfilePanel({
    required this.profile,
    required this.initials,
  });

  final NfcProfile profile;
  final String initials;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel(
          icon: Icons.medical_information_rounded,
          title: 'Medical profile',
          subtitle: 'From your server · card JSON can override some fields',
          accent: Color(0xFFFF6B6B),
        ),
        const SizedBox(height: 18),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.red.shade400.withValues(alpha: 0.5),
                    Colors.red.shade900.withValues(alpha: 0.35),
                  ],
                ),
                border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
              ),
              child: Text(
                initials,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _InfoChip(
                        icon: Icons.bloodtype_rounded,
                        label: profile.bloodGroup,
                        emphasize: true,
                      ),
                      if (profile.age != null)
                        _InfoChip(
                          icon: Icons.cake_rounded,
                          label: '${profile.age} yrs',
                          emphasize: false,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        if (profile.healthSummary != null && profile.healthSummary!.trim().isNotEmpty) ...[
          const SizedBox(height: 16),
          _ProfileInfoRow(
            icon: Icons.monitor_heart_rounded,
            label: 'Conditions',
            value: profile.healthSummary!.trim(),
          ),
        ],
        const SizedBox(height: 12),
        _ProfileInfoRow(
          icon: Icons.coronavirus_outlined,
          label: 'Allergies',
          value: profile.allergies,
        ),
        const SizedBox(height: 4),
        _EmergencyContactRow(phone: profile.emergencyContact),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.emphasize,
  });

  final IconData icon;
  final String label;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: emphasize
            ? Colors.red.withValues(alpha: 0.18)
            : Colors.white.withValues(alpha: 0.08),
        border: Border.all(
          color: emphasize
              ? Colors.redAccent.withValues(alpha: 0.35)
              : Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 18,
            color: emphasize ? Colors.red.shade200 : Colors.white70,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: emphasize ? Colors.red.shade50 : Colors.white,
                ),
          ),
        ],
      ),
    );
  }
}

class _ProfileInfoRow extends StatelessWidget {
  const _ProfileInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.white54),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Colors.white54,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 3),
                SelectableText(
                  value,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        height: 1.35,
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

class _EmergencyContactRow extends StatelessWidget {
  const _EmergencyContactRow({required this.phone});

  final String phone;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          colors: [
            _nfcAccent.withValues(alpha: 0.12),
            Colors.white.withValues(alpha: 0.04),
          ],
        ),
        border: Border.all(color: _nfcAccent.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.emergency_rounded, color: _nfcAccent, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Emergency contact',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Colors.white60,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                SelectableText(
                  phone,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                ),
              ],
            ),
          ),
          IconButton.filledTonal(
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.1),
            ),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: phone));
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Number copied'),
                  behavior: SnackBarBehavior.floating,
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
            },
            icon: const Icon(Icons.copy_rounded, size: 20),
            tooltip: 'Copy number',
          ),
        ],
      ),
    );
  }
}

class _ProfileSkeleton extends StatelessWidget {
  const _ProfileSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 18,
                    width: 160,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    height: 14,
                    width: 120,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        for (var i = 0; i < 4; i++) ...[
          Container(
            height: 14,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ],
      ],
    );
  }
}

class _InlineAlert extends StatelessWidget {
  const _InlineAlert({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.body,
    this.dense = false,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String body;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor, size: dense ? 22 : 26),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: Colors.white.withValues(alpha: 0.95),
                    ),
              ),
              SizedBox(height: dense ? 4 : 6),
              Text(
                body,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white70,
                      height: 1.4,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
