import 'package:flutter/material.dart';
import 'package:function_tree/function_tree.dart';
import '../theme/app_colors.dart';

class CalculatorPad extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmit;

  const CalculatorPad({
    super.key,
    required this.value,
    required this.onChanged,
    required this.onSubmit,
  });

  bool get _canCalculate {
    // Check if value contains any operators and ends with a digit (simple heuristic)
    final operators = RegExp(r'[+\-*/]');
    return value.contains(operators) &&
        !value.endsWith('+') &&
        !value.endsWith('-') &&
        !value.endsWith('*') &&
        !value.endsWith('/');
  }

  void _handleTap(String text) {
    if (text == 'AC') {
      onChanged('');
    } else if (text.trim() == '⌫') {
      if (value.isNotEmpty) {
        onChanged(value.substring(0, value.length - 1));
      }
    } else if (text == 'OK') {
      onSubmit();
    } else if (text == '=') {
      _calculate();
    } else if (['+', '-', 'x', '÷'].contains(text)) {
      // Prevent duplicate operators
      if (value.isEmpty) return;
      if (_isOperator(value.characters.last)) {
        onChanged(
          '${value.substring(0, value.length - 1)}${_convertDisplayToMath(text)}',
        );
        return;
      }
      onChanged(value + _convertDisplayToMath(text));
    } else {
      // Numbers or dot
      if (text == '.' &&
          value.contains('.') &&
          !_lastNumberSegmentHasDot(value)) {
        // Allow dot if the current number segment explicitly needs it?
        // Simplification: Check last number segment
      }
      onChanged(value + text);
    }
  }

  bool _isOperator(String char) {
    return ['+', '-', '*', '/'].contains(char);
  }

  String _convertDisplayToMath(String text) {
    switch (text) {
      case 'x':
        return '*';
      case '÷':
        return '/';
      default:
        return text;
    }
  }

  bool _lastNumberSegmentHasDot(String val) {
    // rudimentary check: split by operators and check last segment
    final parts = val.split(RegExp(r'[+\-*/]'));
    if (parts.isEmpty) return false;
    return parts.last.contains('.');
  }

  void _calculate() {
    try {
      // function_tree interprets standard math strings
      // Avoid division by zero crash or similar
      final result = value.interpret();

      // Remove trailing .0 if integer
      String resultStr = result.toString();
      if (resultStr.endsWith('.0')) {
        resultStr = resultStr.substring(0, resultStr.length - 2);
      }
      onChanged(resultStr);
    } catch (e) {
      // Ignore invalid expression errors
      debugPrint('Calc error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rowHeight = MediaQuery.of(context).size.height < 700 ? 55.0 : 65.0;

    final backgroundColor = isDark
        ? AppColors.surfaceDark
        : AppColors.surfaceLight;
    final primaryColor = AppColors.primary;
    // Numbers
    final numberTextColor = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;
    // Operators
    final operatorTextColor = AppColors.secondary; // Sky Blue

    // Button Backgrounds (Theme aware)
    final buttonBgColor = isDark ? const Color(0xFF2C2F3E) : Colors.white;
    final operatorBgColor = AppColors.secondary.withOpacity(0.1);
    final dangerBgColor = AppColors.expense.withOpacity(0.1);

    return Container(
      color: backgroundColor,
      padding: const EdgeInsets.fromLTRB(
        12,
        8,
        12,
        30,
      ), // Top padding reduced for drag handle
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20, top: 8),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[700] : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Main Grid (First 4 columns)
              Expanded(
                flex: 4,
                child: Column(
                  children: [
                    _buildRow(
                      ['7', '8', '9', '÷'],
                      rowHeight,
                      numberTextColor,
                      operatorTextColor,
                      buttonBgColor,
                      operatorBgColor,
                    ),
                    const SizedBox(height: 8),
                    _buildRow(
                      ['4', '5', '6', 'x'],
                      rowHeight,
                      numberTextColor,
                      operatorTextColor,
                      buttonBgColor,
                      operatorBgColor,
                    ),
                    const SizedBox(height: 8),
                    _buildRow(
                      ['1', '2', '3', '+'],
                      rowHeight,
                      numberTextColor,
                      operatorTextColor,
                      buttonBgColor,
                      operatorBgColor,
                    ),
                    const SizedBox(height: 8),
                    _buildRow(
                      ['00', '0', '.', '-'],
                      rowHeight,
                      numberTextColor,
                      operatorTextColor,
                      buttonBgColor,
                      operatorBgColor,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // 5th Column
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    _buildButton(
                      'AC',
                      height: rowHeight,
                      color: dangerBgColor,
                      textColor: AppColors.expense,
                      isBold: true,
                      enableShadow: true,
                    ),
                    const SizedBox(height: 8),
                    _buildButton(
                      '⌫ ',
                      height: rowHeight,
                      color: dangerBgColor,
                      textColor: AppColors.expense, // Or secondary text
                      isBold: true,
                      enableShadow: true,
                    ),
                    const SizedBox(height: 8),
                    // Tall Button
                    SizedBox(
                      height: (rowHeight * 2) + 8,
                      child: _buildButton(
                        _canCalculate ? '=' : 'OK',
                        height: (rowHeight * 2) + 8,
                        color: primaryColor, // Fallback
                        gradient: AppColors.primaryGradient, // Gradient Support
                        textColor: Colors.white,
                        isBold: true,
                        enableShadow: true,
                        onTapOverride: () {
                          if (_canCalculate) {
                            _handleTap('=');
                          } else {
                            _handleTap('OK');
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRow(
    List<String> items,
    double height,
    Color numberColor,
    Color operatorColor,
    Color buttonBgColor,
    Color operatorBgColor,
  ) {
    return Row(
      children: items.map((text) {
        final isOperator = ['÷', 'x', '+', '-'].contains(text);

        // Use buttonBgColor for numbers, operatorBgColor for operators
        final btnColor = isOperator ? operatorBgColor : buttonBgColor;

        // Operators now have shadow too, to match the premium feel
        const enableShadow = true;

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: _buildButton(
              text,
              height: height,
              color: btnColor,
              textColor: isOperator ? operatorColor : numberColor,
              isOperator: isOperator,
              enableShadow: enableShadow,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildButton(
    String text, {
    required double height,
    Color? color,
    Gradient? gradient, // New Parameter
    Color? textColor,
    bool isBold = false,
    bool isOperator = false,
    bool enableShadow = false,
    VoidCallback? onTapOverride,
  }) {
    final isPill = text == 'OK' || text == '=';
    final shape = isPill ? BoxShape.rectangle : BoxShape.circle;
    final borderRadius = isPill ? BorderRadius.circular(30) : null;

    final Widget button = Container(
      height: height,
      width: isPill ? null : height, // Force square for circles!
      decoration: BoxDecoration(
        color: color,
        gradient: gradient,
        shape: shape,
        borderRadius: borderRadius,
        boxShadow: enableShadow
            ? [
                BoxShadow(
                  color:
                      (gradient != null ? (color ?? Colors.blue) : Colors.black)
                          .withOpacity(gradient != null ? 0.3 : 0.05),
                  blurRadius: gradient != null ? 8 : 4,
                  offset: gradient != null
                      ? const Offset(0, 4)
                      : const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTapOverride ?? () => _handleTap(text),
          // Ensure ripple is exactly circular for non-pill buttons
          customBorder: isPill
              ? RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))
              : const CircleBorder(),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 24,
                fontWeight: isBold || Utils.isOperator(text)
                    ? FontWeight.bold
                    : FontWeight.w500,
                color: textColor,
              ),
            ),
          ),
        ),
      ),
    );

    // If it's a circle button (not pill), wrap in Center so it doesn't stretch
    // to fill square cells if the cell is rectangular.
    if (!isPill) {
      return Center(child: button);
    }
    return button;
  }
}

class Utils {
  static bool isOperator(String text) {
    return ['÷', 'x', '+', '-', '=', 'AC', '⌫', 'OK'].contains(text);
  }
}
