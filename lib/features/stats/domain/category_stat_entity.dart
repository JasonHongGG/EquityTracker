import 'package:equity_tracker/features/category/domain/category_entity.dart';

class CategoryStatEntity {
  final CategoryEntity category;
  final int totalAmount;
  final double percentage;

  const CategoryStatEntity({
    required this.category,
    required this.totalAmount,
    required this.percentage,
  });
}
