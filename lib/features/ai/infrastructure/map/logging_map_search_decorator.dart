import 'package:equity_tracker/features/ai/infrastructure/map/i_map_search_service.dart';
import 'package:equity_tracker/features/ai/infrastructure/logger/map_search_logger.dart';

class LoggingMapSearchDecorator implements IMapSearchService {
  final IMapSearchService innerService;
  late final MapSearchLogger logger;

  LoggingMapSearchDecorator(this.innerService) {
    logger = MapSearchLogger();
  }

  @override
  Future<List<StoreSearchResult>> search(String query) async {
    try {
      final results = await innerService.search(query);
      logger.logSearch(query, results);
      return results;
    } catch (error) {
      logger.logSearch(query, []);
      rethrow;
    }
  }
}
