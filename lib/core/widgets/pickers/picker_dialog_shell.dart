import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PickerBottomSheetShell extends StatelessWidget {
  final String title;
  final Widget child;
  final VoidCallback onConfirm;
  final double contentHeight;
  final bool useShaderMask;
  
  const PickerBottomSheetShell({
    super.key,
    required this.title,
    required this.child,
    required this.onConfirm,
    this.contentHeight = 200,
    this.useShaderMask = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Glassmorphism colors
    final backgroundColor = isDark 
        ? const Color(0xFF1E1E1E).withValues(alpha: 0.8) 
        : Colors.white.withValues(alpha: 0.85);
    final secondaryTextColor = isDark ? Colors.white54 : Colors.black54;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            border: Border(
              top: BorderSide(
                color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.05),
                width: 1,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag Handle
                  Container(
                    width: 48,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),

                  // Header with Title and Done Icon
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Placeholder to keep title perfectly centered
                      const SizedBox(width: 48),
                      
                      // Header Title
                      Text(
                        title.toUpperCase(),
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2.0,
                          color: secondaryTextColor,
                        ),
                      ),

                      // Done Button (Icon)
                      IconButton(
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          onConfirm();
                        },
                        icon: const Icon(Icons.check_circle_rounded),
                        color: theme.primaryColor,
                        iconSize: 28,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 48,
                          minHeight: 48,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),

                  // Content Area
                  SizedBox(
                    height: contentHeight,
                    child: useShaderMask
                        ? ShaderMask(
                            shaderCallback: (Rect bounds) {
                              return LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black,
                                  Colors.black,
                                  Colors.transparent,
                                ],
                                stops: const [0.0, 0.25, 0.75, 1.0],
                              ).createShader(bounds);
                            },
                            blendMode: BlendMode.dstIn,
                            child: child,
                          )
                        : child,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
