import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:shared_types/shared_types.dart';

/// 在地图上绘制备选/选中路线折线（T09 预览级，非 T11 路况着色）。
class RouteLineRenderer {
  MapLibreMapController? _controller;
  final List<Line> _lines = <Line>[];
  List<RouteOption> _routes = <RouteOption>[];
  String? _selectedRouteId;
  bool _styleReady = false;
  bool _pendingUpdate = false;

  void attachController(MapLibreMapController controller) {
    _controller = controller;
  }

  void markStyleLoaded() {
    _styleReady = true;
    if (_pendingUpdate && _routes.isNotEmpty) {
      _pendingUpdate = false;
      // ignore: discarded_futures
      updateRoutes(_routes, selectedRouteId: _selectedRouteId);
    }
  }

  Future<void> updateRoutes(
    List<RouteOption> routes, {
    required String? selectedRouteId,
  }) async {
    _routes = routes;
    _selectedRouteId = selectedRouteId;

    if (!_styleReady || _controller == null) {
      _pendingUpdate = true;
      return;
    }

    await clear();
    if (routes.isEmpty) {
      return;
    }

    for (final RouteOption route in routes) {
      final bool selected = route.id == selectedRouteId;
      final Line line = await _controller!.addLine(
        LineOptions(
          geometry: _toLatLngs(route.geometry),
          lineColor: selected ? '#1570EF' : '#98A2B3',
          lineWidth: selected ? 6 : 3,
          lineOpacity: selected ? 0.95 : 0.45,
          lineJoin: 'round',
          lineCap: 'round',
        ),
        <String, String>{'routeId': route.id},
      );
      _lines.add(line);
    }
  }

  Future<void> clear() async {
    if (_controller == null || _lines.isEmpty) {
      _lines.clear();
      return;
    }
    for (final Line line in _lines) {
      await _controller!.removeLine(line);
    }
    _lines.clear();
  }

  void dispose() {
    _controller = null;
    _lines.clear();
    _routes = <RouteOption>[];
    _selectedRouteId = null;
    _styleReady = false;
    _pendingUpdate = false;
  }

  List<LatLng> _toLatLngs(List<Wgs84LngLat> geometry) {
    return geometry
        .map((Wgs84LngLat point) => LatLng(point.lat, point.lng))
        .toList(growable: false);
  }
}
