import 'package:flutter/material.dart';
import 'dart:ui';

/// A widget that animates number changes column by column, similar to a slot machine or odometer.
class AnimatedOdometer extends StatelessWidget {
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
  Widget build(BuildContext context) {
    // Ensure tabular figures so digits have fixed widths (prevents jittering during animation)
    final tabularStyle = style.copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    final digitCount = formattedValue.characters.where((c) => int.tryParse(c) != null).length;
    int symbolCount = 0;
    int currentDigitIndex = digitCount;

    return AnimatedSize(
      duration: duration,
      curve: Curves.easeOutCubic,
      alignment: Alignment.centerRight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: formattedValue.split('').map((char) {
          final digit = int.tryParse(char);
          
          if (digit != null) {
            currentDigitIndex--;
            return _RollingDigit(
              key: ValueKey('digit_$currentDigitIndex'),
              digit: digit,
              style: tabularStyle,
              duration: duration,
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
  final TextStyle style;
  final Duration duration;

  const _RollingDigit({
    super.key,
    required this.digit,
    required this.style,
    required this.duration,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      // By supplying begin: 0.0, newly added digits (like hundreds place) will roll from 0 to target
      tween: Tween<double>(begin: 0.0, end: digit.toDouble()),
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
