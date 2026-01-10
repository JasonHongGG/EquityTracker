import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'scale_button.dart';

Future<TimeOfDay?> showCustomTimePicker({
  required BuildContext context,
  required TimeOfDay initialTime,
}) {
  return showDialog<TimeOfDay>(
    context: context,
    builder: (context) => CustomTimePicker(initialTime: initialTime),
  );
}

class CustomTimePicker extends StatefulWidget {
  final TimeOfDay initialTime;

  const CustomTimePicker({super.key, required this.initialTime});

  @override
  State<CustomTimePicker> createState() => _CustomTimePickerState();
}

class _CustomTimePickerState extends State<CustomTimePicker>
    with SingleTickerProviderStateMixin {
  late TimeOfDay _selectedTime;
  bool _isHourView = true; // true = Hour, false = Minute
  late AnimationController _animController;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _selectedTime = widget.initialTime;
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _anim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _updateTimeFromAngle(double angle, bool isHour) {
    // Normalize angle to 0..2PI starting from 12 o'clock (top)
    // Canvas coords: 0 is right (3 o'clock).
    // Touch angle needs strictly mathematical conversion.
    // Atan2 returns angle from X axis.
    // 3 o'clock = 0, 12 o'clock = -PI/2.

    // We want 12 to be top.
    double normalized = angle + pi / 2;
    if (normalized < 0) normalized += 2 * pi;

    // Now normalized is 0 at 12 o'clock, increasing clockwise.
    double totalSegments = isHour ? 12 : 60;
    double segmentAngle = 2 * pi / totalSegments;

    int value = (normalized / segmentAngle).round() % totalSegments.toInt();
    if (isHour) {
      if (value == 0) value = 12;
      // Handle AM/PM logic if 24h needed, but for 12h picker we just set logical hour
      // But TimeOfDay stores 0-23.
      // We are just picking the visual hour 1-12.
      // We need to preserve the AM/PM offset.
      final wasPm = _selectedTime.period == DayPeriod.pm;
      if (value == 12) {
        // 12 is 0 or 12 depending on AM/PM
        _selectedTime = _selectedTime.replacing(hour: wasPm ? 12 : 0);
      } else {
        _selectedTime = _selectedTime.replacing(
          hour: wasPm ? value + 12 : value,
        );
      }
    } else {
      _selectedTime = _selectedTime.replacing(minute: value);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.primaryColor;
    final bg = isDark ? const Color(0xFF1E1E2C) : Colors.white;
    final text = isDark ? Colors.white : Colors.black87;
    final inactiveText = isDark ? Colors.white38 : Colors.black38;

    // Formatting
    final hour = _selectedTime.hourOfPeriod == 0
        ? 12
        : _selectedTime.hourOfPeriod;
    final minute = _selectedTime.minute.toString().padLeft(2, '0');
    final isPm = _selectedTime.period == DayPeriod.pm;

    return Dialog(
      backgroundColor: bg,
      elevation: 10,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Container(
        width: 320,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // --- HEADER ---
            // --- HEADER ---
            // --- HEADER ---
            SizedBox(
              height: 60, // Fixed height for header alignment
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // 1. Centered Time Display
                  SizedBox(
                    width: double.infinity,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: GestureDetector(
                              onTap: () {
                                if (!_isHourView) {
                                  setState(() => _isHourView = true);
                                  _animController.forward(from: 0);
                                }
                              },
                              child: Text(
                                hour.toString().padLeft(2, '0'),
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 44,
                                  height: 1,
                                  fontWeight: FontWeight.bold,
                                  color: _isHourView ? primary : text,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Text(
                          ":",
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 44,
                            height: 1,
                            color: text,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: GestureDetector(
                              onTap: () {
                                if (_isHourView) {
                                  setState(() => _isHourView = false);
                                  _animController.forward(from: 0);
                                }
                              },
                              child: Text(
                                minute,
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 44,
                                  height: 1,
                                  fontWeight: FontWeight.bold,
                                  color: !_isHourView ? primary : text,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 2. Absolute Right AM/PM Toggle
                  Positioned(
                    right: 0,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isPm) {
                            _selectedTime = _selectedTime.replacing(
                              hour: _selectedTime.hour - 12,
                            );
                          } else {
                            _selectedTime = _selectedTime.replacing(
                              hour: _selectedTime.hour + 12,
                            );
                          }
                        });
                        HapticFeedback.selectionClick();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: primary.withAlpha(25),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: primary.withAlpha(50),
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          isPm ? "PM" : "AM",
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 13, // Slightly smaller
                            fontWeight: FontWeight.bold,
                            color: primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 0),

            // --- CLOCK FACE ---
            SizedBox(
              height: 260,
              width: 260,
              child: AnimatedBuilder(
                animation: _anim,
                builder: (context, child) {
                  // Subtle scale/fade transition could go here
                  return GestureDetector(
                    onPanUpdate: (details) {
                      _handlePan(details.localPosition, 260);
                    },
                    onTapUp: (details) {
                      _handlePan(details.localPosition, 260);
                      // Auto-advance logic could go here
                      if (_isHourView) {
                        Future.delayed(const Duration(milliseconds: 300), () {
                          if (mounted) {
                            setState(() => _isHourView = false);
                            _animController.forward(from: 0);
                          }
                        });
                      }
                    },
                    child: CustomPaint(
                      painter: _ClockPainter(
                        selectedTime: _selectedTime,
                        isHourView: _isHourView,
                        primaryColor: primary,
                        textColor: text,
                        isDark: isDark,
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 0),
            // --- ACTIONS ---
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    "Cancel",
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 16,
                      color: inactiveText,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ScaleButton(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    Navigator.pop(context, _selectedTime);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: primary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      "OK",
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handlePan(Offset local, double size) {
    // Center is size/2, size/2
    final center = Offset(size / 2, size / 2);
    final dx = local.dx - center.dx;
    final dy = local.dy - center.dy;
    final angle = atan2(dy, dx);
    _updateTimeFromAngle(angle, _isHourView);
  }
}

class _ClockPainter extends CustomPainter {
  final TimeOfDay selectedTime;
  final bool isHourView;
  final Color primaryColor;
  final Color textColor;
  final bool isDark;

  _ClockPainter({
    required this.selectedTime,
    required this.isHourView,
    required this.primaryColor,
    required this.textColor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final faceRadius = radius - 4; // Slight padding

    // 1. Draw Face Background
    final bgPaint = Paint()
      ..color = isDark ? Colors.white.withAlpha(13) : Colors.grey.shade100
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, faceRadius, bgPaint);

    // Center Dot
    canvas.drawCircle(center, 4, Paint()..color = primaryColor);

    // 2. Determine Value
    int value;
    int max;
    if (isHourView) {
      value = selectedTime.hourOfPeriod == 0 ? 12 : selectedTime.hourOfPeriod;
      max = 12;
    } else {
      value = selectedTime.minute;
      max = 60;
    }

    // 3. Draw Hand
    // Calculate Angle
    // 12 o'clock is -PI/2
    double angleStep = 2 * pi / max;
    double angle = (value * angleStep) - (pi / 2);
    // For minutes, 0 is at top, which corresponds to angle 0?
    // Wait, Minute 0 should vary.
    // Logic:
    // If max=12 (Hours), 12 is at Top. 12 * step = 2PI. Top is -PI/2 in Canvas.
    // So angle = (value * 2PI / 12) - PI/2.
    // If value=12, angle = 2PI - PI/2 = 3PI/2 (Top). Correct.
    // If value=3, angle = PI/2 - PI/2 = 0 (Right). Correct.

    // If max=60 (Minutes), 0 is at Top.
    // If value=0. Angle should be -PI/2.
    // Formula: (0 * 2PI/60) - PI/2 = -PI/2. Correct.
    // If value=15. Angle should be 0.
    // (15 * 2PI/60) - PI/2 = PI/2 - PI/2 = 0. Correct.

    final handLength = faceRadius * 0.75;
    final handEnd = Offset(
      center.dx + handLength * cos(angle),
      center.dy + handLength * sin(angle),
    );

    // Hand Line
    final handPaint = Paint()
      ..color = primaryColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(center, handEnd, handPaint);

    // Hand Tip Circle
    final tipPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(handEnd, 16, tipPaint); // Selection Circle at tip

    // Small dot at tip center (optional contrast)
    canvas.drawCircle(handEnd, 4, Paint()..color = Colors.white);

    // 4. Draw Numbers
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    int step = isHourView ? 1 : 5; // Show every 5 mins
    for (int i = isHourView ? 1 : 0; i < (isHourView ? 13 : 60); i += step) {
      if (!isHourView && i == 0) {
        // We handle 0 usually at the '60' spot for drawing, or just draw '00'
        // Convention: draw '00' at top.
      }

      // Calculate pos
      // i=12 (hour) -> -PI/2
      // i=0 (min) -> -PI/2
      // numVal removed as it was unused and handled below by 'i'
      // double numVal = i.toDouble();
      // if (isHourView && i == 12) numVal = 0; // for math? No 12 is 12 segments.

      // angle for number position
      // Same logic as hand
      double numAngle;
      if (isHourView) {
        numAngle = (i * 2 * pi / 12) - (pi / 2);
      } else {
        numAngle = (i * 2 * pi / 60) - (pi / 2);
      }

      final dist = faceRadius * 0.75; // Same as hand length effectively
      final dx = center.dx + dist * cos(numAngle);
      final dy = center.dy + dist * sin(numAngle);

      final isSelected =
          (i == value) ||
          (!isHourView && i == 0 && value == 0); // Special 0 case

      String textLabel = i.toString();
      if (!isHourView && i == 0) textLabel = "00";

      textPainter.text = TextSpan(
        text: textLabel,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: isSelected ? 18 : 16, // Zoom active
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: isSelected ? Colors.white : textColor,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(dx - textPainter.width / 2, dy - textPainter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ClockPainter oldDelegate) {
    return oldDelegate.selectedTime != selectedTime ||
        oldDelegate.isHourView != isHourView;
  }
}
