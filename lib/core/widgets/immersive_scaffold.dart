import 'package:flutter/material.dart';
import 'package:equity_tracker/core/theme/app_colors.dart';

/// A foundational screen container that provides a consistent immersive experience.
/// It encapsulates the Scaffold, standard background colors, and top SafeArea.
/// This widget enforces the "Gesture-Only" minimalist navigation pattern by 
/// explicitly avoiding AppBars and relying on the OS-level gesture navigation.
class ImmersiveScaffold extends StatelessWidget {
  final Widget body;

  const ImmersiveScaffold({
    super.key,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: SafeArea(
        bottom: false,
        child: body,
      ),
    );
  }
}
