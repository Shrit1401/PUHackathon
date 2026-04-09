import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppLanguage {
  en('EN', Locale('en')),
  hi('हिंदी', Locale('hi')),
  kn('ಕನ್ನಡ', Locale('kn'));

  const AppLanguage(this.label, this.locale);
  final String label;
  final Locale locale;
}

final appLanguageProvider = StateProvider<AppLanguage>((ref) {
  return AppLanguage.en;
});

const _strings = <String, Map<AppLanguage, String>>{
  'app_title': {
    AppLanguage.en: 'ResQNet',
    AppLanguage.hi: 'रेस्क्यूनेट',
    AppLanguage.kn: 'ರೆಸ್ಕ್ಯೂನೆಟ್',
  },
  'offline': {
    AppLanguage.en: 'OFFLINE',
    AppLanguage.hi: 'ऑफ़लाइन',
    AppLanguage.kn: 'ಆಫ್‌ಲೈನ್',
  },
  'online': {
    AppLanguage.en: 'ONLINE',
    AppLanguage.hi: 'ऑनलाइन',
    AppLanguage.kn: 'ಆನ್‌ಲೈನ್',
  },
  'area_risk': {
    AppLanguage.en: 'Area Risk',
    AppLanguage.hi: 'क्षेत्र जोखिम',
    AppLanguage.kn: 'ಪ್ರದೇಶದ ಅಪಾಯ',
  },
  'safe': {
    AppLanguage.en: 'SAFE',
    AppLanguage.hi: 'सुरक्षित',
    AppLanguage.kn: 'ಸುರಕ್ಷಿತ',
  },
  'moderate': {
    AppLanguage.en: 'MODERATE',
    AppLanguage.hi: 'मध्यम',
    AppLanguage.kn: 'ಮಧ್ಯಮ',
  },
  'high': {
    AppLanguage.en: 'HIGH',
    AppLanguage.hi: 'उच्च',
    AppLanguage.kn: 'ಹೆಚ್ಚು',
  },
  'tap_for_map': {
    AppLanguage.en: 'Tap to view map',
    AppLanguage.hi: 'मानचित्र देखने के लिए टैप करें',
    AppLanguage.kn: 'ನಕ್ಷೆ ನೋಡಲು ಟ್ಯಾಪ್ ಮಾಡಿ',
  },
  'sos_title': {
    AppLanguage.en: 'EMERGENCY SOS',
    AppLanguage.hi: 'आपातकालीन SOS',
    AppLanguage.kn: 'ತುರ್ತು SOS',
  },
  'sos_subtitle': {
    AppLanguage.en: 'Tap if you are in danger',
    AppLanguage.hi: 'खतरे में हों तो टैप करें',
    AppLanguage.kn: 'ಅಪಾಯದಲ್ಲಿದ್ದರೆ ಟ್ಯಾಪ್ ಮಾಡಿ',
  },
  'need_help_now': {
    AppLanguage.en: 'Need Help Now?',
    AppLanguage.hi: 'अभी मदद चाहिए?',
    AppLanguage.kn: 'ಈಗ ಸಹಾಯ ಬೇಕೇ?',
  },
  'speak': {
    AppLanguage.en: 'Speak',
    AppLanguage.hi: 'बोलें',
    AppLanguage.kn: 'ಮಾತನಾಡಿ',
  },
  'type': {
    AppLanguage.en: 'Type',
    AppLanguage.hi: 'लिखें',
    AppLanguage.kn: 'ಟೈಪ್',
  },
  'report_what_you_see': {
    AppLanguage.en: 'Report What You See',
    AppLanguage.hi: 'जो दिखे, रिपोर्ट करें',
    AppLanguage.kn: 'ನೀವು ನೋಡಿದುದನ್ನು ವರದಿ ಮಾಡಿ',
  },
  'shelter_finder': {
    AppLanguage.en: 'Shelter Finder',
    AppLanguage.hi: 'आश्रय खोजें',
    AppLanguage.kn: 'ಆಶ್ರಯ ಹುಡುಕಿ',
  },
  'view_safe_route': {
    AppLanguage.en: 'View Safe Route',
    AppLanguage.hi: 'सुरक्षित मार्ग देखें',
    AppLanguage.kn: 'ಸುರಕ್ಷಿತ ದಾರಿ ನೋಡಿ',
  },
  'live_alerts': {
    AppLanguage.en: 'Live Alerts',
    AppLanguage.hi: 'लाइव अलर्ट',
    AppLanguage.kn: 'ಲೈವ್ ಎಚ್ಚರಿಕೆಗಳು',
  },
  'family_update': {
    AppLanguage.en: 'Send Family Update',
    AppLanguage.hi: 'परिवार को अपडेट भेजें',
    AppLanguage.kn: 'ಕುಟುಂಬಕ್ಕೆ ಅಪ್ಡೇಟ್ ಕಳುಹಿಸಿ',
  },
  'advanced_tools': {
    AppLanguage.en: 'AI Safety Desk',
    AppLanguage.hi: 'AI सुरक्षा डेस्क',
    AppLanguage.kn: 'AI ಭದ್ರತಾ ಕೇಂದ್ರ',
  },
  'ai_toolkit': {
    AppLanguage.en: 'All AI Features',
    AppLanguage.hi: 'सभी AI फीचर्स',
    AppLanguage.kn: 'ಎಲ್ಲ AI ವೈಶಿಷ್ಟ್ಯಗಳು',
  },
  'detailed_report': {
    AppLanguage.en: 'Full Report Form',
    AppLanguage.hi: 'पूरी रिपोर्ट फॉर्म',
    AppLanguage.kn: 'ಪೂರ್ಣ ವರದಿ ಫಾರ್ಮ್',
  },
  'track_sos': {
    AppLanguage.en: 'Track SOS',
    AppLanguage.hi: 'SOS ट्रैक करें',
    AppLanguage.kn: 'SOS ಟ್ರ್ಯಾಕ್',
  },
  'confirm_sighting': {
    AppLanguage.en: 'I can see this too',
    AppLanguage.hi: 'मैं भी देख सकता/सकती हूँ',
    AppLanguage.kn: 'ನಾನೂ ನೋಡುತ್ತಿದ್ದೇನೆ',
  },
  'confirm': {
    AppLanguage.en: 'Confirm',
    AppLanguage.hi: 'पुष्टि',
    AppLanguage.kn: 'ದೃಢೀಕರಿಸಿ',
  },
  'confirmations': {
    AppLanguage.en: 'confirmations',
    AppLanguage.hi: 'पुष्टियाँ',
    AppLanguage.kn: 'ದೃಢೀಕರಣಗಳು',
  },
  'quick_safe': {
    AppLanguage.en: "I'm safe",
    AppLanguage.hi: 'मैं सुरक्षित हूँ',
    AppLanguage.kn: 'ನಾನು ಸುರಕ್ಷಿತ',
  },
  'quick_need_help': {
    AppLanguage.en: 'Need help',
    AppLanguage.hi: 'मदद चाहिए',
    AppLanguage.kn: 'ಸಹಾಯ ಬೇಕು',
  },
  'copied': {
    AppLanguage.en: 'Copied.',
    AppLanguage.hi: 'कॉपी हो गया।',
    AppLanguage.kn: 'ಕಾಪಿ ಆಯಿತು.',
  },
  'people_count': {
    AppLanguage.en: 'People',
    AppLanguage.hi: 'लोग',
    AppLanguage.kn: 'ಜನ',
  },
  'injury': {
    AppLanguage.en: 'Injury',
    AppLanguage.hi: 'चोट',
    AppLanguage.kn: 'ಗಾಯ',
  },
  'yes': {
    AppLanguage.en: 'YES',
    AppLanguage.hi: 'हाँ',
    AppLanguage.kn: 'ಹೌದು',
  },
  'no': {
    AppLanguage.en: 'NO',
    AppLanguage.hi: 'नहीं',
    AppLanguage.kn: 'ಇಲ್ಲ',
  },
  'send_sos': {
    AppLanguage.en: 'Send SOS',
    AppLanguage.hi: 'SOS भेजें',
    AppLanguage.kn: 'SOS ಕಳುಹಿಸಿ',
  },
  'cancel': {
    AppLanguage.en: 'Cancel',
    AppLanguage.hi: 'रद्द करें',
    AppLanguage.kn: 'ರದ್ದು',
  },
  'nfc_scan_top': {
    AppLanguage.en: 'NFC scan',
    AppLanguage.hi: 'NFC स्कैन',
    AppLanguage.kn: 'NFC ಸ್ಕ್ಯಾನ್',
  },
  'status_risk_safe': {
    AppLanguage.en: 'No major risk nearby right now. Stay prepared.',
    AppLanguage.hi: 'अभी पास में कोई बड़ा जोखिम नहीं। तैयार रहें।',
    AppLanguage.kn: 'ಈಗ ಹತ್ತಿರ ದೊಡ್ಡ ಅಪಾಯವಿಲ್ಲ. ಸಿದ್ಧರಾಗಿರಿ.',
  },
  'status_risk_moderate': {
    AppLanguage.en: 'Moderate risk nearby. Stay alert and avoid crowded routes.',
    AppLanguage.hi: 'पास में मध्यम जोखिम। सतर्क रहें और भीड़ वाले रास्तों से बचें।',
    AppLanguage.kn: 'ಹತ್ತಿರ ಮಧ್ಯಮ ಅಪಾಯ. ಎಚ್ಚರವಾಗಿರಿ ಮತ್ತು ಜನದಟ್ಟಣೆಯ ಮಾರ್ಗಗಳನ್ನು ತಪ್ಪಿಸಿ.',
  },
  'status_risk_high': {
    AppLanguage.en: 'High risk in your area. Keep location and phone active.',
    AppLanguage.hi: 'आपके क्षेत्र में उच्च जोखिम। लोकेशन और फोन सक्रिय रखें।',
    AppLanguage.kn: 'ನಿಮ್ಮ ಪ್ರದೇಶದಲ್ಲಿ ಹೆಚ್ಚಿನ ಅಪಾಯ. ಸ್ಥಾನ ಮತ್ತು ಫೋನ್ ಸಕ್ರಿಯವಾಗಿರಿಸಿ.',
  },
  'cluster_incidents_nearby': {
    AppLanguage.en:
        'Multiple active incidents nearby — avoid crowds and follow official alerts.',
    AppLanguage.hi:
        'आपके पास कई सक्रिय घटनाएँ दिख रही हैं — भीड़ से बचें और आधिकारिक अलर्ट देखें।',
    AppLanguage.kn:
        'ಹತ್ತಿರ ಹಲವು ಸಕ್ರಿಯ ಘಟನೆಗಳಿವೆ — ಗುಂಪುಗಳನ್ನು ತಪ್ಪಿಸಿ ಮತ್ತು ಅಧಿಕೃತ ಎಚ್ಚರಿಕೆಗಳನ್ನು ಅನುಸರಿಸಿ.',
  },
  'section_emergency': {
    AppLanguage.en: 'Emergency',
    AppLanguage.hi: 'आपातकाल',
    AppLanguage.kn: 'ತುರ್ತು',
  },
  'section_immediate_actions': {
    AppLanguage.en: 'Immediate Actions',
    AppLanguage.hi: 'तत्काल कार्य',
    AppLanguage.kn: 'ತಕ್ಷಣದ ಕ್ರಿಯೆಗಳು',
  },
  'section_live_updates': {
    AppLanguage.en: 'Live Updates',
    AppLanguage.hi: 'लाइव अपडेट',
    AppLanguage.kn: 'ಲೈವ್ ಅಪ್‌ಡೇಟ್‌ಗಳು',
  },
  'section_tools': {
    AppLanguage.en: 'Tools',
    AppLanguage.hi: 'उपकरण',
    AppLanguage.kn: 'ಉಪಕರಣಗಳು',
  },
  'action_safe_route_title': {
    AppLanguage.en: 'Safe Route',
    AppLanguage.hi: 'सुरक्षित मार्ग',
    AppLanguage.kn: 'ಸುರಕ್ಷಿತ ಮಾರ್ಗ',
  },
  'action_safe_route_sub': {
    AppLanguage.en: 'Open shelter map',
    AppLanguage.hi: 'आश्रय मानचित्र खोलें',
    AppLanguage.kn: 'ಆಶ್ರಯ ನಕ್ಷೆ ತೆರೆಯಿರಿ',
  },
  'action_health_ai_title': {
    AppLanguage.en: 'Health AI',
    AppLanguage.hi: 'स्वास्थ्य AI',
    AppLanguage.kn: 'ಆರೋಗ್ಯ AI',
  },
  'action_health_ai_sub': {
    AppLanguage.en: 'Get quick guidance',
    AppLanguage.hi: 'तुरंत मार्गदर्शन पाएँ',
    AppLanguage.kn: 'ತ್ವರಿತ ಮಾರ್ಗದರ್ಶನ ಪಡೆಯಿರಿ',
  },
  'action_report_title': {
    AppLanguage.en: 'Report',
    AppLanguage.hi: 'रिपोर्ट',
    AppLanguage.kn: 'ವರದಿ',
  },
  'action_report_sub': {
    AppLanguage.en: 'Send incident details',
    AppLanguage.hi: 'घटना विवरण भेजें',
    AppLanguage.kn: 'ಘಟನೆಯ ವಿವರಗಳನ್ನು ಕಳುಹಿಸಿ',
  },
  'action_alerts_title': {
    AppLanguage.en: 'Alerts',
    AppLanguage.hi: 'अलर्ट',
    AppLanguage.kn: 'ಎಚ್ಚರಿಕೆಗಳು',
  },
  'action_alerts_sub': {
    AppLanguage.en: 'View live warnings',
    AppLanguage.hi: 'लाइव चेतावनियाँ देखें',
    AppLanguage.kn: 'ಲೈವ್ ಎಚ್ಚರಿಕೆಗಳನ್ನು ನೋಡಿ',
  },
  'live_feed_subtitle': {
    AppLanguage.en: 'Official and citizen feed',
    AppLanguage.hi: 'आधिकारिक और नागरिक फ़ीड',
    AppLanguage.kn: 'ಅಧಿಕೃತ ಮತ್ತು ನಾಗರಿಕ ಫೀಡ್',
  },
  'more_tools_title': {
    AppLanguage.en: 'More Tools',
    AppLanguage.hi: 'और उपकरण',
    AppLanguage.kn: 'ಹೆಚ್ಚಿನ ಉಪಕರಣಗಳು',
  },
  'more_tools_subtitle': {
    AppLanguage.en: 'Smartwatch, advanced report, AI lab',
    AppLanguage.hi: 'स्मार्टवॉच, विस्तृत रिपोर्ट, AI लैब',
    AppLanguage.kn: 'ಸ್ಮಾರ್ಟ್‌ವಾಚ್, ವಿಸ್ತೃತ ವರದಿ, AI ಲ್ಯಾಬ್',
  },
  'smartwatch': {
    AppLanguage.en: 'Smartwatch',
    AppLanguage.hi: 'स्मार्टवॉच',
    AppLanguage.kn: 'ಸ್ಮಾರ್ಟ್‌ವಾಚ್',
  },
  'assistant_symptoms_detail': {
    AppLanguage.en: 'Describe symptoms to get immediate steps and medicine guidance.',
    AppLanguage.hi: 'तुरंत कदम और दवा संबंधी मार्गदर्शन पाने के लिए लक्षण बताएँ।',
    AppLanguage.kn: 'ತಕ್ಷಣದ ಹಂತಗಳು ಮತ್ತು ಔಷಧಿ ಮಾರ್ಗದರ್ಶನಕ್ಕೆ ಲಕ್ಷಣಗಳನ್ನು ವಿವರಿಸಿ.',
  },
  'sos_semantics_label': {
    AppLanguage.en: 'Emergency SOS',
    AppLanguage.hi: 'आपातकालीन SOS',
    AppLanguage.kn: 'ತುರ್ತು SOS',
  },
  'community_title': {
    AppLanguage.en: 'Community',
    AppLanguage.hi: 'कम्युनिटी',
    AppLanguage.kn: 'ಸಮುದಾಯ',
  },
  'community_subtitle': {
    AppLanguage.en: 'Nearby alerts • confirm • news • photos',
    AppLanguage.hi: 'पास के अलर्ट • पुष्टि • समाचार • फोटो',
    AppLanguage.kn: 'ಹತ್ತಿರ ಎಚ್ಚರಿಕೆ • ದೃಢೀಕರಣ • ಸುದ್ದಿ • ಫೋಟೋ',
  },
  'footer_sos_reminder': {
    AppLanguage.en: 'In danger: press SOS. Stay calm.',
    AppLanguage.hi: 'संकट में: SOS दबाएँ। शांत रहें।',
    AppLanguage.kn: 'ಸಂಕಟದಲ್ಲಿ: SOS ಒತ್ತಿ. ಶಾಂತವಾಗಿರಿ.',
  },
  'distance_km_suffix': {
    AppLanguage.en: 'km away',
    AppLanguage.hi: 'किमी दूर',
    AppLanguage.kn: 'ಕಿ.ಮೀ ದೂರ',
  },
  'shelter_slots_suffix': {
    AppLanguage.en: 'slots',
    AppLanguage.hi: 'जगहें',
    AppLanguage.kn: 'ಸ್ಥಾನಗಳು',
  },
  'shelter_nearest_fallback': {
    AppLanguage.en: 'Nearest Shelter',
    AppLanguage.hi: 'निकटतम आश्रय',
    AppLanguage.kn: 'ಹತ್ತಿರದ ಆಶ್ರಯ',
  },
  'distance_unknown': {
    AppLanguage.en: '--',
    AppLanguage.hi: '--',
    AppLanguage.kn: '--',
  },
  'no_active_alert_nearby': {
    AppLanguage.en: 'No active alert nearby',
    AppLanguage.hi: 'पास में कोई अलर्ट नहीं',
    AppLanguage.kn: 'ಹತ್ತಿರ ಎಚ್ಚರಿಕೆ ಇಲ್ಲ',
  },
  'feed_nearby_label': {
    AppLanguage.en: 'Nearby',
    AppLanguage.hi: 'पास में',
    AppLanguage.kn: 'ಹತ್ತಿರ',
  },
};

String tr(WidgetRef ref, String key) {
  final lang = ref.watch(appLanguageProvider);
  final map = _strings[key];
  if (map == null) return key;
  return map[lang] ?? map[AppLanguage.en] ?? key;
}

