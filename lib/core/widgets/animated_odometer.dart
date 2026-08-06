import 'package:flutter/material.dart';
import 'dart:ui';

/// A widget that animates number changes column by column, similar to a slot machine or odometer.
class AnimatedOdometer extends StatefulWidget {
  final String formattedValue;
  final TextStyle style;
  final Duration duration;

  const AnimatedOdometer({
    super.key,
    required this.formattedValue,
    required this.style,
    this.duration = const Duration(milliseconds: 600),
  });

  @override
  State<AnimatedOdometer> createState() => _AnimatedOdometerState();
}

class _AnimatedOdometerState extends State<AnimatedOdometer> {
  int _spinCount = 0;

  @override
  void didUpdateWidget(covariant AnimatedOdometer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.formattedValue != widget.formattedValue) {
      _spinCount++;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ensure tabular figures so digits have fixed widths (prevents jittering during animation)
    final tabularStyle = widget.style.copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    final digitCount = widget.formattedValue.characters.where((c) => int.tryParse(c) != null).length;
    int symbolCount = 0;
    int currentDigitIndex = digitCount;

    return AnimatedSize(
      duration: widget.duration,
      curve: Curves.easeOutCubic,
      alignment: Alignment.centerRight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: widget.formattedValue.split('').map((char) {
          final digit = int.tryParse(char);
          
          if (digit != null) {
            currentDigitIndex--;
            
            // Stagger index: 0 for the left-most digit, increasing to the right
            final staggerIndex = digitCount - 1 - currentDigitIndex;
            // Add a slight delay to the duration for each subsequent digit to create a slot-machine stopping effect
            final staggeredDuration = widget.duration + Duration(milliseconds: staggerIndex * 150);

            return _RollingDigit(
              key: ValueKey('digit_$currentDigitIndex'),
              digit: digit,
              spinCount: _spinCount,
              style: tabularStyle,
              duration: staggeredDuration,
            );
          } else {
            final symIndex = symbolCount++;
            return AnimatedSwitcher(
              key: ValueKey('symbol_$symIndex'),
              duration: const Duration(milliseconds: 200),
              child: Text(
                char,
                key: ValueKey(char),
                style: tabularStyle,
              ),
            );
          }
        }).toList(),
      ),
    );
  }
}

class _RollingDigit extends StatelessWidget {
  final int digit;
  final int spinCount;
  final TextStyle style;
  final Duration duration;

  const _RollingDigit({
    super.key,
    required this.digit,
    required this.spinCount,
    required this.style,
    required this.duration,
  });

  @override
  Widget build(BuildContext context) {
    // Target adds 10 for every spin cycle so it ALWAYS rolls forward, even if the digit is the same
    final targetValue = (spinCount * 10) + digit;
    // For newly mounted digits, start them 1 cycle behind so they spin exactly into place
    final beginValue = spinCount == 0 ? 0.0 : ((spinCount - 1) * 10).toDouble();

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: beginValue, end: targetValue.toDouble()),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        final whole = value.floor();
        final decimal = value - whole;

        final currentDigit = whole % 10;
        final nextDigit = (whole + 1) % 10;

        return ClipRect(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Hidden placeholder to size the Stack to the widest possible digit
              Opacity(
                opacity: 0,
                child: Text('0', style: style),
              ),
              Positioned(
                top: 0,
                bottom: 0,
                left: 0,
                right: 0,
                child: FractionalTranslation(
                  translation: Offset(0, -decimal),
                  child: Center(child: Text(currentDigit.toString(), style: style)),
                ),
              ),
              Positioned(
                top: 0,
                bottom: 0,
                left: 0,
                right: 0,
                child: FractionalTranslation(
                  translation: Offset(0, 1.0 - decimal),
                  child: Center(child: Text(nextDigit.toString(), style: style)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
