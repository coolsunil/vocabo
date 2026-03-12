import 'package:flutter/material.dart';

class InteractivePressable extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final BorderRadius borderRadius;
  final Color? overlayColor;
  final double hoverScale;
  final double pressScale;

  const InteractivePressable({
    super.key,
    required this.child,
    required this.onTap,
    required this.borderRadius,
    this.overlayColor,
    this.hoverScale = 1.015,
    this.pressScale = 0.985,
  });

  @override
  State<InteractivePressable> createState() => _InteractivePressableState();
}

class _InteractivePressableState extends State<InteractivePressable> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final scale =
        _pressed ? widget.pressScale : (_hovered ? widget.hoverScale : 1.0);

    return AnimatedScale(
      scale: scale,
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOutCubic,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: widget.borderRadius,
          onTap: widget.onTap,
          onHover: (value) => setState(() => _hovered = value),
          onHighlightChanged: (value) => setState(() => _pressed = value),
          mouseCursor: SystemMouseCursors.click,
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return (widget.overlayColor ?? Colors.black).withValues(
                alpha: 0.12,
              );
            }
            if (states.contains(WidgetState.hovered)) {
              return (widget.overlayColor ?? Colors.black).withValues(
                alpha: 0.06,
              );
            }
            return null;
          }),
          child: widget.child,
        ),
      ),
    );
  }
}
