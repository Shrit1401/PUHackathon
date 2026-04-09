import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/network/api_client.dart';
import '../core/network/supabase_provider.dart';

final nfcServiceProvider = Provider<NfcService>((ref) {
  return NfcService(
    api: ApiClient(),
    supabase: ref.watch(supabaseClientProvider),
  );
});

class NfcProfile {
  NfcProfile({
    required this.name,
    required this.bloodGroup,
    required this.allergies,
    required this.emergencyContact,
    this.age,
    this.healthSummary,
  });

  final String name;
  final String bloodGroup;
  final String allergies;
  final String emergencyContact;

  /// From NFC card JSON overlay (API may not include age / free-text health line).
  final int? age;
  final String? healthSummary;

  /// Merges API profile with optional fields written on the physical card.
  static NfcProfile mergeWithCard(NfcProfile api, Map<String, dynamic>? card) {
    if (card == null || card.isEmpty) return api;

    int? age;
    final rawAge = card['age'];
    if (rawAge is int) {
      age = rawAge;
    } else if (rawAge != null) {
      age = int.tryParse(rawAge.toString().trim());
    }

    final health = card['health_conditions'] ?? card['health_summary'];
    final healthSummary = health == null ? api.healthSummary : health.toString().trim();

    final displayName = card['display_name']?.toString().trim();
    final apiName = api.name.trim();
    final name = (apiName.isNotEmpty && apiName != 'Unknown')
        ? api.name
        : ((displayName != null && displayName.isNotEmpty) ? displayName : api.name);

    return NfcProfile(
      name: name,
      bloodGroup: api.bloodGroup,
      allergies: api.allergies,
      emergencyContact: api.emergencyContact,
      age: age ?? api.age,
      healthSummary: (healthSummary != null && healthSummary.isNotEmpty) ? healthSummary : api.healthSummary,
    );
  }
}

class NfcService {
  NfcService({
    required ApiClient api,
    required SupabaseClient supabase,
  })  : _api = api,
        _supabase = supabase;

  final ApiClient _api;
  final SupabaseClient _supabase;

  static final _uuidPattern = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  /// True if [id] looks like a real UUID (not a doc placeholder like `"uuid"`).
  static bool looksLikeUserUuid(String id) => _uuidPattern.hasMatch(id.trim());

  Future<NfcProfile> fetchProfile(String userId) async {
    final id = userId.trim();
    if (id.isEmpty) {
      throw Exception('Card has no user_id. Write JSON like {"user_id":"<your-real-uuid>"} on the tag.');
    }
    if (!looksLikeUserUuid(id)) {
      throw Exception(
        'Card user_id "$id" is not a valid UUID. '
        'Use the real user_id from signup/SQL (e.g. 11111111-1111-1111-1111-111111111111), '
        'not the word "uuid". NFC tags only need user_id (+ optional display_name, age, health_conditions) — '
        'not the full SOS/context payload.',
      );
    }

    Object? apiError;
    try {
      final json = await _api.getJson('/nfc/profile/$id');
      return _profileFromRestJson(json);
    } catch (e) {
      apiError = e;
    }

    try {
      return await _fetchProfileFromSupabase(id);
    } catch (e2) {
      final apiMsg = apiError.toString();
      if (apiMsg.contains('404') || apiMsg.contains('Profile not found')) {
        throw Exception(
          'No profile for user_id $id. API returned not found; Supabase: $e2',
        );
      }
      throw Exception(
        'NFC profile unavailable. API: $apiError. Supabase fallback: $e2',
      );
    }
  }

  NfcProfile _profileFromRestJson(Map<String, dynamic> json) {
    return NfcProfile(
      name: (json['name'] ?? 'Unknown').toString(),
      bloodGroup: (json['blood_group'] ?? 'NA').toString(),
      allergies: (json['allergies'] ?? 'None reported').toString(),
      emergencyContact: (json['emergency_contact'] ?? 'Not available').toString(),
      age: null,
      healthSummary: null,
    );
  }

  /// Reads `public.profiles` (same row shape as your citizen users).
  Future<NfcProfile> _fetchProfileFromSupabase(String id) async {
    final row = await _supabase.from('profiles').select().eq('id', id).maybeSingle();

    if (row == null) {
      throw Exception('No row in public.profiles for id=$id (check RLS SELECT for anon/authenticated).');
    }

    final name = (row['name'] ?? row['full_name'] ?? 'Unknown').toString();
    return NfcProfile(
      name: name,
      bloodGroup: (row['blood_group'] ?? 'NA').toString(),
      allergies: (row['allergies'] ?? 'None reported').toString(),
      emergencyContact: (row['emergency_contact'] ?? row['phone'] ?? 'Not available').toString(),
      age: null,
      healthSummary: null,
    );
  }
}
