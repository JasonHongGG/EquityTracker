import 'package:flutter/material.dart';
import 'package:equity_tracker/features/category/presentation/widgets/add_category_screen/category_constants.dart';

class CategoryColorPicker extends StatelessWidget {
  final Color selectedColor;
  final ValueChanged<Color> onChanged;

  const CategoryColorPicker({
    super.key,
    required this.selectedColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'COLOR',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
              color: theme.hintColor,
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 56,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            scrollDirection: Axis.horizontal,
            itemCount: CategoryConstants.colors.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final color = CategoryConstants.colors[index];
              final isSelected = selectedColor.value == color.value;
              
              return GestureDetector(
                onTap: () => onChanged(color),
                child: Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: color.withOpacity(0.5),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 24,
                          )
                        : null,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
