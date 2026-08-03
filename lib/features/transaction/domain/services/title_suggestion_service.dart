import 'package:equity_tracker/features/transaction/data/transaction_model.dart';

class TitleSuggestionService {
  final Map<String, int> _frequencyMap = {};

  TitleSuggestionService(List<TransactionModel> transactions) {
    for (final t in transactions) {
      final title = t.title?.trim() ?? '';
      if (title.isNotEmpty) {
        _frequencyMap[title] = (_frequencyMap[title] ?? 0) + 1;
      }
    }
  }

  /// 根據使用者的輸入過濾歷史標題，依據出現頻率降冪排序，最後截取前 limit 筆。
  List<String> getSuggestions(String query, {int limit = 10}) {
    final lowerQuery = query.toLowerCase().trim();

    // 1. 過濾出符合關鍵字的標題
    final filteredTitles = _frequencyMap.keys.where((title) {
      return title.toLowerCase().contains(lowerQuery);
    }).toList();

    // 2. 依照出現頻率降冪排序 (次數多的在前面)
    filteredTitles.sort((a, b) => _frequencyMap[b]!.compareTo(_frequencyMap[a]!));

    // 3. 截取前 limit 筆回傳
    return filteredTitles.take(limit).toList();
  }
}
