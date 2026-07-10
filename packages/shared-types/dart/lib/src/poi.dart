import 'wgs84_lng_lat.dart';

class Poi {
  const Poi({
    required this.id,
    required this.name,
    required this.category,
    required this.location,
  });

  final String id;
  final String name;
  final String category;
  final Wgs84LngLat location;

  factory Poi.fromJson(Map<String, dynamic> json) {
    final String? id = json['id'] as String?;
    final String? name = json['name'] as String?;
    final String? category = json['category'] as String?;
    final List<dynamic>? location = json['location'] as List<dynamic>?;
    if (id == null || name == null || category == null || location == null) {
      throw FormatException('POI fields are invalid.');
    }
    return Poi(
      id: id,
      name: name,
      category: category,
      location: Wgs84LngLat.fromJson(location),
    );
  }
}
