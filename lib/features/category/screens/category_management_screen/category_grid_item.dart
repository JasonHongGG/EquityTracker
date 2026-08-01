import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:equity_tracker/core/widgets/scale_button.dart';

import 'package:equity_tracker/features/category/screens/category_management_screen/category_delete_dialog.dart';
import 'package:equity_tracker/features/category/data/category_model.dart';

class CategoryGridItem extends StatelessWidget {
  final CategoryModel category;
  final bool isEditMode;

  const CategoryGridItem({
    super.key,
    required this.category,
    required this.isEditMode,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ScaleButton(
          onTap: () {
            if (isEditMode) {
              context.push(
                '/add-category',
                extra: {
                  'categoryToEdit': category,
                  'initialType': category.type,
                },
              );
            }
          },
          // In Normal Mode: Pass null to let ReorderableGridView handle LongPress for drag.
          // In Edit Mode: Consume LongPress to prevent dragging
          onLongPress: isEditMode ? () {} : null,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: category.color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  category.iconData,
                  color: category.color,
                  size: category.iconData.fontPackage == null ? 28 : 24,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                category.name,
                style: TextStyle(
                  fontSize: 12,
                  color: category.color,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),

        // Delete Badge
        if (isEditMode && category.name != 'Other')
          Positioned(
            right: 0,
            top: 0,
            child: GestureDetector(
              onTap: () => CategoryDeleteDialog.show(context, category),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.remove, size: 14, color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }
}
