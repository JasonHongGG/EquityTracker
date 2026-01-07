import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';
import '../models/category_model.dart';
import '../models/transaction_type.dart';
import '../providers/category_provider.dart';
import '../theme/app_colors.dart';
import 'add_category_screen.dart';

class CategoryManagementScreen extends ConsumerStatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  ConsumerState<CategoryManagementScreen> createState() =>
      _CategoryManagementScreenState();
}

class _CategoryManagementScreenState
    extends ConsumerState<CategoryManagementScreen> {
  TransactionType _selectedType = TransactionType.expense;
  bool _isEditMode = false;

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoryListProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F111A)
          : const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Manage Categories',
          style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _isEditMode = !_isEditMode;
              });
            },
            icon: Icon(
              _isEditMode ? Icons.check : Icons.edit,
              color: theme.primaryColor,
            ),
            tooltip: _isEditMode ? 'Done' : 'Edit',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Custom Toggle
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : Colors.grey[200],
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTypeButton(TransactionType.expense, 'Expense'),
                    _buildTypeButton(TransactionType.income, 'Income'),
                  ],
                ),
              ),
            ),
          ),

          // Grid
          Expanded(
            child: categoriesAsync.when(
              data: (categories) {
                final filteredCats = categories
                    .where((c) => c.type == _selectedType)
                    .toList();

                return _buildCategoryGrid(
                  context,
                  filteredCats,
                  _selectedType,
                  _isEditMode,
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeButton(TransactionType type, String label) {
    final isSelected = _selectedType == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedType = type;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? (type == TransactionType.income
                    ? AppColors.income
                    : AppColors.expense)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey,
            fontWeight: FontWeight.bold,
            fontFamily: 'Outfit',
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryGrid(
    BuildContext context,
    List<Category> categories,
    TransactionType type,
    bool isEditMode,
  ) {
    // Add button is index 0
    final itemCount = categories.length + 1;

    // Use ReorderableGridView only in Normal Mode?
    // Actually, ReorderableGridView works fine, we just disable reorder via callback
    // or by making dragging difficult. But simpler to just use it always
    // and ignore moves in Edit Mode if desired, OR allow reorder in edit mode (standard iOS).
    // User requested "Edit Button -> Edit Mode -> Tap to Edit".
    // Reorder was separate request.
    // Let's allow reorder in BOTH modes or just Normal? Usually Normal.
    // In Edit mode, tap takes precedence.

    return ReorderableGridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        childAspectRatio: 0.6,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: itemCount,
      onReorder: (oldIndex, newIndex) {
        if (isEditMode) return; // Disable reorder in Edit Mode

        // Prevent moving the "Add" button (index 0)
        // AND prevent moving items TO index 0
        if (oldIndex == 0 || newIndex == 0) return;

        // Adjust indices for the category list (subtract 1 for Add button)
        final int catOldIndex = oldIndex - 1;
        final int catNewIndex = newIndex - 1;

        if (catOldIndex < 0 || catOldIndex >= categories.length) return;
        if (catNewIndex < 0 || catNewIndex >= categories.length) return;

        final item = categories.removeAt(catOldIndex);
        categories.insert(catNewIndex, item);

        // Update order field
        for (int i = 0; i < categories.length; i++) {
          // We create new objects with updated order
          // But effectively we just need to pass the list in new order to provider
          // Provider/DB will handle saving the order index based on list position
          // Actually, we should update the 'order' property on the objects if we want to be strict
          // But the provider method I wrote just takes a list and saves it.
          // DatabaseService.updateCategoryOrder iterates and saves 'category.order'.
          // SO WE MUST UPDATE 'order' property here.
          categories[i] = categories[i].copyWith(order: i);
        }

        ref.read(categoryListProvider.notifier).updateOrder(categories);
      },
      dragWidgetBuilder: (index, child) {
        return Material(
          color: Colors.transparent,
          elevation: 0,
          child: Transform.scale(scale: 1.1, child: child),
        );
      },
      itemBuilder: (context, index) {
        if (index == 0) {
          // Add button hidden in Edit Mode? Or visually disabled?
          // Usually you can't add in edit mode.
          if (isEditMode) {
            return Opacity(
              key: const ValueKey('add_button_key'),
              opacity: 0.3,
              child: _buildAddButton(context, type, isEditMode),
            );
          }
          return Container(
            key: const ValueKey('add_button_key'),
            child: _buildAddButton(context, type, isEditMode),
          );
        }

        final category = categories[index - 1];
        return Container(
          key: ValueKey(category.id),
          child: _buildCategoryItem(context, category, isEditMode),
        );
      },
    );
  }

  Widget _buildAddButton(
    BuildContext context,
    TransactionType type,
    bool isEditMode,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _ScaleButton(
      onTap: () {
        if (isEditMode) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AddCategoryScreen(initialType: type),
          ),
        );
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
  }

  Widget _buildCategoryItem(
    BuildContext context,
    Category category,
    bool isEditMode,
  ) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _ScaleButton(
          onTap: () {
            if (isEditMode) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddCategoryScreen(categoryToEdit: category),
                ),
              );
            }
          },
          // In Normal Mode: Pass null to let ReorderableGridView handle LongPress for drag.
          // In Edit Mode: Consume LongPress to prevent dragging (since we only want Edit/Delete).
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
        if (isEditMode && category.name != '其他')
          Positioned(
            right: 0,
            top: 0,
            child: GestureDetector(
              onTap: () => _confirmDelete(context, ref, category),
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

  void _confirmDelete(BuildContext context, WidgetRef ref, Category category) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).dialogBackgroundColor,
        title: const Text("Delete Category?"),
        content: Text(
          "Delete '${category.name}'? Transactions will be moved to 'Other'.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              ref
                  .read(categoryListProvider.notifier)
                  .deleteCategory(category.id, category.type);
              Navigator.pop(ctx);
            },
            child: const Text(
              "Delete",
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScaleButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const _ScaleButton({required this.child, this.onTap, this.onLongPress});

  @override
  State<_ScaleButton> createState() => _ScaleButtonState();
}

class _ScaleButtonState extends State<_ScaleButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Handle animation only if onTap/onLongPress is provided?
  // Should probably animate on touch down regardless.
  void _onTapDown(_) => _controller.forward();
  void _onTapUp(_) => _controller.reverse();
  void _onTapCancel() => _controller.reverse();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      behavior: HitTestBehavior.opaque,
      child: ScaleTransition(scale: _scaleAnimation, child: widget.child),
    );
  }
}
