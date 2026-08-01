import 'dart:io';

void main() {
  final dir = Directory('lib');
  final files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));

  for (final file in files) {
    String content = file.readAsStringSync();
    bool changed = false;

    if (content.contains('features/category_analysis/')) {
      content = content.replaceAll(
          'package:equity_tracker/features/category_analysis/domain/',
          'package:equity_tracker/features/stats/domain/');
      content = content.replaceAll(
          'package:equity_tracker/features/category_analysis/presentation/providers/',
          'package:equity_tracker/features/stats/presentation/providers/');
      content = content.replaceAll(
          'package:equity_tracker/features/category_analysis/presentation/widgets/',
          'package:equity_tracker/features/stats/presentation/widgets/stats_screen/');
      changed = true;
    }

    if (content.contains('features/trend_analysis/')) {
      content = content.replaceAll(
          'package:equity_tracker/features/trend_analysis/domain/',
          'package:equity_tracker/features/stats/domain/');
      content = content.replaceAll(
          'package:equity_tracker/features/trend_analysis/presentation/providers/',
          'package:equity_tracker/features/stats/presentation/providers/');
      content = content.replaceAll(
          'package:equity_tracker/features/trend_analysis/presentation/widgets/',
          'package:equity_tracker/features/stats/presentation/widgets/stats_screen/');
      changed = true;
    }

    if (changed) {
      file.writeAsStringSync(content);
      print('Updated imports in ${file.path}');
    }
  }
}
