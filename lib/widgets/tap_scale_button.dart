import 'package:flutter/material.dart';

/// Wraps a child so it scales down slightly on tap (Figma/Mobbin/Wix micro-interaction).
class TapScaleButton extends StatefulWidget {
  const TapScaleButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.scaleDown = 0.97,
    this.duration = const Duration(milliseconds: 80),
  });

  final VoidCallback? onPressed;
  final Widget child;
  final double scaleDown;
  final Duration duration;

  @override
  State<TapScaleButton> createState() => _TapScaleButtonState();
}

class _TapScaleButtonState extends State<TapScaleButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final scale = _pressed ? widget.scaleDown : 1.0;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: scale,
        duration: widget.duration,
        curve: Curves.easeInOut,
        child: widget.child,
      ),
    );
  }
}
