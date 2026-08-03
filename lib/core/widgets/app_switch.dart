import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppSwitch extends StatefulWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final Color? activeColor;
  final Color? inactiveColor;
  final double width;
  final double height;
  final EdgeInsetsGeometry padding;

  const AppSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.activeColor,
    this.inactiveColor,
    this.width = 50.0,
    this.height = 28.0,
    this.padding = const EdgeInsets.all(2.0),
  });

  @override
  State<AppSwitch> createState() => _AppSwitchState();
}

class _AppSwitchState extends State<AppSwitch> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Alignment> _alignmentAnimation;
  late Animation<Color?> _trackColorAnimation;
  bool _isHovering = false;
  bool _isTapping = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    if (widget.value) {
      _animationController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(AppSwitch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      if (widget.value) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleSwitch() {
    if (widget.onChanged != null) {
      HapticFeedback.lightImpact();
      widget.onChanged!(!widget.value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final defaultActiveColor = theme.primaryColor;
    final defaultInactiveColor = isDark ? Colors.white24 : Colors.black12;

    _alignmentAnimation = AlignmentTween(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInBack,
    ));

    _trackColorAnimation = ColorTween(
      begin: widget.inactiveColor ?? defaultInactiveColor,
      end: widget.activeColor ?? defaultActiveColor,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    final thumbSize = widget.height - widget.padding.horizontal;

    return MouseRegion(
      cursor: widget.onChanged != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isTapping = true),
        onTapUp: (_) {
          setState(() => _isTapping = false);
          _toggleSwitch();
        },
        onTapCancel: () => setState(() => _isTapping = false),
        behavior: HitTestBehavior.opaque,
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            final trackColor = _trackColorAnimation.value;
            final currentThumbWidth = _isTapping ? thumbSize * 1.3 : thumbSize;
            
            return Container(
              width: widget.width,
              height: widget.height,
              padding: widget.padding,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(widget.height / 2),
                color: trackColor,
                boxShadow: _isHovering
                  ? [
                      BoxShadow(
                        color: (widget.activeColor ?? defaultActiveColor).withOpacity(0.15),
                        blurRadius: 8,
                        spreadRadius: 1,
                      )
                    ]
                  : null,
              ),
              child: Stack(
                children: [
                  Align(
                    alignment: _alignmentAnimation.value,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      curve: Curves.easeOut,
                      width: currentThumbWidth,
                      height: thumbSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.rectangle,
                        borderRadius: BorderRadius.circular(thumbSize / 2),
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 1,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
