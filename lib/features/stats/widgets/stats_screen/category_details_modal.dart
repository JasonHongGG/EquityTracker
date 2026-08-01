import 'package:flutter/material.dart';


import 'package:equity_tracker/features/transaction/widgets/common/transaction_item.dart';
import 'package:go_router/go_router.dart';
import 'package:equity_tracker/features/transaction/data/transaction_model.dart';
import 'package:equity_tracker/features/category/data/category_model.dart';

class CategoryDetailsModal {
  static void show(
    BuildContext context,
    CategoryModel category,
    List<TransactionModel> allTransactions,
  ) {
    final categoryTransactions =
        allTransactions.where((t) => t.categoryId == category.id).toList()
          ..sort((a, b) => a.date.compareTo(b.date));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(category.iconData, color: category.color),
                        const SizedBox(width: 10),
                        Text(
                          category.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      controller: scrollController,
                      itemCount: categoryTransactions.length,
                      separatorBuilder: (_, __) => Divider(
                        height: 1,
                        indent: 70,
                        endIndent: 16,
                        color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                      ),
                      itemBuilder: (context, index) {
                        final tx = categoryTransactions[index];
                        return TransactionItem(
                          transaction: tx,
                          onTap: () {
                            context.push(
                              '/add-transaction',
                              extra: {'transaction': tx},
                            );
                          },
                          showDate: true,
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
