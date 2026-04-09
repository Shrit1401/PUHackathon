import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/app_language.dart';
import '../../../../core/widgets/language_toggle.dart';
import '../../data/crisis_assistant_api_service.dart';
import '../../domain/crisis_assistant_engine.dart';

class PanicAssistantScreen extends ConsumerStatefulWidget {
  const PanicAssistantScreen({super.key, required this.mode});

  final String mode; // "speak" | "type"

  @override
  ConsumerState<PanicAssistantScreen> createState() => _PanicAssistantScreenState();
}

class _PanicAssistantScreenState extends ConsumerState<PanicAssistantScreen> {
  final _engine = CrisisAssistantEngine();
  final _api = CrisisAssistantApiService();
  final _input = TextEditingController();
  final _listController = ScrollController();

  final List<_ChatItem> _items = [];
  bool _busy = false;

  @override
  void dispose() {
    _input.dispose();
    _listController.dispose();
    super.dispose();
  }

  String _langCode(AppLanguage lang) {
    return switch (lang) {
      AppLanguage.en => 'en',
      AppLanguage.hi => 'hi',
      AppLanguage.kn => 'kn',
    };
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _busy) return;

    setState(() {
      _busy = true;
      _items.add(_ChatItem.user(text));
      _input.clear();
    });

    await _scrollToBottom();

    final lang = ref.read(appLanguageProvider);
    final code = _langCode(lang);

    List<String> steps;
    try {
      final ai = await _api.generateAll(
        language: code,
        location: 'current area',
        panicInput: text,
        hazard: 'flood',
        lowArea: true,
        night: false,
        forwardedText: '',
        voiceText: '',
        advisoryText: '',
      );
      steps = _toShortBullets(ai['panic_to_action']) ??
          _engine.panicToAction(text, lang: code);
    } catch (_) {
      steps = _engine.panicToAction(text, lang: code);
    }

    final reply = _limit(steps, 4);

    setState(() {
      _items.add(_ChatItem.assistant(reply));
      _busy = false;
    });

    await _scrollToBottom();
  }

  List<String> _limit(List<String> lines, int max) {
    final cleaned =
        lines.map((e) => e.trim()).where((e) => e.isNotEmpty).toList(growable: false);
    if (cleaned.length <= max) return cleaned;
    return cleaned.take(max).toList(growable: false);
  }

  List<String>? _toShortBullets(dynamic value) {
    if (value is! List) return null;
    return value.map((e) => e.toString()).where((e) => e.trim().isNotEmpty).toList();
  }

  Future<void> _scrollToBottom() async {
    if (!_listController.hasClients) return;
    await Future<void>.delayed(const Duration(milliseconds: 40));
    if (!_listController.hasClients) return;
    _listController.animateTo(
      _listController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(appLanguageProvider);
    final title = switch (lang) {
      AppLanguage.hi => 'सहायता',
      AppLanguage.kn => 'ಸಹಾಯ',
      AppLanguage.en => 'Help',
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: LanguageToggle(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _listController,
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              itemCount: _items.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _AssistantIntro(mode: widget.mode);
                }
                final item = _items[index - 1];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _ChatBubble(item: item),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.12),
              border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 56),
                      child: TextField(
                        controller: _input,
                        minLines: 1,
                        maxLines: 3,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _send(),
                        decoration: InputDecoration(
                          hintText: switch (lang) {
                            AppLanguage.hi => 'क्या हो रहा है?',
                            AppLanguage.kn => 'ಏನು ನಡೆಯುತ್ತಿದೆ?',
                            AppLanguage.en => 'What is happening?',
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    height: 56,
                    width: 56,
                    child: FilledButton(
                      onPressed: _busy ? null : _send,
                      style: FilledButton.styleFrom(
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: _busy
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: widget.mode == 'speak'
          ? FloatingActionButton.extended(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      switch (lang) {
                        AppLanguage.hi => 'बोलने वाला मोड जल्द आ रहा है। अभी टाइप करें।',
                        AppLanguage.kn => 'ಮಾತು ಮೋಡ್ ಶೀಘ್ರದಲ್ಲೇ. ಈಗ ಟೈಪ್ ಮಾಡಿ.',
                        AppLanguage.en => 'Speak mode coming soon. Please type for now.',
                      },
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.mic),
              label: Text(tr(ref, 'speak')),
            )
          : null,
    );
  }
}

class _AssistantIntro extends ConsumerWidget {
  const _AssistantIntro({required this.mode});
  final String mode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(appLanguageProvider);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white.withValues(alpha: 0.06),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
            ),
            child: const Icon(Icons.psychology, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              switch (lang) {
                AppLanguage.hi => '1–2 वाक्य में बताएं। मैं तुरंत छोटे कदम दूँगा/दूँगी।',
                AppLanguage.kn => '1–2 ವಾಕ್ಯಗಳಲ್ಲಿ ಹೇಳಿ. ನಾನು ತಕ್ಷಣ ಸಣ್ಣ ಹೆಜ್ಜೆಗಳು ಕೊಡುತ್ತೇನೆ.',
                AppLanguage.en => 'Tell me in 1–2 lines. I will give short, actionable steps.',
              },
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.item});
  final _ChatItem item;

  @override
  Widget build(BuildContext context) {
    final isUser = item.role == _ChatRole.user;
    final align = isUser ? Alignment.centerRight : Alignment.centerLeft;
    final bg = isUser
        ? Colors.white.withValues(alpha: 0.10)
        : Colors.white.withValues(alpha: 0.06);
    final border = Colors.white.withValues(alpha: isUser ? 0.14 : 0.10);

    return Align(
      alignment: align,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: border),
          ),
          child: item.bullets == null
              ? Text(
                  item.text ?? '',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final b in item.bullets!) ...[
                      Text(
                        '• $b',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              height: 1.25,
                            ),
                      ),
                      const SizedBox(height: 6),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}

enum _ChatRole { user, assistant }

class _ChatItem {
  const _ChatItem._(this.role, {this.text, this.bullets});

  final _ChatRole role;
  final String? text;
  final List<String>? bullets;

  factory _ChatItem.user(String text) => _ChatItem._(_ChatRole.user, text: text);
  factory _ChatItem.assistant(List<String> bullets) =>
      _ChatItem._(_ChatRole.assistant, bullets: bullets);
}

