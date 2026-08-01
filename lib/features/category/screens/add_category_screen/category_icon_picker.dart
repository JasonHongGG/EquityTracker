import 'package:flutter/material.dart';
import 'package:equity_tracker/features/category/constants/category_constants.dart';

class CategoryIconPicker extends StatelessWidget {
  final int selectedIconCode;
  final Color selectedColor;
  final Function(int codePoint, String? fontFamily, String? fontPackage) onChanged;

  const CategoryIconPicker({
    super.key,
    required this.selectedIconCode,
    required this.selectedColor,
    required this.onChanged,
  });

  void _showIconPicker(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.4,
          maxChildSize: 0.8,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select Icon',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: GridView.builder(
                      controller: scrollController,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 5,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: CategoryConstants.icons.length,
                      itemBuilder: (context, index) {
                        final iconData = CategoryConstants.icons[index];
                        final icon = iconData['icon'] as IconData;
                        final isSelected = selectedIconCode == icon.codePoint;

                        return GestureDetector(
                          onTap: () {
                            onChanged(icon.codePoint, icon.fontFamily, icon.fontPackage);
                            Navigator.pop(context);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? selectedColor.withValues(alpha: 0.2)
                                  : (isDark ? Colors.white10 : Colors.grey.shade100),
                              shape: BoxShape.circle,
                              border: isSelected
                                  ? Border.all(color: selectedColor, width: 2)
                                  : null,
                            ),
                            child: Icon(
                              icon,
                              color: isSelected
                                  ? selectedColor
                                  : (isDark ? Colors.white70 : Colors.black54),
                              size: 24,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ICON',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  color: theme.hintColor,
                ),
              ),
              TextButton(
                onPressed: () => _showIconPicker(context, isDark),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'See All',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: theme.primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: CategoryConstants.icons.take(12).map((iconData) {
              final icon = iconData['icon'] as IconData;
              final isSelected = selectedIconCode == icon.codePoint;
              
              return GestureDetector(
                onTap: () {
                  onChanged(icon.codePoint, icon.fontFamily, icon.fontPackage);
                },
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? selectedColor.withValues(alpha: 0.2)
                        : (isDark ? Colors.white10 : Colors.grey.shade100),
                    borderRadius: BorderRadius.circular(16),
                    border: isSelected
                        ? Border.all(color: selectedColor, width: 2)
                        : null,
                  ),
                  child: Icon(
                    icon,
                    color: isSelected
                        ? selectedColor
                        : (isDark ? Colors.white70 : Colors.black54),
                    size: 24,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
