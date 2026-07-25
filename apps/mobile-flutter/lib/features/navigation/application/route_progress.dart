import 'dart:math' as math;

import 'package:shared_types/shared_types.dart';

/// 沿路线几何推算进度（纯函数，便于单测）。
///
/// T12 无 OSRM steps 时，用折线局部方位变化近似「下一动作」。
/// 真实车道级引导不在本周范围。
class RouteProgress {
  const RouteProgress({
    required this.snapped,
    required this.segmentIndex,
    required this.traveledDistanceM,
    required this.remainingDistanceM,
    required this.remainingDurationSec,
    required this.bearingDeg,
    required this.nextActionText,
    required this.arrived,
  });

  final Wgs84LngLat snapped;
  final int segmentIndex;
  final double traveledDistanceM;
  final double remainingDistanceM;
  final int remainingDurationSec;
  final double bearingDeg;
  final String nextActionText;
  final bool arrived;
}

RouteProgress computeRouteProgress({
  required List<Wgs84LngLat> geometry,
  required Wgs84LngLat current,
  required int totalDistanceM,
  required int totalDurationSec,
  double arriveThresholdM = 40,
}) {
  if (geometry.length < 2) {
    final Wgs84LngLat point = geometry.isEmpty ? current : geometry.first;
    return RouteProgress(
      snapped: point,
      segmentIndex: 0,
      traveledDistanceM: 0,
      remainingDistanceM: totalDistanceM.toDouble(),
      remainingDurationSec: totalDurationSec,
      bearingDeg: 0,
      nextActionText: '沿当前路线继续行驶',
      arrived: false,
    );
  }

  final _SnapResult snap = _snapToPolyline(geometry, current);
  final double totalGeom = _polylineLengthM(geometry);
  final double remainingGeom = math.max(0, totalGeom - snap.distanceAlongM);
  final double scale = totalGeom > 0 ? totalDistanceM / totalGeom : 1.0;
  final double remainingDistanceM = remainingGeom * scale;
  final double traveledDistanceM =
      math.max(0, totalDistanceM - remainingDistanceM);

  final int remainingDurationSec = totalDistanceM <= 0
      ? 0
      : ((remainingDistanceM / totalDistanceM) * totalDurationSec)
          .round()
          .clamp(0, totalDurationSec);

  final bool arrived = remainingDistanceM <= arriveThresholdM;
  final double bearing = _segmentBearing(
    geometry[snap.segmentIndex],
    geometry[math.min(snap.segmentIndex + 1, geometry.length - 1)],
  );

  return RouteProgress(
    snapped: snap.point,
    segmentIndex: snap.segmentIndex,
    traveledDistanceM: traveledDistanceM,
    remainingDistanceM: remainingDistanceM,
    remainingDurationSec: remainingDurationSec,
    bearingDeg: bearing,
    nextActionText: arrived
        ? '已到达目的地附近'
        : _nextActionHint(geometry, snap),
    arrived: arrived,
  );
}

class _SnapResult {
  const _SnapResult({
    required this.point,
    required this.segmentIndex,
    required this.distanceAlongM,
  });

  final Wgs84LngLat point;
  final int segmentIndex;
  final double distanceAlongM;
}

_SnapResult _snapToPolyline(List<Wgs84LngLat> geometry, Wgs84LngLat current) {
  double bestDist = double.infinity;
  Wgs84LngLat bestPoint = geometry.first;
  int bestSeg = 0;
  double bestAlong = 0;
  double prefix = 0;

  for (int i = 0; i < geometry.length - 1; i++) {
    final Wgs84LngLat a = geometry[i];
    final Wgs84LngLat b = geometry[i + 1];
    final _Projected projected = _projectOnSegment(current, a, b);
    final double d = distanceMeters(current, projected.point);
    if (d < bestDist) {
      bestDist = d;
      bestPoint = projected.point;
      bestSeg = i;
      bestAlong = prefix + projected.distanceFromStartM;
    }
    prefix += distanceMeters(a, b);
  }

  return _SnapResult(
    point: bestPoint,
    segmentIndex: bestSeg,
    distanceAlongM: bestAlong,
  );
}

class _Projected {
  const _Projected({
    required this.point,
    required this.distanceFromStartM,
  });

  final Wgs84LngLat point;
  final double distanceFromStartM;
}

_Projected _projectOnSegment(
  Wgs84LngLat p,
  Wgs84LngLat a,
  Wgs84LngLat b,
) {
  final double ax = a.lng;
  final double ay = a.lat;
  final double bx = b.lng;
  final double by = b.lat;
  final double px = p.lng;
  final double py = p.lat;

  final double dx = bx - ax;
  final double dy = by - ay;
  final double len2 = dx * dx + dy * dy;
  if (len2 <= 0) {
    return _Projected(point: a, distanceFromStartM: 0);
  }

  double t = ((px - ax) * dx + (py - ay) * dy) / len2;
  t = t.clamp(0.0, 1.0);
  final Wgs84LngLat point = Wgs84LngLat(
    lng: ax + dx * t,
    lat: ay + dy * t,
  );
  return _Projected(
    point: point,
    distanceFromStartM: distanceMeters(a, point),
  );
}

double _polylineLengthM(List<Wgs84LngLat> geometry) {
  double sum = 0;
  for (int i = 0; i < geometry.length - 1; i++) {
    sum += distanceMeters(geometry[i], geometry[i + 1]);
  }
  return sum;
}

/// Haversine 距离（米）。坐标为 WGS-84，不做偏转。
double distanceMeters(Wgs84LngLat a, Wgs84LngLat b) {
  const double earthRadiusM = 6371000;
  final double lat1 = a.lat * math.pi / 180;
  final double lat2 = b.lat * math.pi / 180;
  final double dLat = (b.lat - a.lat) * math.pi / 180;
  final double dLng = (b.lng - a.lng) * math.pi / 180;
  final double h = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(lat1) * math.cos(lat2) * math.sin(dLng / 2) * math.sin(dLng / 2);
  return 2 * earthRadiusM * math.asin(math.sqrt(h));
}

double _segmentBearing(Wgs84LngLat from, Wgs84LngLat to) {
  final double lat1 = from.lat * math.pi / 180;
  final double lat2 = to.lat * math.pi / 180;
  final double dLng = (to.lng - from.lng) * math.pi / 180;
  final double y = math.sin(dLng) * math.cos(lat2);
  final double x = math.cos(lat1) * math.sin(lat2) -
      math.sin(lat1) * math.cos(lat2) * math.cos(dLng);
  final double bearing = math.atan2(y, x) * 180 / math.pi;
  return (bearing + 360) % 360;
}

double _normalizeDelta(double deg) {
  double d = deg % 360;
  if (d > 180) {
    d -= 360;
  }
  if (d < -180) {
    d += 360;
  }
  return d;
}

String _nextActionHint(List<Wgs84LngLat> geometry, _SnapResult snap) {
  double ahead = 0;
  double prevBearing = _segmentBearing(
    geometry[snap.segmentIndex],
    geometry[math.min(snap.segmentIndex + 1, geometry.length - 1)],
  );

  for (int i = snap.segmentIndex; i < geometry.length - 1; i++) {
    final Wgs84LngLat a = geometry[i];
    final Wgs84LngLat b = geometry[i + 1];
    final double segLen = distanceMeters(a, b);
    final double bearing = _segmentBearing(a, b);
    final double delta = _normalizeDelta(bearing - prevBearing);

    if (i > snap.segmentIndex && delta.abs() >= 35) {
      final String turn = delta > 0 ? '右转' : '左转';
      final int meters = ahead.round().clamp(20, 9999);
      if (meters < 1000) {
        return '约 ${meters}m 后$turn';
      }
      return '约 ${(meters / 1000).toStringAsFixed(1)}公里后$turn';
    }

    ahead += segLen;
    prevBearing = bearing;
    if (ahead > 3000) {
      break;
    }
  }

  final int meters = ahead.round().clamp(50, 9999);
  if (meters >= 1000) {
    return '继续沿当前道路行驶约 ${(meters / 1000).toStringAsFixed(1)}公里';
  }
  return '继续沿当前道路行驶约 ${meters}m';
}
