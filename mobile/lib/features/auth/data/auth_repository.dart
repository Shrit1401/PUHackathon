import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../core/network/api_client.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ApiClient());
});

class DashboardUser {
  DashboardUser({
    required this.id,
    required this.role,
    this.email,
    this.phone,
    this.accessToken,
  });

  final String id;
  final String role;
  final String? email;
  final String? phone;
  final String? accessToken;
}

class AuthRepository {
  AuthRepository(this._api);

  final ApiClient _api;

  DashboardUser? _currentUser;
  final _authController = StreamController<DashboardUser?>.broadcast();

  DashboardUser? get currentUser => _currentUser;

  Stream<DashboardUser?> get authState => _authController.stream;

  String normalizePhone(String value) => value.trim().replaceAll(' ', '');
  bool isValidE164(String phone) =>
      RegExp(r'^\+[1-9]\d{7,14}$').hasMatch(normalizePhone(phone));

  Future<void> sendPhoneOtp(String phone) async {
    final normalized = normalizePhone(phone);
    if (!isValidE164(normalized)) {
      throw Exception('Phone must be E.164 format, e.g. +14155550123');
    }

    final uri = Uri.parse('${_api.baseUrl}/auth/phone/send-otp');
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone': normalized}),
    );
    if (res.statusCode >= 400) {
      throw Exception('Failed to send OTP: ${res.body}');
    }
  }

  Future<void> verifyPhoneOtp({
    required String phone,
    required String token,
    String? fullName,
  }) async {
    final normalized = normalizePhone(phone);
    if (!isValidE164(normalized)) {
      throw Exception('Phone must be E.164 format, e.g. +14155550123');
    }

    final uri = Uri.parse('${_api.baseUrl}/auth/phone/verify-otp');
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'phone': normalized,
        'otp': token.trim(),
        if (fullName != null && fullName.trim().isNotEmpty)
          'name': fullName.trim(),
      }),
    );

    if (res.statusCode >= 400) {
      throw Exception('OTP verification failed: ${res.body}');
    }

    final body = jsonDecode(res.body) as Map<String, dynamic>;
    _currentUser = DashboardUser(
      id: body['user_id'] as String,
      role: (body['role'] as String?) ?? 'citizen',
      phone: body['phone'] as String?,
      accessToken: body['access_token'] as String?,
    );
    _authController.add(_currentUser);
  }

  Future<void> signOut() async {
    try {
      final uri = Uri.parse('${_api.baseUrl}/auth/logout');
      await http.post(uri);
    } catch (_) {
      // Ignore logout network errors.
    }
    _currentUser = null;
    _authController.add(null);
  }
}

