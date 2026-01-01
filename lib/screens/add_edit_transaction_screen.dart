import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';
import '../models/transaction_type.dart';
import '../providers/transaction_provider.dart';
import '../providers/category_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/category_grid.dart';

class AddEditTransactionScreen extends ConsumerStatefulWidget {
  final TransactionModel? transaction;
  final DateTime? initialDate;

  const AddEditTransactionScreen({
    super.key,
    this.transaction,
    this.initialDate,
  });

  @override
  ConsumerState<AddEditTransactionScreen> createState() =>
      _AddEditTransactionScreenState();
}

class _AddEditTransactionScreenState
    extends ConsumerState<AddEditTransactionScreen> {
  late TransactionType _type;
  late DateTime _date;
  late int _amount;
  late TextEditingController _amountController;
  late TextEditingController _titleController;
  late TextEditingController _noteController;
  String? _selectedCategoryId;

  final FocusNode _amountFocusNode = FocusNode();
  final FocusNode _titleFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    final t = widget.transaction;
    _type = t?.type ?? TransactionType.expense;
    _date = t?.date ?? widget.initialDate ?? DateTime.now();
    _amount = t?.amount ?? 0;
    _amountController = TextEditingController(
      text: t != null ? t.amount.toString() : '',
    );
    _titleController = TextEditingController(text: t?.title ?? '');
    _noteController = TextEditingController(text: t?.note ?? '');
    _selectedCategoryId = t?.categoryId;

    // Listen to focus changes to toggle chip visibility
    _titleFocusNode.addListener(() {
      setState(() {});
    });

    // Auto-focus amount if new
    if (widget.transaction == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _amountFocusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _titleController.dispose();
    _noteController.dispose();
    _amountFocusNode.dispose();
    _titleFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoryListProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(widget.transaction == null ? 'New Entry' : 'Edit Entry'),
        actions: [
          if (widget.transaction != null)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.expense),
              onPressed: _deleteTransaction,
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Hero Section: Combined Amount & Title
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                children: [
                  // Type Switcher
                  Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : Colors.grey[200],
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

                  // Amount Input
                  Consumer(
                    builder: (context, ref, child) {
                      return Focus(
                        onFocusChange: (hasFocus) {
                          // Force rebuild to update styling
                          setState(() {});
                        },
                        child: IntrinsicWidth(
                          child: TextField(
                            controller: _amountController,
                            focusNode: _amountFocusNode,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            showCursor:
                                false, // Hide the default blinking cursor
                            textInputAction: TextInputAction.next,
                            onSubmitted: (_) {
                              // Auto-focus title when done
                              _titleFocusNode.requestFocus();
                            },
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 56,
                              fontWeight: FontWeight.bold,
                              color: _type == TransactionType.income
                                  ? AppColors.income
                                  : AppColors.expense,
                              decoration: _amountFocusNode.hasFocus
                                  ? TextDecoration.underline
                                  : TextDecoration.none,
                              decorationColor: _type == TransactionType.income
                                  ? AppColors.income.withValues(alpha: 0.3)
                                  : AppColors.expense.withValues(alpha: 0.3),
                            ),
                            decoration: const InputDecoration(
                              prefixText: '\$',
                              prefixStyle: TextStyle(
                                fontSize: 30,
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                              border: InputBorder.none,
                              hintText: '0',
                              hintStyle: TextStyle(color: Colors.grey),
                            ),
                            onChanged: (val) =>
                                _amount = int.tryParse(val) ?? 0,
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 10),

                  // Smart Title Autocomplete
                  // Title Input
                  Consumer(
                    builder: (context, ref, child) {
                      final recentTitlesAsync = ref.watch(recentTitlesProvider);
                      final allOptions = recentTitlesAsync.value ?? [];

                      // Filter options based on user input
                      final filteredOptions = allOptions.where((String option) {
                        return option.toLowerCase().contains(
                          _titleController.text.toLowerCase(),
                        );
                      }).toList();

                      // Only show limited number of suggestions
                      final displayOptions = filteredOptions.take(10).toList();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: _titleController,
                            focusNode: _titleFocusNode,
                            textAlign: TextAlign.center,
                            textInputAction: TextInputAction.done,
                            onChanged: (value) {
                              // Trigger rebuild to update suggestions
                              setState(() {});
                            },
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              hintText: 'What is this for?',
                              hintStyle: TextStyle(
                                color: isDark ? Colors.white38 : Colors.black38,
                              ),
                              border: InputBorder.none,
                              prefixIcon: const Icon(
                                Icons.edit,
                                color: Colors.transparent, // Spacer
                                size: 16,
                              ),
                              suffixIcon: const Icon(
                                Icons.edit,
                                color: Colors.grey,
                                size: 16,
                              ),
                            ),
                          ),

                          // Horizontal Suggestion Chips
                          if (_titleFocusNode.hasFocus &&
                              displayOptions.isNotEmpty)
                            Container(
                              height: 50,
                              margin: const EdgeInsets.only(top: 8),
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: displayOptions.map((option) {
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        right: 8.0,
                                      ),
                                      child: ActionChip(
                                        label: Text(option),
                                        backgroundColor: isDark
                                            ? AppColors.surfaceDark
                                            : Colors.white,
                                        elevation: 2,
                                        shadowColor: Colors.black12,
                                        side: BorderSide.none,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        labelStyle: TextStyle(
                                          color: isDark
                                              ? Colors.white
                                              : Colors.black87,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _titleController.text = option;
                                            _titleController.selection =
                                                TextSelection.fromPosition(
                                                  TextPosition(
                                                    offset: option.length,
                                                  ),
                                                );
                                          });
                                          // Keep focus or dismiss? User flow usually implies
                                          // setting title then moving on. Let's keep focus
                                          // so they can edit if needed, or they can tap outside.
                                        },
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),

            // Details Section
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Category',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  categoriesAsync.when(
                    data: (categories) {
                      final filtered = categories
                          .where((c) => c.type == _type && c.isEnabled)
                          .toList();

                      if (_selectedCategoryId == null &&
                          widget.transaction == null) {
                        if (filtered.isNotEmpty) {
                          _selectedCategoryId = filtered.first.id;
                        }
                      }
                      if (_selectedCategoryId != null &&
                          !filtered.any((c) => c.id == _selectedCategoryId)) {
                        _selectedCategoryId = filtered.isNotEmpty
                            ? filtered.first.id
                            : null;
                      }

                      if (filtered.isEmpty) {
                        return const Text('No Categories');
                      }

                      // Use same Grid but maybe update styling later if needed
                      return CategoryGrid(
                        categories: filtered,
                        selectedCategoryId: _selectedCategoryId,
                        onSelected: (id) =>
                            setState(() => _selectedCategoryId = id),
                      );
                    },
                    loading: () => const CircularProgressIndicator(),
                    error: (e, s) => const Text('Error'),
                  ),
                  const SizedBox(height: 24),

                  // Date
                  const Text(
                    'Date',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _pickDate,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.backgroundDark
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            size: 18,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            DateFormat('yyyy / MM / dd  (EEEE)').format(_date),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Note (Optional, secondary)
                  const Text(
                    'Internal Note',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _noteController,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: isDark
                          ? AppColors.backgroundDark
                          : Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                      hintText: 'Private details...',
                    ),
                  ),

                  // Buttons... (Existing code handles this part if I don't overwrite effectively, but I should probably overwrite up to the end of body or just the input part)
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _saveTransaction,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 5,
                        shadowColor: AppColors.primary.withValues(alpha: 0.5),
                      ),
                      child: const Text(
                        'Save Transaction',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeButton(TransactionType type, String label) {
    final isSelected = _type == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _type = type;
          _selectedCategoryId = null; // Reset category
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
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
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.surfaceDark,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _date = picked;
      });
    }
  }

  void _saveTransaction() {
    if (_amount <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Amount must be > 0')));
      return;
    }
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a category')));
      return;
    }

    final newTx = TransactionModel(
      id: widget.transaction?.id,
      title: _titleController.text.isNotEmpty ? _titleController.text : null,
      type: _type,
      amount: _amount,
      categoryId: _selectedCategoryId!,
      date: _date,
      createdAt: widget.transaction?.createdAt ?? DateTime.now(),
      note: _noteController.text,
    );

    if (widget.transaction == null) {
      ref.read(transactionListProvider.notifier).addTransaction(newTx);
    } else {
      ref.read(transactionListProvider.notifier).updateTransaction(newTx);
    }

    Navigator.pop(context);
  }

  void _deleteTransaction() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: const Text('Delete', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Delete this transaction?',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (widget.transaction?.id != null) {
                ref
                    .read(transactionListProvider.notifier)
                    .deleteTransaction(widget.transaction!.id!);
              }
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.expense),
            ),
          ),
        ],
      ),
    );
  }
}
