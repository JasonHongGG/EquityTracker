import 'package:flutter/material.dart';
import 'package:equity_tracker/features/ai/presentation/widgets/thinking_orb.dart';

class PremiumConfigHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? trailing;

  const PremiumConfigHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Decorative Orb
          Positioned(
            right: -15,
            top: -10,
            bottom: -10,
            child: Align(
              alignment: Alignment.centerRight,
              child: Opacity(
                opacity: 0.15,
                child: IgnorePointer(
                  child: ThinkingOrb(
                    size: 150,
                    isDark: isDark,
                  ),
                ),
              ),
            ),
          ),
          
          // Content
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : Colors.black87,
                        letterSpacing: -0.5,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white54 : Colors.black54,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 16),
                trailing!,
              ],
            ],
          ),
        ],
      ),
    );
  }
}
