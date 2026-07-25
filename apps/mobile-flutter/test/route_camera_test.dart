import 'package:flutter_test/flutter_test.dart';
import 'package:shared_types/shared_types.dart';
import 'package:wuhan_nav/core/map/route_camera.dart';

void main() {
  test('RouteBounds.fromRoutes 合并多条路线几何', () {
    final RouteBounds? bounds = RouteBounds.fromRoutes(<RouteOption>[
      const RouteOption(
        id: 'r1',
        durationSec: 1,
        distanceM: 1,
        tollEstimateYuan: 0,
        tag: 'a',
        summary: '',
        geometry: <Wgs84LngLat>[
          Wgs84LngLat(lng: 114.4, lat: 30.6),
          Wgs84LngLat(lng: 114.3, lat: 30.61),
        ],
      ),
      const RouteOption(
        id: 'r2',
        durationSec: 1,
        distanceM: 1,
        tollEstimateYuan: 0,
        tag: 'b',
        summary: '',
        geometry: <Wgs84LngLat>[Wgs84LngLat(lng: 114.25, lat: 30.62)],
      ),
    ]);

    expect(bounds, isNotNull);
    expect(bounds!.minLng, 114.25);
    expect(bounds.maxLng, 114.4);
  });
}
