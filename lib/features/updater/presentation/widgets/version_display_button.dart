import 'package:flutter/material.dart';

class VersionDisplayButton extends StatelessWidget {
  final String version;
  final VoidCallback onTap;

  const VersionDisplayButton({
    super.key,
    required this.version,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'Version $version',
            style: TextStyle(
              color: isDark ? Colors.white38 : Colors.black38,
              fontFamily: 'Outfit',
            ),
          ),
        ),
      ),
    );
  }
}
