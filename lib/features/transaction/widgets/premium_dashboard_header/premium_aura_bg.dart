import 'package:flutter/material.dart';
import 'dart:math' as math;

class PremiumAuraBg extends StatefulWidget {
  const PremiumAuraBg({super.key});

  @override
  State<PremiumAuraBg> createState() => _PremiumAuraBgState();
}

class _PremiumAuraBgState extends State<PremiumAuraBg>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _PremiumAuraPainter(
            progress: _controller.value,
            isDark: isDark,
          ),
          child: const SizedBox.expand(),
        );
      },
    );
  }
}

class _PremiumAuraPainter extends CustomPainter {
  final double progress;
  final bool isDark;

  _PremiumAuraPainter({required this.progress, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    
    // Orb 1 (Mint / Teal)
    final double orbit1Angle = progress * 2 * math.pi;
    final Offset center1 = Offset(
      size.width * 0.7 + math.cos(orbit1Angle) * 40,
      size.height * 0.3 + math.sin(orbit1Angle) * 20,
    );
    
    final Paint paint1 = Paint()
      ..shader = RadialGradient(
        colors: [
          isDark 
              ? const Color(0xFF10B981).withValues(alpha: 0.15) 
              : const Color(0xFF10B981).withValues(alpha: 0.08),
          Colors.transparent,
        ],
        radius: 0.9,
      ).createShader(Rect.fromCircle(center: center1, radius: 160));
      
    // Orb 2 (Rose / Purple)
    final double orbit2Angle = (progress + 0.5) * 2 * math.pi;
    final Offset center2 = Offset(
      size.width * 0.85 + math.cos(orbit2Angle) * 50,
      size.height * 0.8 + math.sin(orbit2Angle) * 30,
    );
    
    final Paint paint2 = Paint()
      ..shader = RadialGradient(
        colors: [
          isDark 
              ? const Color(0xFF8B5CF6).withValues(alpha: 0.12) 
              : const Color(0xFF8B5CF6).withValues(alpha: 0.06),
          Colors.transparent,
        ],
        radius: 0.9,
      ).createShader(Rect.fromCircle(center: center2, radius: 180));

    canvas.drawRect(rect, paint1);
    canvas.drawRect(rect, paint2);
  }

  @override
  bool shouldRepaint(covariant _PremiumAuraPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.isDark != isDark;
  }
}
