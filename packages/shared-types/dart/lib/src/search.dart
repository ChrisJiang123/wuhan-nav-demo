import 'poi.dart';

class SearchResponse {
  const SearchResponse({required this.pois});

  final List<Poi> pois;

  factory SearchResponse.fromJson(Map<String, dynamic> json) {
    final List<dynamic>? pois = json['pois'] as List<dynamic>?;
    if (pois == null) {
      throw FormatException('SearchResponse missing pois.');
    }
    return SearchResponse(
      pois: pois
          .map((dynamic poi) => Poi.fromJson(poi as Map<String, dynamic>))
          .toList(growable: false),
    );
  }
}
