import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equity_tracker/features/transaction/domain/transaction_entity.dart';
import 'package:equity_tracker/core/enums/transaction_type.dart';
import 'package:equity_tracker/features/transaction/presentation/providers/transaction_notifier.dart';
import 'package:equity_tracker/features/category/presentation/providers/category_notifier.dart';
import 'package:equity_tracker/core/theme/app_colors.dart';
import 'package:equity_tracker/features/category/presentation/widgets/common/category_grid.dart';
import 'package:equity_tracker/core/widgets/calculator_pad.dart';
import 'package:equity_tracker/core/widgets/custom_date_picker_dialog.dart';
import 'package:go_router/go_router.dart';
import 'package:equity_tracker/core/widgets/custom_toast.dart';
import 'package:equity_tracker/features/transaction/presentation/widgets/add_edit_transaction_screen/transaction_header.dart';
import 'package:equity_tracker/features/transaction/presentation/widgets/add_edit_transaction_screen/transaction_date_selector.dart';
import 'package:equity_tracker/core/widgets/segmented_type_tab.dart';
import 'package:equity_tracker/features/transaction/presentation/widgets/add_edit_transaction_screen/transaction_footer.dart';
import 'package:equity_tracker/features/transaction/presentation/widgets/add_edit_transaction_screen/transaction_delete_dialog.dart';

class AddEditTransactionScreen extends ConsumerStatefulWidget {
  final TransactionEntity? transaction;
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

class _AddEditTransactionScreenState extends ConsumerState<AddEditTransactionScreen> {
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

    if (t != null) {
      _date = t.date;
    } else {
      final now = DateTime.now();
      if (widget.initialDate != null) {
        _date = DateTime(
          widget.initialDate!.year,
          widget.initialDate!.month,
          widget.initialDate!.day,
          now.hour,
          now.minute,
          now.second,
        );
      } else {
        _date = now;
      }
    }

    _amount = t?.amount ?? 0;
    _amountController = TextEditingController(
      text: t != null ? t.amount.toString() : '',
    );
    _titleController = TextEditingController(text: t?.title ?? '');
    _noteController = TextEditingController(text: t?.note ?? '');
    _selectedCategoryId = t?.categoryId;

    _titleFocusNode.addListener(() {
      setState(() {});
    });

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
        _date = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _date.hour,
          _date.minute,
          _date.second,
        );
      });
    }
  }

  void _showCalculatorSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      clipBehavior: Clip.hardEdge,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return CalculatorPad(
              value: _amountController.text,
              onChanged: (val) {
                setState(() {
                  _amountController.text = val;
                  final parsed = int.tryParse(val);
                  if (parsed != null) _amount = parsed;
                });
                setSheetState(() {});
              },
              onSubmit: () {
                Navigator.pop(context);
                _titleFocusNode.requestFocus();
              },
            );
          },
        );
      },
    );
  }

  void _saveTransaction() {
    int finalAmount = _amount;
    final val = _amountController.text;
    final parsed = int.tryParse(val);
    if (parsed == null) {
      ToastService.showError(context, 'Invalid Amount');
      return;
    }
    finalAmount = parsed;

    if (finalAmount <= 0) {
      ToastService.showError(context, 'Amount must be > 0');
      return;
    }
    if (_selectedCategoryId == null) {
      ToastService.showError(context, 'Please select a category');
      return;
    }

    final newTx = TransactionEntity(
      id: widget.transaction?.id,
      notionId: widget.transaction?.notionId,
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

  void _deleteTransaction() async {
    final shouldDelete = await TransactionDeleteDialog.show(context);
    if (shouldDelete && widget.transaction?.id != null) {
      ref
          .read(transactionListProvider.notifier)
          .deleteTransaction(
            widget.transaction!.id!,
            widget.transaction!.notionId,
          );
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoryListProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final surfaceColor = isDark ? AppColors.surfaceDark : Colors.white;
    final txtColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: bgColor,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusScope.of(context).unfocus(),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(Icons.close, color: txtColor, size: 28),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      visualDensity: VisualDensity.compact,
                      onPressed: () => Navigator.pop(context),
                    ),
                    if (widget.transaction != null)
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: AppColors.expense),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        visualDensity: VisualDensity.compact,
                        onPressed: _deleteTransaction,
                      )
                    else
                      const SizedBox(width: 48),
                  ],
                ),
              ),

              TransactionHeader(
                type: _type,
                amountController: _amountController,
                titleController: _titleController,
                titleFocusNode: _titleFocusNode,
                suggestionsScrollController: _suggestionsScrollController,
                onAmountTap: _showCalculatorSheet,
              ),

              const SizedBox(height: 12),

              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
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
                      TransactionDateSelector(
                        date: _date,
                        onPreviousDay: () => setState(() => _date = _date.subtract(const Duration(days: 1))),
                        onNextDay: () => setState(() => _date = _date.add(const Duration(days: 1))),
                        onPickDate: _pickDate,
                      ),
                      
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: SegmentedTypeTab(
                                selectedType: _type,
                                onChanged: (type) {
                                  setState(() {
                                    _type = type;
                                    _selectedCategoryId = null;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              decoration: BoxDecoration(
                                color: isDark ? Colors.black26 : Colors.grey[200],
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                onPressed: () => context.push('/manage-categories'),
                                icon: const Icon(Icons.settings_outlined, size: 20),
                                color: txtColor,
                                tooltip: 'Manage Categories',
                              ),
                            ),
                          ],
                        ),
                      ),

                      Expanded(
                        child: categoriesAsync.when(
                          data: (categories) {
                            final filtered = categories.where((c) => c.type == _type && c.isEnabled).toList();

                            if (_selectedCategoryId == null && filtered.isNotEmpty) {
                              final defaultCat = filtered.firstWhere(
                                (c) => c.name == '飲食',
                                orElse: () => filtered.first,
                              );
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
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: CategoryGrid(
                                categories: filtered,
                                selectedCategoryId: _selectedCategoryId,
                                onSelected: (id) => setState(() => _selectedCategoryId = id),
                              ),
                            );
                          },
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (_, __) => const Center(child: Text('Error')),
                        ),
                      ),

                      TransactionFooter(
                        noteController: _noteController,
                        onSave: _saveTransaction,
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
}
