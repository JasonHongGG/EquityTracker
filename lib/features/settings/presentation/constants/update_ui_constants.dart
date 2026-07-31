import 'package:flutter/material.dart';

class UpdateDialogStyle {
  static ShapeBorder get shape =>
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(24));

  static EdgeInsets get padding => const EdgeInsets.all(28);
  static double get maxWidth => 360;
}

class StatusIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color backgroundColor;

  const StatusIcon({
    super.key,
    required this.icon,
    required this.color,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Icon(icon, size: 36, color: color),
    );
  }
}
