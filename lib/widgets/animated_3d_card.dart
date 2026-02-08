import 'package:flutter/material.dart';

/// Card with subtle 3D tilt on hover (web/desktop). Uses perspective and rotateX/Y.
class Animated3DCard extends StatefulWidget {
  const Animated3DCard({
    super.key,
    required this.child,
    this.borderRadius,
    this.padding = const EdgeInsets.all(24),
  });

  final Widget child;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry padding;

  @override
  State<Animated3DCard> createState() => _Animated3DCardState();
}

class _Animated3DCardState extends State<Animated3DCard> {
  double _tiltX = 0;
  double _tiltY = 0;

  static const double _perspective = 0.0012;
  static const double _maxTilt = 0.12;

  void _onHover(PointerEvent e) {
    if (!mounted) return;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    final size = box.size;
    final pos = box.globalToLocal(e.position);
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final dy = (pos.dy - centerY) / centerY;
    final dx = (pos.dx - centerX) / centerX;
    setState(() {
      _tiltY = dx * _maxTilt;
      _tiltX = -dy * _maxTilt;
    });
  }

  void _onExit(PointerEvent e) {
    setState(() {
      _tiltX = 0;
      _tiltY = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderRadius = widget.borderRadius ?? BorderRadius.circular(24);

    return MouseRegion(
      onHover: _onHover,
      onExit: _onExit,
      child: Transform(
        transform: Matrix4.identity()
          ..setEntry(3, 2, _perspective)
          ..rotateX(_tiltX)
          ..rotateY(_tiltY),
        alignment: Alignment.center,
        child: Container(
          padding: widget.padding,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: borderRadius,
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.06),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
              BoxShadow(
                color: theme.colorScheme.shadow.withValues(alpha: 0.08),
                blurRadius: 32,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
