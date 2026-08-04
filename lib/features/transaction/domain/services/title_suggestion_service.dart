import 'package:equity_tracker/features/transaction/data/transaction_model.dart';

class TitleSuggestionService {
  final List<String> _frequentTitles;

  TitleSuggestionService(this._frequentTitles);

  /// 根據使用者的輸入過濾歷史標題，截取前 limit 筆。
  List<String> getSuggestions(String query, {int limit = 10}) {
    final lowerQuery = query.toLowerCase().trim();

    // 1. 過濾出符合關鍵字的標題
    final filteredTitles = _frequentTitles.where((title) {
      return title.toLowerCase().contains(lowerQuery);
    }).toList();

    // 2. 截取前 limit 筆回傳
    return filteredTitles.take(limit).toList();
  }
}

