import 'package:equity_tracker/features/ai/infrastructure/logger/base_file_logger.dart';
import 'package:equity_tracker/features/ai/infrastructure/map/i_map_search_service.dart';

class MapSearchLogger extends BaseFileLogger<Map<String, dynamic>> {
  MapSearchLogger() : super('map');

  @override
  String getFileName() {
    final parts = getTimestampParts();
    return '${parts["yyyymmdd"]}_${parts["hhmmss"]}_map.json';
  }

  void logSearch(String query, List<StoreSearchResult> results) {
    final logData = {
      'timestamp': getLocalISOString(DateTime.now()),
      'query': query,
      'results': results.map((r) => r.toMap()).toList(),
    };

    this.log(logData);
  }
}
