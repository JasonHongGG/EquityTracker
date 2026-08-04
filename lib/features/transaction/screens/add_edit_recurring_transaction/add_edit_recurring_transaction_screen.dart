import 'package:equity_tracker/core/enums/frequency.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:equity_tracker/core/enums/transaction_type.dart';
import 'package:equity_tracker/features/category/providers/category_notifier.dart';
import 'package:equity_tracker/features/transaction/providers/recurring_transaction_notifier.dart';
import 'package:equity_tracker/core/theme/app_colors.dart';
import 'package:equity_tracker/features/category/widgets/common/category_grid.dart';
import 'package:equity_tracker/core/widgets/calculator_pad.dart';

import 'package:equity_tracker/core/widgets/pickers/date_time_wheel_picker.dart';
import 'package:equity_tracker/core/widgets/pickers/premium_calendar_picker.dart';
import 'package:equity_tracker/core/widgets/pickers/string_wheel_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:equity_tracker/core/widgets/toast_notification.dart';
import 'package:equity_tracker/core/widgets/segmented_type_tab.dart';
import 'package:equity_tracker/features/transaction/screens/add_edit_recurring_transaction/frequency_selector.dart';
import 'package:equity_tracker/core/widgets/inline_delete_button.dart';
import 'package:equity_tracker/features/transaction/screens/add_edit_recurring_transaction/recurring_transaction_footer.dart';
import 'package:equity_tracker/features/transaction/screens/add_edit_recurring_transaction/recurring_transaction_header.dart';
import 'package:equity_tracker/features/transaction/screens/add_edit_recurring_transaction/trigger_date_time_selector.dart';
import 'package:equity_tracker/features/transaction/data/recurring_transaction_model.dart';

class AddEditRecurringTransactionModelScreen extends ConsumerStatefulWidget {
  final RecurringTransactionModel? transaction;

  const AddEditRecurringTransactionModelScreen({super.key, this.transaction});

  @override
  ConsumerState<AddEditRecurringTransactionModelScreen> createState() =>
      _AddEditRecurringTransactionModelScreenState();
}

class _AddEditRecurringTransactionModelScreenState
    extends ConsumerState<AddEditRecurringTransactionModelScreen> {
  late TransactionType _type;
  late Frequency _frequency;
  late DateTime _nextDueDate; // Stores the next trigger
  late int _amount;
  late TextEditingController _amountController;
  late TextEditingController _titleController;

  String? _selectedCategoryId;
  bool _isEnabled = true;

  final FocusNode _titleFocusNode = FocusNode();
  final ScrollController _suggestionsScrollController = ScrollController();

  // Helper to store "Time" separately if needed, but we can extract from _nextDueDate
  TimeOfDay _time = const TimeOfDay(hour: 9, minute: 0);

  @override
  void initState() {
    super.initState();
    final t = widget.transaction;
    _type = t?.type ?? TransactionType.expense;
    _frequency = t?.frequency ?? Frequency.monthly;
    _nextDueDate = t?.nextDueDate ?? DateTime.now();
    _amount = t?.amount ?? 0;
    _amountController = TextEditingController(
      text: t != null ? t.amount.toString() : '',
    );
    _titleController = TextEditingController(text: t?.title ?? '');
    _titleController = TextEditingController(text: t?.title ?? '');
    _selectedCategoryId = t?.categoryId;
    _isEnabled = t?.isEnabled ?? true;
    _time = TimeOfDay.fromDateTime(_nextDueDate);

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
    _titleFocusNode.dispose();
    _suggestionsScrollController.dispose();
    super.dispose();
  }

  // --- Logic to calculate the "Next Due Date" based on rules ---
  // When user picks a "Rule" (e.g. Weekly on Monday at 10am), we calculate the immediate next occurrence from NOW.
  DateTime _calculateNextDate({
    required Frequency freq,
    int? dayOfWeek, // 1-7 for Weekly
    int? dayOfMonth, // 1-31 for Monthly
    DateTime? specificDate, // for Yearly
    required TimeOfDay time,
  }) {
    final now = DateTime.now();
    DateTime candidate = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    switch (freq) {
      case Frequency.daily:
        if (candidate.isBefore(now)) {
          candidate = candidate.add(const Duration(days: 1));
        }
        break;
      case Frequency.weekly:
        // Find next specific day of week
        // dayOfWeek 1=Mon, 7=Sun
        if (dayOfWeek != null) {
          while (candidate.weekday != dayOfWeek || candidate.isBefore(now)) {
            candidate = candidate.add(const Duration(days: 1));
          }
        }
        break;
      case Frequency.monthly:
        // Find next specific day of month
        if (dayOfMonth != null) {
          // Start with current month/year but target day
          // Handle invalid days (e.g. Feb 30) by clamping or skipping?
          // Database logic allows "day > daysInMonth -> last day".
          // Here we just try to set it.
          // Simple approach: Set to this month's target day. If passed, add month.

          // Logic:
          // 1. Construct target for this month.
          // 2. If invalid (e.g. Feb 30), what to do? User likely picked a valid day (1-31).
          //    We should probably snap to last day if current month doesn't have it.
          //    OR, simpler: Loop months until we find a valid date? No.
          //    Standard: If Day > MonthDays, use MonthDays.

          DateTime targetForMonth(int year, int month) {
            int maxDays = DateUtils.getDaysInMonth(year, month);
            int d = dayOfMonth > maxDays ? maxDays : dayOfMonth;
            return DateTime(year, month, d, time.hour, time.minute);
          }

          candidate = targetForMonth(now.year, now.month);
          if (candidate.isBefore(now)) {
            // Try next month
            int nextMonth = now.month + 1;
            int nextYear = now.year;
            if (nextMonth > 12) {
              nextMonth = 1;
              nextYear++;
            }
            candidate = targetForMonth(nextYear, nextMonth);
          }
        }
        break;
      case Frequency.yearly:
        if (specificDate != null) {
          // Target: specificDate's Month/Day, current Year
          candidate = DateTime(
            now.year,
            specificDate.month,
            specificDate.day,
            time.hour,
            time.minute,
          );
          if (candidate.isBefore(now)) {
            candidate = DateTime(
              now.year + 1,
              specificDate.month,
              specificDate.day,
              time.hour,
              time.minute,
            );
          }
        }
        break;
    }
    return candidate;
  }

  String _getFrequencyLabel() {
    final dateFormat = DateFormat('HH:mm');
    final date = _nextDueDate;
    final timeStr = dateFormat.format(date);

    switch (_frequency) {
      case Frequency.daily:
        return 'Daily at $timeStr';
      case Frequency.weekly:
        final dayName = DateFormat('EEEE').format(date);
        return 'Weekly on $dayName at $timeStr';
      case Frequency.monthly:
        return 'Monthly on day ${date.day} at $timeStr';
      case Frequency.yearly:
        final monthDay = DateFormat('MMM dd').format(date);
        return 'Yearly on $monthDay at $timeStr';
    }
  }

  Future<void> _pickTrigger() async {
    // Dismiss keyboard to prevent overflow
    FocusScope.of(context).unfocus();

    // Give time for keyboard to dismiss
    await Future.delayed(const Duration(milliseconds: 200));
    // Helper to update state
    void update(DateTime newDate, TimeOfDay newTime) {
      setState(() {
        _time = newTime;
        _nextDueDate = newDate;
      });
    }

    if (_frequency == Frequency.daily) {
      final DateTime? pickedTime = await showCustomDateTimePicker(
        context: context,
        initialDate: DateTime(
          DateTime.now().year,
          DateTime.now().month,
          DateTime.now().day,
          _time.hour,
          _time.minute,
        ),
        showTime: true,
      );
      if (pickedTime != null) {
        update(
          _calculateNextDate(freq: Frequency.daily, time: TimeOfDay.fromDateTime(pickedTime)),
          TimeOfDay.fromDateTime(pickedTime),
        );
      }
      return;
    }

    // Helper to pick time
    Future<TimeOfDay?> pickTime() async {
      return showCustomDateTimePicker(
        context: context,
        initialDate: DateTime(
          DateTime.now().year,
          DateTime.now().month,
          DateTime.now().day,
          _time.hour,
          _time.minute,
        ),
        showTime: true,
      ).then((dt) => dt != null ? TimeOfDay(hour: dt.hour, minute: dt.minute) : null);
    }

    if (_frequency == Frequency.weekly) {
      // 1. Pick Day of Week
      final days = List.generate(7, (index) {
        final dayNum = index + 1; // 1 = Monday
        // Calculate a dummy date for label
        final now = DateTime.now();
        final diff = dayNum - now.weekday;
        final d = now.add(Duration(days: diff));
        return DateFormat('EEEE').format(d);
      });

      final initialIndex = _nextDueDate.weekday - 1;

      final int? selectedIndex = await showCustomWheelPicker(
        context: context,
        title: 'Select Day of Week',
        items: days,
        initialIndex: initialIndex,
      );

      if (selectedIndex != null) {
        // 2. Pick Time
        final t = await pickTime();
        if (t != null) {
          final dayNum = selectedIndex + 1;
          update(
            _calculateNextDate(
              freq: Frequency.weekly,
              dayOfWeek: dayNum,
              time: t,
            ),
            t,
          );
        }
      }
      return;
    }

    if (_frequency == Frequency.monthly) {
      // 1. Pick Day 1-31
      final days = List.generate(31, (index) => '${index + 1}');
      final initialIndex = (_nextDueDate.day - 1).clamp(0, 30);

      final int? selectedIndex = await showCustomWheelPicker(
        context: context,
        title: 'Select Day of Month',
        items: days,
        initialIndex: initialIndex,
      );

      if (selectedIndex != null) {
        // 2. Pick Time
        final t = await pickTime();
        if (t != null) {
          final day = selectedIndex + 1;
          update(
            _calculateNextDate(
              freq: Frequency.monthly,
              dayOfMonth: day,
              time: t,
            ),
            t,
          );
        }
      }
      return;
    }

    if (_frequency == Frequency.yearly) {
      // 1. Pick Date
      final DateTime? pickedDate = await showPremiumCalendarPicker(
        context: context,
        initialDate: _nextDueDate,
      );
      if (pickedDate != null) {
        // 2. Pick Time
        final t = await pickTime();
        if (t != null) {
          update(
            _calculateNextDate(
              freq: Frequency.yearly,
              specificDate: pickedDate,
              time: t,
            ),
            t,
          );
        }
      }
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoryListProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark
        ? AppColors.backgroundDark
        : AppColors.backgroundLight;
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
              // --- HEADER ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(Icons.close, color: txtColor, size: 28),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Row(
                      children: [
                        // Active Rule Toggle
                        IconButton(
                          icon: Icon(
                            _isEnabled
                                ? Icons.alarm_on_rounded
                                : Icons.alarm_off_rounded,
                            color: _isEnabled ? Theme.of(context).primaryColor : Colors.grey,
                            size: 24, // Slightly smaller than close/delete
                          ),
                          onPressed: () {
                            setState(() {
                              _isEnabled = !_isEnabled;
                            });
                          },
                        ),
                        if (widget.transaction != null)
                          InlineDeleteButton(
                            onDelete: _deleteTransaction,
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              RecurringTransactionHeader(
                type: _type,
                amountController: _amountController,
                titleController: _titleController,
                titleFocusNode: _titleFocusNode,
                onAmountTap: _showCalculatorSheet,
              ),

              // --- MAIN CARD ---
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
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),

                      FrequencySelector(
                        selectedFrequency: _frequency,
                        onChanged: (f) {
                          setState(() {
                            _frequency = f;
                          });
                        },
                      ),

                      TriggerDateTimeSelector(
                        label: _getFrequencyLabel(),
                        onTap: _pickTrigger,
                      ),

                      // --- 3. TYPE TABS & SETTINGS ---
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
                                color: isDark
                                    ? Colors.black26
                                    : Colors.grey[200],
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.settings_outlined,
                                  size: 20,
                                ),
                                color: txtColor,
                                onPressed: () => context.push('/manage-categories'),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // --- 4. CATEGORY GRID ---
                      Expanded(
                        child: categoriesAsync.when(
                          data: (categories) {
                            final filtered = categories
                                .where((c) => c.type == _type && c.isEnabled)
                                .toList();

                            if (_selectedCategoryId == null &&
                                filtered.isNotEmpty) {
                              final defaultCat = filtered.firstWhere(
                                (c) => c.name == '?∵??',
                                orElse: () => filtered.first,
                              );
                              Future.microtask(() {
                                if (mounted && _selectedCategoryId == null) {
                                  setState(
                                    () => _selectedCategoryId = defaultCat.id,
                                  );
                                }
                              });
                            }

                            if (filtered.isEmpty) {
                              return const Center(child: Text('No Categories'));
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

                      RecurringTransactionFooter(
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

    final title = _titleController.text.trim();
    // Default title if empty
    final finalTitle = title.isEmpty ? _frequency.label : title;

    final newTx = RecurringTransactionModel(
      id: widget.transaction?.id,
      title: finalTitle,
      amount: finalAmount,
      type: _type,
      categoryId: _selectedCategoryId!,
      frequency: _frequency,
      nextDueDate: _nextDueDate,
      lastGeneratedDate: widget.transaction?.lastGeneratedDate,
      isEnabled: _isEnabled,
      note: '',
      createdAt: widget.transaction?.createdAt ?? DateTime.now(),
    );

    if (widget.transaction == null) {
      ref
          .read(recurringTransactionListProvider.notifier)
          .addRecurringTransaction(newTx);
    } else {
      ref
          .read(recurringTransactionListProvider.notifier)
          .updateRecurringTransaction(newTx);
    }

    Navigator.pop(context);
  }

  void _showCalculatorSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      barrierColor: Colors.transparent,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (c, setStateSheet) {
            return CalculatorPad(
              value: _amountController.text,
              onChanged: (val) {
                setState(() {
                  _amountController.text = val;
                  final p = int.tryParse(val);
                  if (p != null) _amount = p;
                });
                setStateSheet(() {});
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

  void _deleteTransaction() async {
    if (widget.transaction?.id != null) {
      ref
          .read(recurringTransactionListProvider.notifier)
          .deleteRecurringTransaction(widget.transaction!.id!);
      if (mounted) {
        Navigator.pop(context);
        Navigator.pop(context);
      }
    }
  }
}
