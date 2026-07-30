import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:equity_tracker/core/theme/app_colors.dart';

class BlankScreen extends StatelessWidget {
  const BlankScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            FontAwesomeIcons.gear,
            color: isDark ? Colors.white70 : Colors.black54,
            size: 20,
          ),
          onPressed: () {
            context.push('/settings');},
        ),
      ),
      body: Center(
        child: Text(
          'Coming Soon',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
      ),
    );
  }
}
