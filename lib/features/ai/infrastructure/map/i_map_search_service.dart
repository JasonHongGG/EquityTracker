class StoreSearchResult {
  final String name;
  final String address;
  final num rating;
  final int userRatingsTotal;
  final List<String> types;

  StoreSearchResult({
    required this.name,
    required this.address,
    required this.rating,
    required this.userRatingsTotal,
    required this.types,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'address': address,
      'rating': rating,
      'userRatingsTotal': userRatingsTotal,
      'types': types,
    };
  }
}

abstract class IMapSearchService {
  Future<List<StoreSearchResult>> search(String query);
}
