import 'package:equity_tracker/features/category/data/category_model.dart';


class CategoryStatEntity {
  final CategoryModel category;
  final int totalAmount;
  final double percentage;

  const CategoryStatEntity({
    required this.category,
    required this.totalAmount,
    required this.percentage,
  });
}
