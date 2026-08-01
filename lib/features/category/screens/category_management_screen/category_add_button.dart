import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:equity_tracker/core/widgets/scale_button.dart';

class CategoryAddButton extends StatelessWidget {
  final bool isEditMode;

  const CategoryAddButton({super.key, required this.isEditMode});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    Widget button = ScaleButton(
      onTap: () {
        if (isEditMode) return;
        context.push('/add-category');
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isDark ? Colors.white10 : Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.add_rounded, color: Colors.grey, size: 28),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );

    if (isEditMode) {
      return Opacity(
        opacity: 0.3,
        child: button,
      );
    }

    return button;
  }
}
