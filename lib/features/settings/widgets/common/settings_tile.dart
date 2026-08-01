import 'package:flutter/material.dart';

class SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool isDestructive;

  const SettingsTile({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final textColor = isDestructive
        ? Colors.redAccent
        : (isDark ? Colors.white : const Color(0xFF1A1D2B));

    final iconBgColor = isDestructive
        ? Colors.redAccent.withValues(alpha: 0.1)
        : iconColor.withValues(alpha: 0.15);

    final displayIconColor = isDestructive ? Colors.redAccent : iconColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(
          16,
        ), // Match section radius technically, but clipped by parent
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Icon Bubble
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 20, color: displayIconColor),
              ),
              const SizedBox(width: 16),

              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: textColor,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 12,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Trailing
              if (trailing != null) ...[
                const SizedBox(width: 8),
                trailing!,
              ] else if (onTap != null) ...[
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: isDark ? Colors.white30 : Colors.black26,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
