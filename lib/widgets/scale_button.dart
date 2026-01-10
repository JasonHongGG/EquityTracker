import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ScaleButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onPressed;
  final Duration duration;
  final double scale;
  final bool enableFeedback;

  const ScaleButton({
    super.key,
    required this.child,
    this.onTap,
    this.onPressed,
    this.duration = const Duration(milliseconds: 100),
    this.scale = 0.96,
    this.enableFeedback = true,
  });

  @override
  State<ScaleButton> createState() => _ScaleButtonState();
}

class _ScaleButtonState extends State<ScaleButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
      lowerBound: 0.0,
      upperBound: 1.0,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.scale,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onTap != null || widget.onPressed != null) {
      _controller.forward();
      if (widget.enableFeedback) {
        HapticFeedback.selectionClick();
      }
    }
  }

  void _onTapUp(TapUpDetails details) {
    final callback = widget.onTap ?? widget.onPressed;
    if (callback != null) {
      _controller.reverse();
      callback();
    }
  }

  void _onTapCancel() {
    if (widget.onTap != null || widget.onPressed != null) {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(scale: _scaleAnimation, child: widget.child),
    );
  }
}
