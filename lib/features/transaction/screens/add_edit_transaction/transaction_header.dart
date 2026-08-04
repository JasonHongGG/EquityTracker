import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equity_tracker/core/enums/transaction_type.dart';
import 'package:equity_tracker/core/theme/app_colors.dart';
import 'package:equity_tracker/features/transaction/providers/transaction_notifier.dart';

class TransactionHeader extends ConsumerWidget {
  final TransactionType type;
  final TextEditingController amountController;
  final TextEditingController titleController;
  final FocusNode titleFocusNode;
  final ScrollController suggestionsScrollController;
  final VoidCallback onAmountTap;

  const TransactionHeader({
    super.key,
    required this.type,
    required this.amountController,
    required this.titleController,
    required this.titleFocusNode,
    required this.suggestionsScrollController,
    required this.onAmountTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final txtColor = isDark ? Colors.white : Colors.black;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 0),
      child: Column(
        children: [
          // Amount Display (Tappable)
          GestureDetector(
            onTap: onAmountTap,
            child: IntrinsicWidth(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: (type == TransactionType.income ? AppColors.income : AppColors.expense).withValues(alpha: 0.3),
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
                        amountController.text.isEmpty ? '0' : amountController.text,
                        style: TextStyle(
                          fontSize: 64,
                          fontWeight: FontWeight.bold,
                          color: type == TransactionType.income ? AppColors.income : AppColors.expense,
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
              final suggestionServiceAsync = ref.watch(titleSuggestionServiceProvider);

              return suggestionServiceAsync.when(
                data: (suggestionService) {
                  return Column(
                    children: [
                      TextField(
                        controller: titleController,
                        focusNode: titleFocusNode,
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
                            color: Colors.grey.withValues(alpha: 0.5),
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                      // Suggestion Chips
                      ListenableBuilder(
                        listenable: Listenable.merge([titleController, titleFocusNode]),
                        builder: (context, child) {
                          final value = titleController.text;
                          final displayOptions = suggestionService.getSuggestions(value);

                          if (titleFocusNode.hasFocus && displayOptions.isNotEmpty) {
                            return Container(
                              height: 40,
                              margin: const EdgeInsets.only(top: 4),
                              child: SingleChildScrollView(
                                controller: suggestionsScrollController,
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: displayOptions.map((option) {
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 8.0, bottom: 4.0),
                                      child: ActionChip(
                                        label: Text(option),
                                        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
                                        padding: EdgeInsets.zero,
                                        labelStyle: TextStyle(
                                          fontSize: 13,
                                          color: isDark ? Colors.white70 : Colors.grey[700],
                                          fontWeight: FontWeight.w500,
                                        ),
                                        elevation: 2,
                                        shadowColor: Colors.black.withValues(alpha: 0.1),
                                        side: BorderSide.none,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        onPressed: () {
                                          titleController.text = option;
                                          titleController.selection = TextSelection.fromPosition(
                                            TextPosition(offset: option.length),
                                          );
                                          titleFocusNode.unfocus();
                                        },
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ],
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (e, st) => const SizedBox.shrink(),
              );
            },
          ),
        ],
      ),
    );
  }
}
