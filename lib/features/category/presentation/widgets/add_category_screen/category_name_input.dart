import 'package:flutter/material.dart';

class CategoryNameInput extends StatelessWidget {
  final TextEditingController controller;

  const CategoryNameInput({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CATEGORY NAME',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
            color: theme.hintColor,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: const TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
          decoration: InputDecoration(
            hintText: 'e.g. Groceries',
            hintStyle: TextStyle(
              fontFamily: 'Outfit',
              color: theme.hintColor.withValues(alpha: 0.5),
              fontWeight: FontWeight.normal,
            ),
            filled: true,
            fillColor: isDark
                ? Colors.grey[800]!.withValues(alpha: 0.5)
                : Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: theme.primaryColor,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }
}
