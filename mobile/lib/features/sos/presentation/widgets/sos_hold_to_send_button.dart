import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Hold ~1.2s to confirm — reduces accidental SOS taps.
class SosHoldToSendButton extends StatefulWidget {
  const SosHoldToSendButton({
    super.key,
    required this.label,
    required this.onConfirmed,
    this.enabled = true,
    this.stealth = false,
  });

  final String label;
  final VoidCallback onConfirmed;
  final bool enabled;
  final bool stealth;

  @override
  State<SosHoldToSendButton> createState() => _SosHoldToSendButtonState();
}

class _SosHoldToSendButtonState extends State<SosHoldToSendButton> with SingleTickerProviderStateMixin {
  static const _holdMs = 1200;
  late final AnimationController _ac;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _holdMs),
    )..addListener(() => setState(() {}))
    ..addStatusListener((s) {
        if (s == AnimationStatus.completed) {
          if (!widget.enabled) return;
          if (widget.stealth) {
            HapticFeedback.selectionClick();
          } else {
            HapticFeedback.heavyImpact();
          }
          widget.onConfirmed();
          _ac.reset();
          setState(() {});
        }
      });
  }

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: widget.enabled
          ? (_) {
              _ac.forward(from: 0);
            }
          : null,
      onTapUp: widget.enabled
          ? (_) {
              if (_ac.isAnimating || _ac.value < 1) _ac.reset();
            }
          : null,
      onTapCancel: widget.enabled
          ? () {
              if (_ac.isAnimating || _ac.value < 1) _ac.reset();
            }
          : null,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: LinearProgressIndicator(
                value: _ac.value,
                backgroundColor: Colors.white.withValues(alpha: 0.12),
                color: const Color(0xFFFF3B30),
              ),
            ),
          ),
          Text(
            widget.enabled ? widget.label : '…',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
          ),
        ],
      ),
    );
  }
}
