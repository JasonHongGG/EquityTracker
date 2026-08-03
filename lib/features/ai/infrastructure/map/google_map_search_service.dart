import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equity_tracker/features/ai/infrastructure/map/i_map_search_service.dart';
import 'package:equity_tracker/features/ai/infrastructure/logger/map_search_logger.dart';
import 'package:equity_tracker/features/ai/presentation/controllers/ai_config_controller.dart';

class GoogleMapSearchService implements IMapSearchService {
  final String apiKey;
  final MapSearchLogger logger;

  GoogleMapSearchService({required this.apiKey, required this.logger});

  @override
  Future<List<StoreSearchResult>> search(String query) async {
    if (apiKey.isEmpty) {
      return [];
    }

    try {
      final url = Uri.parse(
          'https://maps.googleapis.com/maps/api/place/textsearch/json?query=\${Uri.encodeComponent(query)}&language=zh-TW&key=\$apiKey');
      
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final parsedData = jsonDecode(response.body);

        if (parsedData['status'] != 'OK' && parsedData['status'] != 'ZERO_RESULTS') {
          print('[GoogleMapSearchService] API Error: \${parsedData["status"]} \${parsedData["error_message"]}');
          return [];
        }

        if (parsedData['status'] == 'ZERO_RESULTS') {
          return [];
        }

        final results = (parsedData['results'] as List).take(5);

        final mappedResults = results.map((result) {
          return StoreSearchResult(
            name: result['name'] ?? '',
            address: result['formatted_address'] ?? '',
            types: (result['types'] as List<dynamic>?)?.map((t) => t.toString()).toList() ?? [],
            rating: result['rating'] ?? 0,
            userRatingsTotal: result['user_ratings_total'] ?? 0,
          );
        }).toList();

        logger.logSearch(query, mappedResults);
        return mappedResults;
      } else {
        print('[GoogleMapSearchService] Request failed with status: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('[GoogleMapSearchService] Error: \$e');
      return [];
    }
  }
}

final mapSearchServiceProvider = Provider<IMapSearchService>((ref) {
  final apiKey = ref.watch(aiConfigControllerProvider).googleMapApiKey;
  return GoogleMapSearchService(
    apiKey: apiKey,
    logger: MapSearchLogger(),
  );
});
