import 'wgs84_lng_lat.dart';

class RouteOption {
  const RouteOption({
    required this.id,
    required this.durationSec,
    required this.distanceM,
    required this.tollEstimateYuan,
    required this.tag,
    required this.summary,
    required this.geometry,
  });

  final String id;
  final int durationSec;
  final int distanceM;
  final num tollEstimateYuan;
  final String tag;
  final String summary;
  final List<Wgs84LngLat> geometry;

  factory RouteOption.fromJson(Map<String, dynamic> json) {
    final String? id = json['id'] as String?;
    final num? durationSec = json['durationSec'] as num?;
    final num? distanceM = json['distanceM'] as num?;
    final num? tollEstimateYuan = json['tollEstimateYuan'] as num?;
    final String? tag = json['tag'] as String?;
    final String? summary = json['summary'] as String?;
    final List<dynamic>? geometry = json['geometry'] as List<dynamic>?;
    if (id == null ||
        durationSec == null ||
        distanceM == null ||
        tollEstimateYuan == null ||
        tag == null ||
        summary == null ||
        geometry == null) {
      throw FormatException('RouteOption fields are invalid.');
    }
    return RouteOption(
      id: id,
      durationSec: durationSec.round(),
      distanceM: distanceM.round(),
      tollEstimateYuan: tollEstimateYuan,
      tag: tag,
      summary: summary,
      geometry: geometry
          .map((dynamic point) => Wgs84LngLat.fromJson(point as List<dynamic>))
          .toList(growable: false),
    );
  }
}

class RouteResponse {
  const RouteResponse({required this.routes});

  final List<RouteOption> routes;

  factory RouteResponse.fromJson(Map<String, dynamic> json) {
    final List<dynamic>? routes = json['routes'] as List<dynamic>?;
    if (routes == null) {
      throw FormatException('RouteResponse missing routes.');
    }
    return RouteResponse(
      routes: routes
          .map((dynamic route) =>
              RouteOption.fromJson(route as Map<String, dynamic>))
          .toList(growable: false),
    );
  }
}
