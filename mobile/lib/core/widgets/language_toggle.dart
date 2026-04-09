import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../localization/app_language.dart';

class LanguageToggle extends ConsumerWidget {
  const LanguageToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(appLanguageProvider);

    return SegmentedButton<AppLanguage>(
      segments: const [
        ButtonSegment(value: AppLanguage.en, label: Text('EN')),
        ButtonSegment(value: AppLanguage.hi, label: Text('हिंदी')),
        ButtonSegment(value: AppLanguage.kn, label: Text('ಕನ್ನಡ')),
      ],
      selected: {lang},
      showSelectedIcon: false,
      onSelectionChanged: (s) {
        final next = s.isEmpty ? AppLanguage.en : s.first;
        ref.read(appLanguageProvider.notifier).state = next;
      },
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        ),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white.withValues(alpha: 0.14);
          }
          return Colors.white.withValues(alpha: 0.06);
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return Colors.white.withValues(alpha: 0.78);
        }),
        side: WidgetStateProperty.all(
          BorderSide(color: Colors.white.withValues(alpha: 0.10)),
        ),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}

