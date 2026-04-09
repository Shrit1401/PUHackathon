import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  const AppConstants._();

  static String get supabaseUrl {
    const fromEnv = String.fromEnvironment('SUPABASE_URL');
    if (fromEnv.isNotEmpty) return fromEnv;
    return dotenv.env['SUPABASE_URL'] ?? '';
  }

  static String get supabaseAnonKey {
    const fromEnv = String.fromEnvironment('SUPABASE_ANON_KEY');
    if (fromEnv.isNotEmpty) return fromEnv;
    return dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  }

  static String get openAiApiKey {
    const fromEnv = String.fromEnvironment('OPENAI_API_KEY');
    if (fromEnv.isNotEmpty) return fromEnv;
    return dotenv.env['OPENAI_API_KEY'] ?? '';
  }

  static String get openAiModel {
    const fromEnv = String.fromEnvironment('OPENAI_MODEL');
    if (fromEnv.isNotEmpty) return fromEnv;
    return dotenv.env['OPENAI_MODEL'] ?? 'gpt-5-mini';
  }

  static const emergencyRed = 0xFFFF3B30;

  /// When true, NFC scan rows are inserted via the Supabase client into `nfc_card_scans` instead of `POST /nfc/scans`.
  /// Use this if you created the table in Supabase but have not implemented the REST API route yet.
  static bool get nfcScansSupabaseInsert {
    final v = dotenv.env['NFC_SCANS_SUPABASE_INSERT']?.toLowerCase().trim();
    return v == 'true' || v == '1' || v == 'yes';
  }
}
