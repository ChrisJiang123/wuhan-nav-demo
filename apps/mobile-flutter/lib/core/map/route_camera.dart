import 'dart:math' as math;

import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:shared_types/shared_types.dart';

/// 从路线几何计算 WGS-84 包围盒（可合并多条路线做全览）。
class RouteBounds {
  const RouteBounds({
    required this.minLat,
    required this.maxLat,
    required this.minLng,
    required this.maxLng,
  });

  final double minLat;
  final double maxLat;
  final double minLng;
  final double maxLng;

  LatLng get southWest => LatLng(minLat, minLng);
  LatLng get northEast => LatLng(maxLat, maxLng);

  LatLngBounds toLatLngBounds() => LatLngBounds(southwest: southWest, northeast: northEast);

  static RouteBounds? fromRoutes(Iterable<RouteOption> routes) {
    bool hasPoint = false;
    double minLat = 0;
    double maxLat = 0;
    double minLng = 0;
    double maxLng = 0;

    for (final RouteOption route in routes) {
      for (final Wgs84LngLat point in route.geometry) {
        if (!hasPoint) {
          minLat = maxLat = point.lat;
          minLng = maxLng = point.lng;
          hasPoint = true;
        } else {
          minLat = math.min(minLat, point.lat);
          maxLat = math.max(maxLat, point.lat);
          minLng = math.min(minLng, point.lng);
          maxLng = math.max(maxLng, point.lng);
        }
      }
    }

    if (!hasPoint) {
      return null;
    }

    // 单点或极短路线时给最小跨度，避免 zoom 过大。
    const double minSpan = 0.008;
    if (maxLat - minLat < minSpan) {
      final double mid = (minLat + maxLat) / 2;
      minLat = mid - minSpan / 2;
      maxLat = mid + minSpan / 2;
    }
    if (maxLng - minLng < minSpan) {
      final double mid = (minLng + maxLng) / 2;
      minLng = mid - minSpan / 2;
      maxLng = mid + minSpan / 2;
    }

    return RouteBounds(
      minLat: minLat,
      maxLat: maxLat,
      minLng: minLng,
      maxLng: maxLng,
    );
  }
}

/// 将相机移动到能看全路线的位置；[bottomPadding] 需扣除底部面板占用高度。
Future<void> animateCameraToRouteOverview({
  required MapLibreMapController controller,
  required Iterable<RouteOption> routes,
  double left = 32,
  double top = 56,
  double right = 32,
  double bottom = 160,
}) async {
  final RouteBounds? bounds = RouteBounds.fromRoutes(routes);
  if (bounds == null) {
    return;
  }

  await controller.animateCamera(
    CameraUpdate.newLatLngBounds(
      bounds.toLatLngBounds(),
      left: left,
      top: top,
      right: right,
      bottom: bottom,
    ),
  );
}
