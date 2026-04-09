import 'package:flutter/material.dart';

import '../theme/motion_tokens.dart';

class PressEffect extends StatefulWidget {
  const PressEffect({
    super.key,
    required this.child,
    this.scale = 0.97,
    this.onTap,
    this.borderRadius,
  });

  final Widget child;
  final double scale;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;

  @override
  State<PressEffect> createState() => _PressEffectState();
}

class _PressEffectState extends State<PressEffect> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MotionTokens.reduceMotion(context);
    final scale = (_pressed && !reduce) ? widget.scale : 1.0;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _setPressed(true),
      onTapCancel: () => _setPressed(false),
      onTapUp: (_) => _setPressed(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: scale,
        duration: MotionTokens.duration(context, MotionTokens.fast),
        curve: MotionTokens.easeOut,
        child: ClipRRect(
          borderRadius: widget.borderRadius ?? BorderRadius.zero,
          child: widget.child,
        ),
      ),
    );
  }
}
