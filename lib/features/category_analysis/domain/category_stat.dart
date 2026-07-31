import 'package:equity_tracker/features/category/data/category_model.dart';


class CategoryStat {
  final CategoryModel category;
  final int totalAmount;
  final double percentage;

  const CategoryStat({
    required this.category,
    required this.totalAmount,
    required this.percentage,
  });
}
