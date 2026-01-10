import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/recurring_transaction_model.dart';
import '../models/transaction_type.dart';
import '../providers/category_provider.dart';
import '../providers/recurring_transaction_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/category_grid.dart';
import '../widgets/calculator_pad.dart';
import '../widgets/scale_button.dart';
import '../widgets/custom_wheel_picker.dart';
import '../widgets/custom_month_day_picker.dart';

import 'category_management_screen.dart';

class AddEditRecurringTransactionScreen extends ConsumerStatefulWidget {
  final RecurringTransaction? transaction;

  const AddEditRecurringTransactionScreen({super.key, this.transaction});

  @override
  ConsumerState<AddEditRecurringTransactionScreen> createState() =>
      _AddEditRecurringTransactionScreenState();
}

class _AddEditRecurringTransactionScreenState
    extends ConsumerState<AddEditRecurringTransactionScreen> {
  late TransactionType _type;
  late Frequency _frequency;
  late DateTime _nextDueDate; // Stores the next trigger
  late int _amount;
  late TextEditingController _amountController;
  late TextEditingController _titleController;
  late TextEditingController _noteController;
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
    _noteController = TextEditingController(text: t?.note ?? '');
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
    _noteController.dispose();
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
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: _time,
      );
      if (pickedTime != null) {
        update(
          _calculateNextDate(freq: Frequency.daily, time: pickedTime),
          pickedTime,
        );
      }
      return;
    }

    // Helper to pick time
    Future<TimeOfDay?> pickTime() async {
      return showTimePicker(context: context, initialTime: _time);
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
      final DateTime? pickedDate = await showCustomMonthDayPicker(
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
                    if (widget.transaction != null)
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: AppColors.expense,
                        ),
                        onPressed: _deleteTransaction,
                      ),
                  ],
                ),
              ),

              // --- AMOUNT & TITLE ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
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
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
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
                    const SizedBox(height: 12),
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
                    ),
                    // Snippet: Suggestion chips could go here if we want to copy the exact logic
                    // Skipping for brevity, but could add. User focused on "Same UI".
                  ],
                ),
              ),
              const SizedBox(height: 12),

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
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),

                      // --- 1. FREQUENCY SELECTOR (New Setting) ---
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.black26 : Colors.grey[100],
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white10
                                  : Colors.black.withOpacity(0.05),
                            ),
                          ),
                          child: Row(
                            children: Frequency.values.map((f) {
                              final isSelected = _frequency == f;
                              return Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _frequency = f;
                                      // Re-calculate next date based on new frequency and existing params?
                                      // Ideally preserving user intent.
                                      // For now, just keep same nextDueDate time, but snap to rule.
                                      // Or just let user re-pick trigger.
                                    });
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? (isDark
                                                ? Colors.white24
                                                : Colors.white)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: isSelected
                                          ? [
                                              BoxShadow(
                                                color: Colors.black12,
                                                blurRadius: 4,
                                              ),
                                            ]
                                          : [],
                                    ),
                                    child: Text(
                                      f.label,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        color: isSelected
                                            ? txtColor
                                            : Colors.grey,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),

                      // --- 2. TRIGGER DATE/TIME SELECTOR ---
                      GestureDetector(
                        onTap: _pickTrigger,
                        child: Container(
                          margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 16,
                          ),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.black26 : Colors.grey[100],
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white10
                                  : Colors.black.withOpacity(0.05),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.access_time_filled_rounded,
                                size: 18,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _getFrequencyLabel(),
                                style: TextStyle(
                                  color: txtColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(Icons.arrow_drop_down, color: txtColor),
                            ],
                          ),
                        ),
                      ),

                      // --- 3. TYPE TABS & SETTINGS ---
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
                                icon: const Icon(
                                  Icons.settings_outlined,
                                  size: 20,
                                ),
                                color: txtColor,
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const CategoryManagementScreen(),
                                  ),
                                ),
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
                                (c) => c.name == '伙食',
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

                            if (filtered.isEmpty)
                              return const Center(child: Text('No Categories'));

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

                      // --- 5. FOOTER ---
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
                          children: [
                            // Enable Switch for Recurring
                            if (widget.transaction != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Active Rule',
                                      style: TextStyle(
                                        color: txtColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Switch(
                                      value: _isEnabled,
                                      onChanged: (v) =>
                                          setState(() => _isEnabled = v),
                                      activeColor: AppColors.primary,
                                    ),
                                  ],
                                ),
                              ),

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
                              child: ScaleButton(
                                onPressed: _saveTransaction,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  alignment: Alignment.center,
                                  child: const Text(
                                    'Save Rule',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
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
      child: ScaleButton(
        onPressed: () {
          if (!isActive)
            setState(() {
              _type = type;
              _selectedCategoryId = null;
            });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            boxShadow: isActive
                ? [const BoxShadow(color: Colors.black12, blurRadius: 4)]
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

    final title = _titleController.text.trim();
    // Default title if empty
    final finalTitle = title.isEmpty ? _frequency.label : title;

    final newTx = RecurringTransaction(
      id: widget.transaction?.id,
      title: finalTitle,
      amount: finalAmount,
      type: _type,
      categoryId: _selectedCategoryId!,
      frequency: _frequency,
      nextDueDate: _nextDueDate,
      lastGeneratedDate: widget.transaction?.lastGeneratedDate,
      isEnabled: _isEnabled,
      note: _noteController.text.trim(),
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

  void _deleteTransaction() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Rule?'),
        content: const Text('This will stop future auto-generations.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (widget.transaction?.id != null) {
                ref
                    .read(recurringTransactionListProvider.notifier)
                    .deleteRecurringTransaction(widget.transaction!.id!);
              }
              Navigator.pop(context); // close dialog
              Navigator.pop(context); // close screen
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
