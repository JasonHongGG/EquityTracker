import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:equity_tracker/features/ai/infrastructure/map/i_map_search_service.dart';

class GoogleMapSearchService implements IMapSearchService {
  final String apiKey;

  GoogleMapSearchService(this.apiKey);

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

        final results = (parsedData['results'] as List).take(5).map((place) {
          return StoreSearchResult(
            name: place['name'] ?? '',
            address: place['formatted_address'] ?? '',
            rating: place['rating'] ?? 0,
            userRatingsTotal: place['user_ratings_total'] ?? 0,
            types: List<String>.from(place['types'] ?? []),
          );
        }).toList();

        return results;
      } else {
        print('[GoogleMapSearchService] Request failed with status: \${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('[GoogleMapSearchService] Error: \$e');
      return [];
    }
  }
}
