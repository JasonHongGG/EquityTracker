import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class InlineDeleteButton extends StatefulWidget {
  final VoidCallback onDelete;

  const InlineDeleteButton({
    super.key,
    required this.onDelete,
  });

  @override
  State<InlineDeleteButton> createState() => _InlineDeleteButtonState();
}

class _InlineDeleteButtonState extends State<InlineDeleteButton> with SingleTickerProviderStateMixin {
  bool _isConfirming = false;
  late AnimationController _controller;
  late Animation<double> _widthAnimation;
  late Animation<Color?> _colorAnimation;
  late Animation<Color?> _borderColorAnimation;
  late Animation<double> _contentOpacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _widthAnimation = Tween<double>(begin: 40.0, end: 150.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Explicitly interpolate from a transparent version of the target color to prevent grayish/white flashes
    final activeColor = isDark ? const Color(0xFF2A1515) : const Color(0xFFFDE8E8);
    final transparentColor = activeColor.withValues(alpha: 0.0);

    _colorAnimation = ColorTween(
      begin: transparentColor,
      end: activeColor,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _borderColorAnimation = ColorTween(
      begin: Colors.red.withValues(alpha: 0.0),
      end: Colors.red.withValues(alpha: 0.3),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    // Delays the fade-in of the buttons until the pill has expanded halfway
    _contentOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleConfirm() {
    HapticFeedback.selectionClick();
    setState(() {
      _isConfirming = !_isConfirming;
      if (_isConfirming) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  void _handleDelete() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isConfirming = false;
      _controller.reverse();
    });
    widget.onDelete();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          height: 40,
          width: _widthAnimation.value,
          decoration: BoxDecoration(
            color: _colorAnimation.value,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _borderColorAnimation.value ?? Colors.transparent, 
              width: 1
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              child: SizedBox(
                width: _widthAnimation.value,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Initial Trash Icon
                    IgnorePointer(
                      ignoring: _isConfirming,
                      child: Opacity(
                        // Fades out in the first 40% of the animation
                        opacity: (1.0 - (_controller.value / 0.4)).clamp(0.0, 1.0),
                        child: InkWell(
                          onTap: _toggleConfirm,
                          borderRadius: BorderRadius.circular(20),
                          child: const SizedBox(
                            width: 40,
                            height: 40,
                            child: Center(
                              child: Icon(
                                Icons.delete_outline_rounded,
                                color: Colors.redAccent,
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    // Expanded Confirm State
                    IgnorePointer(
                      ignoring: !_isConfirming,
                      child: Opacity(
                        opacity: _contentOpacityAnimation.value,
                        child: SizedBox(
                          width: 150.0,
                          height: 40,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              const Text(
                                'Delete?',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.redAccent,
                                ),
                              ),
                              // Cancel Button
                              GestureDetector(
                                onTap: _toggleConfirm,
                                behavior: HitTestBehavior.opaque,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close_rounded, size: 16, color: Colors.redAccent),
                                ),
                              ),
                              // Confirm Button
                              GestureDetector(
                                onTap: _handleDelete,
                                behavior: HitTestBehavior.opaque,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.redAccent,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.check_rounded, size: 16, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
