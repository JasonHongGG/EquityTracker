import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';
import '../models/transaction_type.dart';
import '../providers/transaction_provider.dart';
import '../providers/category_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/category_grid.dart';
import '../widgets/calculator_pad.dart';
import '../widgets/custom_date_picker_dialog.dart';
import 'category_management_screen.dart';

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

  final FocusNode _titleFocusNode = FocusNode();
  final FocusNode _noteFocusNode = FocusNode();
  final ScrollController _suggestionsScrollController = ScrollController();

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

    // Add listener to rebuild UI when title focus changes (to show/hide suggestions)
    _titleFocusNode.addListener(() {
      setState(() {});
    });

    // Auto-focus calculator for new entries
    if (widget.transaction == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showCalculatorSheet();
      });
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _titleController.dispose();
    _noteController.dispose();
    _titleFocusNode.dispose();
    _noteFocusNode.dispose();
    _suggestionsScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoryListProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Theme Colors
    final bgColor = isDark
        ? AppColors.backgroundDark
        : AppColors.backgroundLight;
    final surfaceColor = isDark ? AppColors.surfaceDark : Colors.white;
    final txtColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: bgColor,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.close,
            color: txtColor,
            size: 28,
          ), // Slightly bigger close icon
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (widget.transaction != null)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.expense),
              onPressed: _deleteTransaction,
            ),
        ],
      ),
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusScope.of(context).unfocus(),
          child: Column(
            children: [
              // --- HEADER SECTION: Amount & Title ---
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 0,
                ),
                child: Column(
                  children: [
                    // Amount Display (Tappable)
                    GestureDetector(
                      onTap: _showCalculatorSheet,
                      child: IntrinsicWidth(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color:
                                    (_type == TransactionType.income
                                            ? AppColors.income
                                            : AppColors.expense)
                                        .withOpacity(0.3),
                                width: 2,
                              ),
                            ),
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                const Text(
                                  '\$',
                                  style: TextStyle(
                                    fontSize: 32,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _amountController.text.isEmpty
                                      ? '0'
                                      : _amountController.text,
                                  style: TextStyle(
                                    fontSize: 64,
                                    fontWeight: FontWeight.bold,
                                    color: _type == TransactionType.income
                                        ? AppColors.income
                                        : AppColors.expense,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Title Input (Compact with Suggestion Chips)
                    Consumer(
                      builder: (context, ref, child) {
                        final recentTitlesAsync = ref.watch(
                          recentTitlesProvider,
                        );
                        final allOptions = recentTitlesAsync.value ?? [];
                        final filteredOptions = allOptions.where((
                          String option,
                        ) {
                          return option.toLowerCase().contains(
                            _titleController.text.toLowerCase(),
                          );
                        }).toList();
                        final displayOptions = filteredOptions
                            .take(10)
                            .toList();

                        return Column(
                          children: [
                            TextField(
                              controller: _titleController,
                              focusNode: _titleFocusNode,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 24,
                                color: txtColor,
                                fontWeight: FontWeight.w500,
                              ),
                              decoration: InputDecoration(
                                isDense: true,
                                hintText: 'What is this for?',
                                hintStyle: TextStyle(
                                  color: Colors.grey.withOpacity(0.5),
                                ),
                                border: InputBorder.none,
                              ),
                              onChanged: (val) {
                                setState(() {});
                                // Reset scroll position to start when filtering changes
                                if (_suggestionsScrollController.hasClients) {
                                  _suggestionsScrollController.jumpTo(0);
                                }
                              },
                            ),
                            // Suggestion Chips
                            if (_titleFocusNode.hasFocus &&
                                displayOptions.isNotEmpty)
                              Container(
                                height: 40,
                                margin: const EdgeInsets.only(top: 4),
                                child: SingleChildScrollView(
                                  controller: _suggestionsScrollController,
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: displayOptions.map((option) {
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          right: 8.0,
                                          bottom: 4.0, // Space for shadow
                                        ),
                                        child: ActionChip(
                                          label: Text(option),
                                          backgroundColor: isDark
                                              ? AppColors.surfaceDark
                                              : Colors.white,
                                          padding: EdgeInsets.zero,
                                          labelStyle: TextStyle(
                                            fontSize: 13,
                                            color: isDark
                                                ? Colors.white70
                                                : Colors.grey[700],
                                            fontWeight: FontWeight.w500,
                                          ),
                                          elevation: 2,
                                          shadowColor: Colors.black.withOpacity(
                                            0.1,
                                          ),
                                          side: BorderSide
                                              .none, // Remove strong border
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
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
                                              // Unfocus to hide suggestions
                                              _titleFocusNode.unfocus();
                                            });
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
              const SizedBox(height: 12),

              // --- MAIN CARD: Date, Type Tabs, Category Grid ---
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // --- DATE SELECTOR (Moved to Top) ---
                      Container(
                        margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        height: 48,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.black26 : Colors.grey[100],
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: isDark
                                ? Colors.white10
                                : Colors.black.withOpacity(0.05),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.arrow_left_rounded,
                                size: 28,
                              ),
                              color: Colors.grey,
                              padding: EdgeInsets.zero,
                              onPressed: () => setState(
                                () => _date = _date.subtract(
                                  const Duration(days: 1),
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: _pickDate,
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    size: 14,
                                    color: txtColor,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    DateFormat('yyyy/MM/dd EEEE').format(_date),
                                    style: TextStyle(
                                      color: txtColor,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.arrow_right_rounded,
                                size: 28,
                              ),
                              color: Colors.grey,
                              padding: EdgeInsets.zero,
                              onPressed: () => setState(
                                () =>
                                    _date = _date.add(const Duration(days: 1)),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // --- TABS & SETTINGS ---
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 40,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.black26
                                      : Colors.grey[200],
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  children: [
                                    _buildTabItem(
                                      TransactionType.expense,
                                      'Expense',
                                      _type == TransactionType.expense,
                                    ),
                                    _buildTabItem(
                                      TransactionType.income,
                                      'Income',
                                      _type == TransactionType.income,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.black26
                                    : Colors.grey[200],
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const CategoryManagementScreen(),
                                  ),
                                ),
                                icon: const Icon(
                                  Icons.settings_outlined,
                                  size: 20,
                                ),
                                color: txtColor,
                                tooltip: 'Manage Categories',
                              ),
                            ),
                          ],
                        ),
                      ),

                      // --- CATEGORY GRID ---
                      Expanded(
                        child: categoriesAsync.when(
                          data: (categories) {
                            final filtered = categories
                                .where((c) => c.type == _type && c.isEnabled)
                                .toList();

                            // Auto-selection of default category '伙食' (Food) or first available
                            if (_selectedCategoryId == null &&
                                filtered.isNotEmpty) {
                              // Try to find '伙食' (Food)
                              final defaultCat = filtered.firstWhere(
                                (c) => c.name == '伙食', // Or 'Food' if english
                                orElse: () => filtered.first,
                              );
                              // Do not setState during build, defer to next frame
                              Future.microtask(() {
                                if (mounted && _selectedCategoryId == null) {
                                  setState(() {
                                    _selectedCategoryId = defaultCat.id;
                                  });
                                }
                              });
                            }

                            if (filtered.isEmpty) {
                              return const Center(
                                child: Text(
                                  'No Categories',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              );
                            }
                            return SingleChildScrollView(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: CategoryGrid(
                                categories: filtered,
                                selectedCategoryId: _selectedCategoryId,
                                onSelected: (id) =>
                                    setState(() => _selectedCategoryId = id),
                              ),
                            );
                          },
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
                          error: (_, __) => const Center(child: Text('Error')),
                        ),
                      ),

                      // --- FOOTER (Note & Save) ---
                      Container(
                        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                        decoration: BoxDecoration(
                          color: surfaceColor,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 10,
                              offset: const Offset(0, -5),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.backgroundDark
                                    : Colors.grey[100],
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: TextField(
                                controller: _noteController,
                                style: TextStyle(color: txtColor),
                                decoration: const InputDecoration(
                                  hintText: 'Add note...',
                                  border: InputBorder.none,
                                  icon: Icon(
                                    Icons.edit,
                                    size: 16,
                                    color: Colors.grey,
                                  ),
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _saveTransaction,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  elevation: 0,
                                ),
                                child: const Text(
                                  'Save',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabItem(TransactionType type, String label, bool isActive) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (!isActive) {
            setState(() {
              _type = type;
              _selectedCategoryId = null; // Clear selection on switch
            });
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            boxShadow: isActive
                ? [BoxShadow(color: Colors.black12, blurRadius: 4)]
                : [],
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isActive
                  ? (type == TransactionType.income
                        ? AppColors.income
                        : AppColors.expense)
                  : Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  void _showCalculatorSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // Sheet content background
      barrierColor: Colors.transparent, // Remove dimmed background
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      clipBehavior: Clip.hardEdge, // Clip content to shape
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return CalculatorPad(
              value: _amountController.text,
              onChanged: (val) {
                setState(() {
                  // Update Main Screen Controller
                  _amountController.text = val;
                  // Logic check
                  final parsed = int.tryParse(val);
                  if (parsed != null) {
                    _amount = parsed;
                  }
                });
                // Rebuild Sheet (CalculatorPad)
                setSheetState(() {});
              },
              onSubmit: () {
                Navigator.pop(context);
                // Move focus to title
                _titleFocusNode.requestFocus();
              },
            );
          },
        );
      },
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDialog<DateTime>(
      context: context,
      builder: (context) => CustomDatePickerDialog(
        initialDate: _date,
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
      ),
    );
    if (picked != null) {
      setState(() {
        _date = picked;
      });
    }
  }

  void _saveTransaction() {
    int finalAmount = _amount;
    final val = _amountController.text;
    final parsed = int.tryParse(val);
    if (parsed == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invalid Amount')));
      return;
    }
    finalAmount = parsed;

    if (finalAmount <= 0) {
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
      amount: finalAmount,
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
