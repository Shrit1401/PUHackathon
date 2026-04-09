import 'package:shared_preferences/shared_preferences.dart';

/// Remembers last successful NFC profile scan so SOS can reference it in context.
class NfcLinkage {
  NfcLinkage({required this.userId, required this.at});

  final String userId;
  final DateTime at;

  int? secondsAgo() {
    final s = DateTime.now().difference(at).inSeconds;
    return s < 0 ? null : s;
  }
}

class NfcLinkageStore {
  static const _kUser = 'nfc_link_last_user_id';
  static const _kAt = 'nfc_link_last_at_ms';

  static Future<void> recordLink(SharedPreferences prefs, String userId) async {
    await prefs.setString(_kUser, userId);
    await prefs.setInt(_kAt, DateTime.now().millisecondsSinceEpoch);
  }

  static Future<NfcLinkage?> read(SharedPreferences prefs) async {
    final id = prefs.getString(_kUser);
    final ms = prefs.getInt(_kAt);
    if (id == null || id.isEmpty || ms == null) return null;
    return NfcLinkage(userId: id, at: DateTime.fromMillisecondsSinceEpoch(ms));
  }
}
