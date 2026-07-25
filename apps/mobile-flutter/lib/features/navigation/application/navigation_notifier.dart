import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_types/shared_types.dart';

import '../data/location_source.dart';
import '../data/navigation_foreground_service.dart';
import 'navigation_state.dart';
import 'route_progress.dart';

final navigationProvider =
    NotifierProvider<NavigationNotifier, NavigationState>(
  NavigationNotifier.new,
);

class NavigationNotifier extends Notifier<NavigationState> {
  StreamSubscription<Wgs84LngLat>? _locationSub;
  GpsLocationSource? _gpsSource;
  SimulatedRouteLocationSource? _simSource;

  @override
  NavigationState build() {
    ref.onDispose(() {
      // ignore: discarded_futures
      _teardown();
    });
    return NavigationState(
      locationMode: preferSimulationByDefault()
          ? LocationMode.simulateAlongRoute
          : LocationMode.gps,
    );
  }

  Future<void> start(NavigationSession session) async {
    await _teardown(keepState: true);

    state = state.copyWith(
      session: session,
      isActive: true,
      isFollowing: true,
      clearError: true,
      clearPermissionMessage: true,
      clearProgress: true,
      clearPosition: true,
    );

    final bool fgsOk = await NavigationForegroundService.start(
      destinationName: session.destinationName,
    );
    state = state.copyWith(
      foregroundServiceRunning: fgsOk,
      permissionMessage: fgsOk
          ? null
          : '前台服务未能启动（可能缺通知权限或 OEM 限制）。前台仍可导航，息屏保活需真机验证。',
    );

    await _startLocationSource();
  }

  Future<void> stop() async {
    await _teardown();
    state = const NavigationState();
  }

  void toggleMute() {
    state = state.copyWith(isMuted: !state.isMuted);
  }

  void togglePerspective() {
    final CameraPerspective next =
        state.perspective == CameraPerspective.headingUp
            ? CameraPerspective.northUp
            : CameraPerspective.headingUp;
    state = state.copyWith(perspective: next);
  }

  void setFollowing(bool following) {
    state = state.copyWith(isFollowing: following);
  }

  void recenter() {
    state = state.copyWith(isFollowing: true);
  }

  Future<void> setLocationMode(LocationMode mode) async {
    if (state.locationMode == mode) {
      return;
    }
    state = state.copyWith(locationMode: mode, clearError: true);
    if (state.isActive) {
      await _startLocationSource();
    }
  }

  Future<void> _startLocationSource() async {
    await _locationSub?.cancel();
    _locationSub = null;
    await _gpsSource?.stop();
    await _simSource?.stop();

    final NavigationSession? session = state.session;
    if (session == null) {
      return;
    }

    try {
      final LocationSource source;
      if (state.locationMode == LocationMode.simulateAlongRoute) {
        _simSource = SimulatedRouteLocationSource(
          geometry: session.route.geometry,
        );
        source = _simSource!;
      } else {
        _gpsSource = GpsLocationSource();
        source = _gpsSource!;
      }

      await source.start();
      _locationSub = source.positions.listen(
        _onPosition,
        onError: (Object error) {
          state = state.copyWith(errorMessage: '定位失败：$error');
        },
      );
    } catch (error) {
      state = state.copyWith(
        errorMessage: '$error',
        // Debug 下 GPS 失败时提示可切模拟。
        permissionMessage: kDebugMode &&
                state.locationMode == LocationMode.gps
            ? '可在导航页切换到「模拟沿路线」以便在无 GPS 的模拟器上验收跟随。'
            : null,
      );
    }
  }

  void _onPosition(Wgs84LngLat position) {
    final NavigationSession? session = state.session;
    if (session == null) {
      return;
    }
    final RouteProgress progress = computeRouteProgress(
      geometry: session.route.geometry,
      current: position,
      totalDistanceM: session.route.distanceM,
      totalDurationSec: session.route.durationSec,
    );
    state = state.copyWith(
      currentPosition: position,
      progress: progress,
      clearError: true,
    );
  }

  Future<void> _teardown({bool keepState = false}) async {
    await _locationSub?.cancel();
    _locationSub = null;
    await _gpsSource?.stop();
    await _simSource?.stop();
    await _gpsSource?.dispose();
    await _simSource?.dispose();
    _gpsSource = null;
    _simSource = null;
    await NavigationForegroundService.stop();
    if (!keepState) {
      // caller may replace state
    }
  }
}
