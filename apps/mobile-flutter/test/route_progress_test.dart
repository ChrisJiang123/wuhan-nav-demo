import 'package:flutter_test/flutter_test.dart';
import 'package:shared_types/shared_types.dart';
import 'package:wuhan_nav/features/navigation/application/route_progress.dart';

void main() {
  final List<Wgs84LngLat> geometry = <Wgs84LngLat>[
    const Wgs84LngLat(lng: 114.42, lat: 30.60),
    const Wgs84LngLat(lng: 114.35, lat: 30.60),
    const Wgs84LngLat(lng: 114.30, lat: 30.61),
    const Wgs84LngLat(lng: 114.25, lat: 30.62),
  ];

  test('起点附近剩余接近全程', () {
    final RouteProgress progress = computeRouteProgress(
      geometry: geometry,
      current: geometry.first,
      totalDistanceM: 20000,
      totalDurationSec: 1000,
    );
    expect(progress.remainingDistanceM, greaterThan(15000));
    expect(progress.remainingDurationSec, greaterThan(700));
    expect(progress.arrived, isFalse);
    expect(progress.nextActionText, isNotEmpty);
  });

  test('终点附近判定到达', () {
    final RouteProgress progress = computeRouteProgress(
      geometry: geometry,
      current: geometry.last,
      totalDistanceM: 20000,
      totalDurationSec: 1000,
      arriveThresholdM: 50,
    );
    expect(progress.remainingDistanceM, lessThan(50));
    expect(progress.arrived, isTrue);
    expect(progress.nextActionText, contains('到达'));
  });

  test('distanceMeters 量级合理', () {
    final double d = distanceMeters(
      const Wgs84LngLat(lng: 114.4249, lat: 30.6073),
      const Wgs84LngLat(lng: 114.2546, lat: 30.618),
    );
    // 武汉站→汉口站直线约 16km 量级
    expect(d, greaterThan(14000));
    expect(d, lessThan(20000));
  });
}
