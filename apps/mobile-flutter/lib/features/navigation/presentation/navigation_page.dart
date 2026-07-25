import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:shared_types/shared_types.dart';

import '../../../core/config/app_config.dart';
import '../../../core/map/map_style.dart';
import '../../../core/map/route_camera.dart';
import '../../../core/map/route_line_renderer.dart';
import '../../../core/theme/app_theme.dart';
import '../application/navigation_notifier.dart';
import '../application/navigation_state.dart';
import '../application/route_progress.dart';
import 'widgets/navigation_chrome.dart';

/// 导航态页面（T12）：定位跟随、回中、视角、静音、顶底栏、前台服务保活。
class NavigationPage extends ConsumerStatefulWidget {
  const NavigationPage({
    super.key,
    required this.session,
  });

  final NavigationSession session;

  @override
  ConsumerState<NavigationPage> createState() => _NavigationPageState();
}

class _NavigationPageState extends ConsumerState<NavigationPage> {
  final RouteLineRenderer _routeRenderer = RouteLineRenderer();
  MapLibreMapController? _mapController;
  Circle? _puck;
  bool _styleReady = false;
  Wgs84LngLat? _lastCameraPos;
  double? _lastBearing;

  String get _styleJson => buildRasterStyleJson(
        tileUrlTemplate: AppConfig.tileUrlTemplate,
        attribution: AppConfig.attribution,
      );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // ignore: discarded_futures
      ref.read(navigationProvider.notifier).start(widget.session);
    });
  }

  @override
  void dispose() {
    _routeRenderer.dispose();
    super.dispose();
  }

  void _onMapCreated(MapLibreMapController controller) {
    _mapController = controller;
    _routeRenderer.attachController(controller);
  }

  Future<void> _onStyleLoaded() async {
    _styleReady = true;
    _routeRenderer.markStyleLoaded();
    await _routeRenderer.updateRoutes(
      <RouteOption>[widget.session.route],
      selectedRouteId: widget.session.route.id,
    );
    await _fitOverview();
  }

  Future<void> _fitOverview() async {
    if (_mapController == null) {
      return;
    }
    ref.read(navigationProvider.notifier).setFollowing(false);
    await animateCameraToRouteOverview(
      controller: _mapController!,
      routes: <RouteOption>[widget.session.route],
      top: 120,
      bottom: 160,
    );
  }

  Future<void> _syncCamera(NavigationState nav) async {
    if (!_styleReady || _mapController == null) {
      return;
    }
    final RouteProgress? progress = nav.progress;
    final Wgs84LngLat? pos = progress?.snapped ?? nav.currentPosition;
    if (pos == null || !nav.isFollowing) {
      return;
    }

    final double bearing = nav.perspective == CameraPerspective.headingUp
        ? (progress?.bearingDeg ?? 0)
        : 0;

    // 节流：位移很小且方位变化小时不刷相机，减轻掉帧。
    if (_lastCameraPos != null) {
      final double moved = (pos.lat - _lastCameraPos!.lat).abs() +
          (pos.lng - _lastCameraPos!.lng).abs();
      final double bearingDelta =
          ((_lastBearing ?? bearing) - bearing).abs();
      if (moved < 0.00005 && bearingDelta < 4) {
        return;
      }
    }
    _lastCameraPos = pos;
    _lastBearing = bearing;

    await _mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(pos.lat, pos.lng),
          zoom: 16,
          bearing: bearing,
          tilt: nav.perspective == CameraPerspective.headingUp ? 45 : 0,
        ),
      ),
    );
  }

  Future<void> _syncPuck(NavigationState nav) async {
    if (!_styleReady || _mapController == null) {
      return;
    }
    final Wgs84LngLat? pos = nav.progress?.snapped ?? nav.currentPosition;
    if (pos == null) {
      return;
    }
    final LatLng latLng = LatLng(pos.lat, pos.lng);
    if (_puck == null) {
      _puck = await _mapController!.addCircle(
        CircleOptions(
          geometry: latLng,
          circleRadius: 8,
          circleColor: '#1570EF',
          circleStrokeWidth: 3,
          circleStrokeColor: '#FFFFFF',
        ),
      );
    } else {
      await _mapController!.updateCircle(
        _puck!,
        CircleOptions(geometry: latLng),
      );
    }
  }

  Future<void> _endNavigation() async {
    await ref.read(navigationProvider.notifier).stop();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<NavigationState>(navigationProvider, (
      NavigationState? previous,
      NavigationState next,
    ) {
      final bool moved = previous?.currentPosition != next.currentPosition ||
          previous?.progress?.snapped != next.progress?.snapped ||
          previous?.isFollowing != next.isFollowing ||
          previous?.perspective != next.perspective;
      if (moved) {
        // ignore: discarded_futures
        _syncCamera(next);
        // ignore: discarded_futures
        _syncPuck(next);
      }
    });

    final LngLat fallback = widget.session.route.geometry.isNotEmpty
        ? LngLat(
            lng: widget.session.route.geometry.first.lng,
            lat: widget.session.route.geometry.first.lat,
          )
        : AppConfig.wuhanCenter;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        await ref.read(navigationProvider.notifier).stop();
      },
      child: Scaffold(
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: MapLibreMap(
              styleString: _styleJson,
              initialCameraPosition: CameraPosition(
                target: LatLng(fallback.lat, fallback.lng),
                zoom: 14,
              ),
              minMaxZoomPreference: const MinMaxZoomPreference(
                AppConfig.minZoom,
                AppConfig.maxZoom,
              ),
              scrollGesturesEnabled: true,
              zoomGesturesEnabled: true,
              rotateGesturesEnabled: true,
              tiltGesturesEnabled: true,
              myLocationEnabled: false,
              compassEnabled: false,
              onMapCreated: _onMapCreated,
              onStyleLoadedCallback: _onStyleLoaded,
            ),
          ),
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: NavigationTopBanner(),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: NavigationBottomBar(
              onOverview: _fitOverview,
              onEnd: _endNavigation,
            ),
          ),
          if (AppConfig.usingPlaceholderTiles)
            const Positioned(
              left: 8,
              top: 120,
              child: _DemoTileHint(),
            ),
        ],
      ),
    ),
    );
  }
}

class _DemoTileHint extends StatelessWidget {
  const _DemoTileHint();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          '演示占位瓦片',
          style: TextStyle(color: Colors.white, fontSize: 11),
        ),
      ),
    );
  }
}
