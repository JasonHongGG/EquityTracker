import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:equity_tracker/core/theme/app_colors.dart';

class PremiumCurrencyPicker extends StatefulWidget {
  final String currentSymbol;
  final ValueChanged<String> onSelected;

  const PremiumCurrencyPicker({
    super.key,
    required this.currentSymbol,
    required this.onSelected,
  });

  static void show(BuildContext context, String currentSymbol, ValueChanged<String> onSelected) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => PremiumCurrencyPicker(
        currentSymbol: currentSymbol,
        onSelected: onSelected,
      ),
    );
  }

  @override
  State<PremiumCurrencyPicker> createState() => _PremiumCurrencyPickerState();
}

class _PremiumCurrencyPickerState extends State<PremiumCurrencyPicker> {
  final List<String> _symbols = ['\$', 'NT\$', '€', '£', '¥', '₩'];
  late String _selectedSymbol;

  @override
  void initState() {
    super.initState();
    _selectedSymbol = widget.currentSymbol;
    if (!_symbols.contains(_selectedSymbol)) {
      _selectedSymbol = _symbols.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.black12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header Row
          Padding(
            padding: const EdgeInsets.only(left: 24, right: 16, top: 12, bottom: 24),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  'SELECT CURRENCY',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white54 : Colors.black54,
                    letterSpacing: 1.5,
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      widget.onSelected(_selectedSymbol);
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark ? Colors.white24 : const Color(0xFF4A5568),
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Micro-Grid Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              children: _symbols.map((sym) {
                final isSelected = sym == _selectedSymbol;
                return _CurrencyChip(
                  symbol: sym,
                  isSelected: isSelected,
                  isDark: isDark,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _selectedSymbol = sym;
                    });
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _CurrencyChip extends StatelessWidget {
  final String symbol;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _CurrencyChip({
    required this.symbol,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    
    // Width calculated to fit 3 items per row with 16px spacing and 24px horizontal padding
    // Screen width - 48 (padding) - 32 (spacing) = remaining space / 3
    final double screenWidth = MediaQuery.of(context).size.width;
    final double chipWidth = (screenWidth - 48 - 32) / 3;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        width: chipWidth,
        height: 56, // Fixed height for elegance
        decoration: BoxDecoration(
          color: isSelected 
              ? primaryColor.withValues(alpha: 0.15)
              : (isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 20,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected 
                  ? primaryColor 
                  : (isDark ? Colors.white70 : Colors.black87),
            ),
            child: Text(symbol),
          ),
        ),
      ),
    );
  }
}
