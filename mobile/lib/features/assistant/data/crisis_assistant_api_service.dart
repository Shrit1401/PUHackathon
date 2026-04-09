import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/constants/app_constants.dart';

class CrisisAssistantApiService {
  Future<Map<String, dynamic>> generateAll({
    required String language,
    required String location,
    required String panicInput,
    required String hazard,
    required bool lowArea,
    required bool night,
    required String forwardedText,
    required String voiceText,
    required String advisoryText,
  }) async {
    final apiKey = AppConstants.openAiApiKey;
    if (apiKey.isEmpty) {
      throw Exception('Missing OPENAI_API_KEY. Set it in .env or --dart-define.');
    }

    final prompt = '''
You are a disaster-response assistant. Return ONLY valid JSON object.
Language: $language
Location: $location
Hazard: $hazard
Low area: $lowArea
Night: $night
Panic input: $panicInput
Forwarded message: $forwardedText
Voice transcript: $voiceText
Official advisory: $advisoryText

Required JSON shape:
{
  "incident": {
    "disaster_type": "string",
    "severity": "critical|high|moderate|low",
    "people_count": 1,
    "urgent_needs": ["string"]
  },
  "panic_to_action": ["short bullet", "..."],
  "translated_phrase": "translation of: Need rescue now",
  "plain_advisory": "plain language advisory",
  "survival_guidance": ["do/don't bullet", "..."],
  "rumor_check": "label + short reason + mention official verification",
  "voice_companion": ["adaptive guidance", "..."],
  "family_message": "concise message to family",
  "responder_brief": ["5 lines max"],
  "mental_first_aid": ["30-second grounding steps"],
  "recovery_copilot": ["forms/docs/eligibility/deadlines checklist"]
}

Rules:
- Keep bullets concise and actionable.
- Respect selected language for user-facing outputs where possible.
- No markdown, no extra keys, no explanation outside JSON.
''';

    final res = await http.post(
      Uri.parse('https://api.openai.com/v1/responses'),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': AppConstants.openAiModel,
        'input': prompt,
      }),
    );

    if (res.statusCode >= 400) {
      throw Exception('OpenAI call failed (${res.statusCode}): ${res.body}');
    }

    final raw = jsonDecode(res.body) as Map<String, dynamic>;
    final text = (raw['output_text'] ?? '').toString().trim();
    if (text.isEmpty) {
      throw Exception('OpenAI returned empty output_text.');
    }

    final parsed = _extractJsonObject(text);
    return parsed;
  }

  Map<String, dynamic> _extractJsonObject(String text) {
    try {
      return Map<String, dynamic>.from(jsonDecode(text) as Map);
    } catch (_) {
      final start = text.indexOf('{');
      final end = text.lastIndexOf('}');
      if (start == -1 || end == -1 || end <= start) {
        throw Exception('Response was not JSON.');
      }
      final slice = text.substring(start, end + 1);
      return Map<String, dynamic>.from(jsonDecode(slice) as Map);
    }
  }
}
