import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../models/transaction_model.dart';
import '../models/transaction_type.dart';
import '../models/category_model.dart';
import '../providers/category_provider.dart';
import '../theme/app_colors.dart';

class TransactionItem extends ConsumerWidget {
  final TransactionModel transaction;
  final VoidCallback? onTap;

  const TransactionItem({super.key, required this.transaction, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoryListProvider);

    final category = categoriesAsync.asData?.value.firstWhere(
      (c) => c.id == transaction.categoryId,
      orElse: () => Category(
        id: 'unknown',
        name: 'Unknown',
        iconCodePoint: FontAwesomeIcons.question.codePoint,
        colorValue: Colors.grey.toARGB32(),
        type: transaction.type,
        isSystem: false,
        isEnabled: true,
      ),
    );

    final color = transaction.type == TransactionType.income
        ? AppColors.income
        : AppColors.expense;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.transparent,
          // Removed individual card styling
        ),
        child: Row(
          children: [
            // Icon Bubble
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: category?.color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(category?.iconData, color: category?.color, size: 18),
            ),
            const SizedBox(width: 16),

            // Text Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.title?.isNotEmpty == true
                        ? transaction.title!
                        : (category?.name ?? 'Unknown'),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (transaction.title?.isNotEmpty == true)
                    Text(
                      category?.name ?? '',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  if (transaction.note != null && transaction.note!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        transaction.note!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),

            // Amount
            Text(
              '${transaction.type == TransactionType.income ? '+' : '-'}\$${transaction.amount}',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 16,
                fontFamily: 'Outfit',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
