import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_types/shared_types.dart';

import 'map_api_client.dart';
import 'map_api_exception.dart';

/// 基于 `packages/test-fixtures` 的离线 mock 客户端。
///
/// mock 路线/POI 量级贴近 T03 实测（武汉站→汉口站 19884m、武昌站→黄鹤楼 3001m、
/// 汉口站→光谷 24438m 含备选）。`id`/`summary` 带 `mock` 前缀便于与真实联调区分。
class MockMapApiClient implements MapApiClient {
  MockMapApiClient({
    Future<String> Function(String assetPath)? assetLoader,
    List<RouteFixture>? routeFixtures,
    List<PoiFixture>? poiFixtures,
  })  : _assetLoader = assetLoader ?? rootBundle.loadString,
        _routeFixtures = routeFixtures,
        _poiFixtures = poiFixtures;

  static const String routesAssetPath =
      'packages/test_fixtures/assets/wuhan-routes.json';
  static const String poisAssetPath =
      'packages/test_fixtures/assets/wuhan-pois.json';

  final Future<String> Function(String assetPath) _assetLoader;
  List<RouteFixture>? _routeFixtures;
  List<PoiFixture>? _poiFixtures;

  @override
  Future<RouteResponse> getRoute({
    required Wgs84LngLat origin,
    required Wgs84LngLat destination,
    bool alternatives = true,
  }) async {
    final List<RouteFixture> fixtures = await _loadRouteFixtures();
    final String originKey = origin.toMatchKey();
    final String destinationKey = destination.toMatchKey();

    for (final RouteFixture fixture in fixtures) {
      if (fixture.origin.toMatchKey() == originKey &&
          fixture.destination.toMatchKey() == destinationKey) {
        final List<RouteOption> routes = alternatives
            ? fixture.response.routes
            : fixture.response.routes.take(1).toList(growable: false);
        return RouteResponse(routes: routes);
      }
    }

    throw MapApiException(
      code: 'ROUTE_NOT_FOUND',
      message:
          'mock 未覆盖该起终点（$originKey → $destinationKey）。'
          '请使用 fixtures 中的武汉站/汉口站/武昌站/黄鹤楼/光谷坐标。',
    );
  }

  @override
  Future<SearchResponse> search({
    required String query,
    Wgs84LngLat? near,
  }) async {
    final String trimmed = query.trim();
    if (trimmed.isEmpty) {
      throw const MapApiException(
        code: 'INVALID_QUERY',
        message: 'q is required.',
      );
    }

    final List<PoiFixture> fixtures = await _loadPoiFixtures();
    final String normalizedQuery = _normalizeSearchText(trimmed);
    final List<_ScoredPoi> scored = fixtures
        .map((PoiFixture poi) => _ScoredPoi(
              poi: poi,
              score: _scorePoi(poi, normalizedQuery, near),
            ))
        .where((_ScoredPoi item) => item.score > 0)
        .toList()
      ..sort((_ScoredPoi a, _ScoredPoi b) => b.score.compareTo(a.score));

    return SearchResponse(
      pois: scored
          .take(10)
          .map((_ScoredPoi item) => item.poi.toPoi())
          .toList(growable: false),
    );
  }

  Future<List<RouteFixture>> _loadRouteFixtures() async {
    if (_routeFixtures != null) {
      return _routeFixtures!;
    }
    final String raw = await _assetLoader(routesAssetPath);
    final List<dynamic> json = jsonDecode(raw) as List<dynamic>;
    _routeFixtures = json
        .map((dynamic item) =>
            RouteFixture.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
    return _routeFixtures!;
  }

  Future<List<PoiFixture>> _loadPoiFixtures() async {
    if (_poiFixtures != null) {
      return _poiFixtures!;
    }
    final String raw = await _assetLoader(poisAssetPath);
    final List<dynamic> json = jsonDecode(raw) as List<dynamic>;
    _poiFixtures = json
        .map((dynamic item) => PoiFixture.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
    return _poiFixtures!;
  }

  String _normalizeSearchText(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'\s+'), '');
  }

  int _scorePoi(PoiFixture poi, String normalizedQuery, Wgs84LngLat? near) {
    final String name = _normalizeSearchText(poi.name);
    final String category = _normalizeSearchText(poi.category);
    int score = 0;

    if (name == normalizedQuery) {
      score += 100;
    } else if (name.contains(normalizedQuery)) {
      score += 80;
    }

    for (final String alias in poi.aliases) {
      final String normalizedAlias = _normalizeSearchText(alias);
      if (normalizedAlias == normalizedQuery) {
        score += 70;
        break;
      }
      if (normalizedAlias.contains(normalizedQuery)) {
        score += 50;
        break;
      }
    }

    if (category.contains(normalizedQuery)) {
      score += 20;
    }

    if (score == 0) {
      return 0;
    }

    if (near != null) {
      final double distanceKm = _approximateDistanceKm(near, poi.location);
      score += (20 - distanceKm.clamp(0, 20)).round();
    }

    return score;
  }

  double _approximateDistanceKm(Wgs84LngLat from, Wgs84LngLat to) {
    final double lngDeltaKm = (from.lng - to.lng) *
        111.32 *
        math.cos(((from.lat + to.lat) / 2) * math.pi / 180);
    final double latDeltaKm = (from.lat - to.lat) * 110.57;
    return math.sqrt(lngDeltaKm * lngDeltaKm + latDeltaKm * latDeltaKm);
  }
}

class _ScoredPoi {
  const _ScoredPoi({required this.poi, required this.score});

  final PoiFixture poi;
  final int score;
}

/// 路线 fixture 条目（对应 test-fixtures/wuhan-routes.json）。
class RouteFixture {
  const RouteFixture({
    required this.id,
    required this.origin,
    required this.destination,
    required this.response,
    this.description,
    this.alternatives,
  });

  final String id;
  final String? description;
  final Wgs84LngLat origin;
  final Wgs84LngLat destination;
  final bool? alternatives;
  final RouteResponse response;

  factory RouteFixture.fromJson(Map<String, dynamic> json) {
    return RouteFixture(
      id: json['id'] as String,
      description: json['description'] as String?,
      origin: Wgs84LngLat.fromJson(json['origin'] as List<dynamic>),
      destination: Wgs84LngLat.fromJson(json['destination'] as List<dynamic>),
      alternatives: json['alternatives'] as bool?,
      response:
          RouteResponse.fromJson(json['response'] as Map<String, dynamic>),
    );
  }
}

/// POI fixture 条目（对应 test-fixtures/wuhan-pois.json，含 aliases）。
class PoiFixture {
  const PoiFixture({
    required this.id,
    required this.name,
    required this.category,
    required this.location,
    required this.aliases,
  });

  final String id;
  final String name;
  final String category;
  final Wgs84LngLat location;
  final List<String> aliases;

  Poi toPoi() => Poi(
        id: id,
        name: name,
        category: category,
        location: location,
      );

  factory PoiFixture.fromJson(Map<String, dynamic> json) {
    return PoiFixture(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      location: Wgs84LngLat.fromJson(json['location'] as List<dynamic>),
      aliases: (json['aliases'] as List<dynamic>? ?? const <dynamic>[])
          .map((dynamic alias) => alias as String)
          .toList(growable: false),
    );
  }
}
