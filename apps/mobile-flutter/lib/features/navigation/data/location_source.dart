import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_types/shared_types.dart';

import '../application/route_progress.dart';

/// 定位流抽象：真实 GPS 或沿路线模拟。
abstract class LocationSource {
  Stream<Wgs84LngLat> get positions;
  Future<void> start();
  Future<void> stop();
}

class GpsLocationSource implements LocationSource {
  StreamSubscription<Position>? _sub;
  final StreamController<Wgs84LngLat> _controller =
      StreamController<Wgs84LngLat>.broadcast();

  @override
  Stream<Wgs84LngLat> get positions => _controller.stream;

  @override
  Future<void> start() async {
    await stop();

    final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw StateError('系统定位服务未开启。请在设置中打开位置信息。');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw StateError('定位权限被拒绝。导航需要定位权限才能跟随。');
    }
    if (permission == LocationPermission.deniedForever) {
      throw StateError('定位权限被永久拒绝。请到系统设置中开启。');
    }

    // 先拿一个当前位置，避免等待首个 stream 事件过久。
    try {
      final Position first = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );
      _emit(first);
    } catch (_) {
      // 继续依赖 stream；模拟器可能暂时无位置。
    }

    _sub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 3,
      ),
    ).listen(
      _emit,
      onError: (Object error) {
        if (!_controller.isClosed) {
          _controller.addError(error);
        }
      },
    );
  }

  void _emit(Position position) {
    if (_controller.isClosed) {
      return;
    }
    _controller.add(
      Wgs84LngLat(lng: position.longitude, lat: position.latitude),
    );
  }

  @override
  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
  }

  Future<void> dispose() async {
    await stop();
    await _controller.close();
  }
}

/// Debug：沿路线按匀速插值，便于模拟器验收「跟随」。
class SimulatedRouteLocationSource implements LocationSource {
  SimulatedRouteLocationSource({
    required this.geometry,
    this.speedMps = 18,
    this.tick = const Duration(milliseconds: 500),
  });

  final List<Wgs84LngLat> geometry;
  final double speedMps;
  final Duration tick;

  final StreamController<Wgs84LngLat> _controller =
      StreamController<Wgs84LngLat>.broadcast();
  Timer? _timer;
  double _distanceAlongM = 0;
  late final double _totalLengthM;

  @override
  Stream<Wgs84LngLat> get positions => _controller.stream;

  @override
  Future<void> start() async {
    await stop();
    if (geometry.isEmpty) {
      throw StateError('路线几何为空，无法模拟沿路线移动。');
    }
    _totalLengthM = _length(geometry);
    _distanceAlongM = 0;
    _emitAt(_distanceAlongM);
    _timer = Timer.periodic(tick, (_) {
      _distanceAlongM += speedMps * (tick.inMilliseconds / 1000);
      if (_distanceAlongM >= _totalLengthM) {
        _distanceAlongM = _totalLengthM;
        _emitAt(_distanceAlongM);
        _timer?.cancel();
        return;
      }
      _emitAt(_distanceAlongM);
    });
  }

  void _emitAt(double alongM) {
    if (_controller.isClosed) {
      return;
    }
    _controller.add(_pointAt(geometry, alongM));
  }

  @override
  Future<void> stop() async {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> dispose() async {
    await stop();
    await _controller.close();
  }

  double _length(List<Wgs84LngLat> points) {
    double sum = 0;
    for (int i = 0; i < points.length - 1; i++) {
      sum += distanceMeters(points[i], points[i + 1]);
    }
    return sum <= 0 ? 1 : sum;
  }

  Wgs84LngLat _pointAt(List<Wgs84LngLat> points, double alongM) {
    if (points.length == 1) {
      return points.first;
    }
    double remain = alongM;
    for (int i = 0; i < points.length - 1; i++) {
      final Wgs84LngLat a = points[i];
      final Wgs84LngLat b = points[i + 1];
      final double seg = distanceMeters(a, b);
      if (remain <= seg || i == points.length - 2) {
        final double t = seg <= 0 ? 0 : (remain / seg).clamp(0.0, 1.0);
        return Wgs84LngLat(
          lng: a.lng + (b.lng - a.lng) * t,
          lat: a.lat + (b.lat - a.lat) * t,
        );
      }
      remain -= seg;
    }
    return points.last;
  }
}

/// Debug 默认：模拟器无稳定 GPS 时可用模拟源。真机验收请用 [LocationMode.gps]。
bool preferSimulationByDefault() {
  return kDebugMode;
}
