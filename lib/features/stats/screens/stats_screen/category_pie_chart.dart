import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:equity_tracker/features/stats/domain/category_stat.dart';
import 'package:equity_tracker/core/utils/currency_formatter.dart';
import 'package:equity_tracker/core/enums/transaction_type.dart';

class CategoryPieChart extends StatefulWidget {
  final List<CategoryStat> stats;
  final int totalAmount;
  final String currencySymbol;
  final TransactionType type;

  const CategoryPieChart({
    super.key,
    required this.stats,
    required this.totalAmount,
    required this.currencySymbol,
    required this.type,
  });

  @override
  State<CategoryPieChart> createState() => _CategoryPieChartState();
}

class _CategoryPieChartState extends State<CategoryPieChart> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  int _touchedIndex = -1;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _animationController.forward();
  }

  @override
  void didUpdateWidget(CategoryPieChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-trigger animation if type changes (Expense -> Income)
    if (widget.type != oldWidget.type) {
      _touchedIndex = -1;
      _animationController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTap(Offset localPosition, double size) {
    if (widget.stats.isEmpty) return;

    // Coordinate system: center is (0, 0)
    final center = Offset(size / 2, size / 2);
    final dx = localPosition.dx - center.dx;
    final dy = localPosition.dy - center.dy;
    final distance = math.sqrt(dx * dx + dy * dy);

    // Hit test radii: inner hole is 65, stroke is 45, max radius is ~110.
    // If touched slice is expanded, radius goes up to 115.
    if (distance < 65 || distance > 120) {
      setState(() => _touchedIndex = -1);
      return;
    }

    // atan2 returns angle between -pi and pi. 
    // Right (3 o'clock) is 0, Bottom is pi/2, Top is -pi/2, Left is pi.
    double touchAngle = math.atan2(dy, dx); 
    
    // Normalize to [0, 2*pi] starting from the top (12 o'clock), 
    // because our CustomPainter starts drawing at -pi/2.
    touchAngle += math.pi / 2;
    if (touchAngle < 0) touchAngle += 2 * math.pi;

    final sortedData = List<CategoryStat>.from(widget.stats)
      ..sort((a, b) => b.totalAmount.compareTo(a.totalAmount));

    double currentAngle = 0.0;
    for (int i = 0; i < sortedData.length; i++) {
      final stat = sortedData[i];
      final sweepAngle = (stat.totalAmount / widget.totalAmount) * 2 * math.pi;
      
      // Check if touch falls within this slice
      if (touchAngle >= currentAngle && touchAngle <= currentAngle + sweepAngle) {
        setState(() {
          // Toggle off if clicking the same slice, otherwise select the new one
          _touchedIndex = (_touchedIndex == i) ? -1 : i;
        });
        return;
      }
      currentAngle += sweepAngle;
    }
    
    setState(() => _touchedIndex = -1);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final sortedData = List<CategoryStat>.from(widget.stats)
      ..sort((a, b) => b.totalAmount.compareTo(a.totalAmount));

    // ==========================================
    // CENTER WIDGET LOGIC
    // ==========================================
    Widget centerWidget;
    if (_touchedIndex == -1 || _touchedIndex >= sortedData.length) {
      // Default: Show Type & Total
      centerWidget = Column(
        key: const ValueKey('total'),
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.type == TransactionType.expense ? 'Expense' : 'Income',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white54 : Colors.black54,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            CurrencyFormatter.format(widget.totalAmount, widget.currencySymbol),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ],
      );
    } else {
      // Touched: Show Category Details
      final touchedStat = sortedData[_touchedIndex];
      final percentage = touchedStat.percentage * 100;
      
      centerWidget = Column(
        key: ValueKey('touched_$_touchedIndex'),
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8, height: 8,
                decoration: BoxDecoration(
                  color: touchedStat.category.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  touchedStat.category.name,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white54 : Colors.black54,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            CurrencyFormatter.format(touchedStat.totalAmount, widget.currencySymbol),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${percentage.toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 13,
              color: touchedStat.category.color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Use a consistent bounding box for the chart
        final size = math.min(constraints.maxWidth, 240.0); 
        
        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // NATIVE CUSTOM PAINTER DRAWING ENGINE
              GestureDetector(
                onTapUp: (details) => _handleTap(details.localPosition, size),
                behavior: HitTestBehavior.opaque,
                child: AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    return CustomPaint(
                      size: Size(size, size),
                      painter: DonutChartPainter(
                        stats: sortedData,
                        totalAmount: widget.totalAmount,
                        touchedIndex: _touchedIndex,
                        animationValue: _animation.value,
                        isDark: isDark,
                      ),
                    );
                  },
                ),
              ),
              
              // Animated Center Text
              IgnorePointer(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  switchInCurve: Curves.easeIn,
                  switchOutCurve: Curves.easeOut,
                  child: centerWidget,
                ),
              ),
            ],
          ),
        );
      }
    );
  }
}

// ============================================================================
// CORE DRAWING ENGINE: REPLACES fl_chart FOR PERFECT MATH & PERFORMANCE
// ============================================================================
class DonutChartPainter extends CustomPainter {
  final List<CategoryStat> stats;
  final int totalAmount;
  final int touchedIndex;
  final double animationValue;
  final bool isDark;

  DonutChartPainter({
    required this.stats,
    required this.totalAmount,
    required this.touchedIndex,
    required this.animationValue,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    
    const innerRadius = 65.0; // Hole size
    const baseStrokeWidth = 45.0; // Ring thickness
    
    // In Canvas, drawArc is based on the center of the stroke
    final drawRadius = innerRadius + (baseStrokeWidth / 2);
    final rect = Rect.fromCircle(center: center, radius: drawRadius);
    
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.butt; // Flat edges for classic donut look

    // ==================================
    // 1. EMPTY STATE RENDERING
    // ==================================
    if (stats.isEmpty || totalAmount == 0) {
      paint.color = isDark ? Colors.grey.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.2);
      paint.strokeWidth = baseStrokeWidth;
      // Animate the empty ring too for a consistent premium feel
      canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * animationValue, false, paint);
      return;
    }

    // ==================================
    // 2. DATA SLICES RENDERING
    // ==================================
    // Tiny gap between slices for elegance
    final double gapAngle = stats.length > 1 ? 0.03 : 0.0;
    
    // Start drawing from 12 o'clock (-90 degrees)
    double startAngle = -math.pi / 2;
    
    // Total sweep permitted at this frame of the animation
    double remainingSweepToDraw = 2 * math.pi * animationValue;

    for (int i = 0; i < stats.length; i++) {
      if (remainingSweepToDraw <= 0) break;

      final stat = stats[i];
      final isTouched = i == touchedIndex;
      
      // Geometric percentage of the circle
      final categorySweep = (stat.totalAmount / totalAmount) * 2 * math.pi;
      
      // Actual drawn arc (subtract gap). Prevent negative sweep if a slice is microscopically small.
      double arcSweep = categorySweep - gapAngle;
      if (arcSweep < 0) arcSweep = categorySweep; 
      
      // Calculate how much of this slice we are allowed to draw right now
      double sweepToDraw = math.min(arcSweep, remainingSweepToDraw);

      paint.color = stat.category.color;
      
      // Enlargement logic when a user taps a slice
      if (isTouched) {
        paint.strokeWidth = baseStrokeWidth + 10.0;
        final touchedDrawRadius = innerRadius + (paint.strokeWidth / 2);
        final touchedRect = Rect.fromCircle(center: center, radius: touchedDrawRadius);
        canvas.drawArc(touchedRect, startAngle, sweepToDraw, false, paint);
      } else {
        paint.strokeWidth = baseStrokeWidth;
        canvas.drawArc(rect, startAngle, sweepToDraw, false, paint);
      }

      // Advance our drawing cursor by the FULL category sweep (including the gap)
      startAngle += categorySweep;
      // Consume the sweep budget
      remainingSweepToDraw -= categorySweep;
    }
  }

  @override
  bool shouldRepaint(covariant DonutChartPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
           oldDelegate.touchedIndex != touchedIndex ||
           oldDelegate.isDark != isDark ||
           oldDelegate.totalAmount != totalAmount ||
           oldDelegate.stats != stats;
  }
}
