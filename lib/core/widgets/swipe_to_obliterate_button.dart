import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SwipeToObliterateButton extends StatefulWidget {
  final String title;
  final VoidCallback onConfirmed;
  final bool isLoading;
  final Color activeColor;

  const SwipeToObliterateButton({
    super.key,
    this.title = 'Slide to confirm',
    required this.onConfirmed,
    this.isLoading = false,
    this.activeColor = Colors.redAccent,
  });

  @override
  State<SwipeToObliterateButton> createState() => _SwipeToObliterateButtonState();
}

class _SwipeToObliterateButtonState extends State<SwipeToObliterateButton> with SingleTickerProviderStateMixin {
  double _dragPosition = 0.0;
  bool _isConfirmed = false;
  
  late AnimationController _springController;
  late Animation<double> _springAnimation;
  
  final double _thumbSize = 56.0;
  final double _padding = 6.0;
  
  @override
  void initState() {
    super.initState();
    _springController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _springAnimation = Tween<double>(begin: 0.0, end: 0.0).animate(
      CurvedAnimation(parent: _springController, curve: Curves.elasticOut),
    );
    
    _springController.addListener(() {
      setState(() {
        _dragPosition = _springAnimation.value;
      });
    });
  }
  
  @override
  void dispose() {
    _springController.dispose();
    super.dispose();
  }

  void _onPanUpdate(DragUpdateDetails details, double maxWidth) {
    if (widget.isLoading || _isConfirmed) return;

    final double maxDrag = maxWidth - _thumbSize - (_padding * 2);
    
    setState(() {
      _dragPosition += details.delta.dx;
      if (_dragPosition < 0) _dragPosition = 0;
      if (_dragPosition > maxDrag) _dragPosition = maxDrag;
    });

    if (details.delta.dx.abs() > 2.0) {
       HapticFeedback.selectionClick();
    }
  }

  void _onPanEnd(DragEndDetails details, double maxWidth) {
    if (widget.isLoading || _isConfirmed) return;

    final double maxDrag = maxWidth - _thumbSize - (_padding * 2);
    
    if (_dragPosition >= maxDrag * 0.95) {
      // Confirmed!
      setState(() {
        _dragPosition = maxDrag;
        _isConfirmed = true;
      });
      HapticFeedback.heavyImpact();
      widget.onConfirmed();
    } else {
      // Snap back
      HapticFeedback.lightImpact();
      _springAnimation = Tween<double>(begin: _dragPosition, end: 0.0).animate(
        CurvedAnimation(parent: _springController, curve: Curves.elasticOut),
      );
      _springController.forward(from: 0.0);
    }
  }

  @override
  void didUpdateWidget(covariant SwipeToObliterateButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isLoading && !widget.isLoading) {
      setState(() {
        _isConfirmed = false;
        _dragPosition = 0.0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Differentiate track color from bottom sheet background
    final trackColor = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA);
    // Use a solid white thumb in both modes so it pops against the vibrant red reveal
    final thumbColor = Colors.white; 
    final textColor = isDark ? Colors.white38 : Colors.black38;
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxDrag = constraints.maxWidth - _thumbSize - (_padding * 2);
        final double progress = maxDrag > 0 ? (_dragPosition / maxDrag).clamp(0.0, 1.0) : 0.0;
        
        return Container(
          height: _thumbSize + (_padding * 2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(100),
            color: trackColor,
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
              width: 1,
            ),
          ),
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              // Revealing SOLID vibrant background color from the left (no opacity/muddiness)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: _thumbSize + (_padding * 2) + _dragPosition,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(100),
                    color: widget.activeColor, 
                  ),
                ),
              ),
              
              // Minimalistic Text
              Center(
                child: Opacity(
                  // Fade out quickly so the grey text doesn't overlap the solid red track
                  opacity: (1.0 - progress * 2.5).clamp(0.0, 1.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.title.toUpperCase(),
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // The Solid Thumb
              Positioned(
                left: _padding + _dragPosition,
                child: GestureDetector(
                  onPanUpdate: (details) => _onPanUpdate(details, constraints.maxWidth),
                  onPanEnd: (details) => _onPanEnd(details, constraints.maxWidth),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: _thumbSize,
                    height: _thumbSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: thumbColor,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.3 : 0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: widget.isLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(widget.activeColor),
                              ),
                            )
                          : Icon(
                              _isConfirmed ? Icons.check_rounded : Icons.arrow_forward_ios_rounded,
                              color: widget.activeColor,
                              size: 18,
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
