/// WGS-84 longitude/latitude coordinate pair.
///
/// Tuple order is always [lng, lat]. Do not pass GCJ-02 or BD-09 coordinates.
class Wgs84LngLat {
  const Wgs84LngLat({required this.lng, required this.lat});

  final double lng;
  final double lat;

  /// BFF query parameter format: `lng,lat`.
  String toQueryParam() => '$lng,$lat';

  /// Normalize for fixture / mock coordinate matching (4 decimal places).
  String toMatchKey() => '${lng.toStringAsFixed(4)},${lat.toStringAsFixed(4)}';

  /// JSON array `[lng, lat]`.
  List<double> toJson() => <double>[lng, lat];

  factory Wgs84LngLat.fromJson(List<dynamic> json) {
    if (json.length != 2) {
      throw FormatException('WGS-84 location must be [lng, lat].');
    }
    final double lng = _requireFinite(json[0], 'lng');
    final double lat = _requireFinite(json[1], 'lat');
    _assertValidRange(lng, lat);
    return Wgs84LngLat(lng: lng, lat: lat);
  }

  /// Parse BFF query parameter `lng,lat`.
  factory Wgs84LngLat.fromQueryParam(String value) {
    final List<String> parts = value.split(',');
    if (parts.length != 2) {
      throw FormatException('Coordinate must use lng,lat order.');
    }
    final double lng = _requireFinite(parts[0], 'lng');
    final double lat = _requireFinite(parts[1], 'lat');
    _assertValidRange(lng, lat);
    return Wgs84LngLat(lng: lng, lat: lat);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Wgs84LngLat &&
          other.lng.toStringAsFixed(4) == lng.toStringAsFixed(4) &&
          other.lat.toStringAsFixed(4) == lat.toStringAsFixed(4);

  @override
  int get hashCode => Object.hash(
        lng.toStringAsFixed(4),
        lat.toStringAsFixed(4),
      );

  @override
  String toString() => 'Wgs84LngLat($lng, $lat)';
}

double _requireFinite(Object? value, String name) {
  final double? parsed = value is num ? value.toDouble() : double.tryParse('$value');
  if (parsed == null || !parsed.isFinite) {
    throw FormatException('$name must be a finite number.');
  }
  return parsed;
}

void _assertValidRange(double lng, double lat) {
  if (lng < -180 || lng > 180 || lat < -90 || lat > 90) {
    throw FormatException('Coordinate must be valid WGS-84 [lng, lat].');
  }
}
