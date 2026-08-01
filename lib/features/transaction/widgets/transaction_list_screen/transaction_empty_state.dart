import 'package:flutter/material.dart';

class TransactionEmptyState extends StatelessWidget {
  const TransactionEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return const SliverFillRemaining(
      child: Center(
        child: Text(
          'No transactions recently.',
          style: TextStyle(
            fontFamily: 'Outfit',
            color: Colors.grey,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
