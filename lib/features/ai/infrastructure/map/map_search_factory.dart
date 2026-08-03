import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equity_tracker/features/ai/infrastructure/map/i_map_search_service.dart';
import 'package:equity_tracker/features/ai/infrastructure/map/google_map_search_service.dart';
import 'package:equity_tracker/features/ai/infrastructure/map/logging_map_search_decorator.dart';
import 'package:equity_tracker/features/ai/presentation/controllers/ai_config_controller.dart';

final mapSearchServiceProvider = Provider<IMapSearchService>((ref) {
  final config = ref.watch(aiConfigControllerProvider);
  
  IMapSearchService service;
  
  if (config.googleMapApiKey.isNotEmpty) {
    service = GoogleMapSearchService(config.googleMapApiKey);
  } else {
    // If no key is provided, we just use GoogleMapSearchService with empty key (which handles empty key safely)
    service = GoogleMapSearchService('');
  }

  return LoggingMapSearchDecorator(service);
});
