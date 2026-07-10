import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:shared_types/shared_types.dart';

import '../../../core/config/app_config.dart';
import '../../../core/map/map_style.dart';
import '../../../core/map/route_line_renderer.dart';
import '../../../core/theme/app_theme.dart';
import '../../trip/application/trip_planner_notifier.dart';
import '../../trip/application/trip_planner_state.dart';
import '../../trip/presentation/widgets/trip_planner_sheet.dart';

/// 首页：地图常驻 + 底部可拖拽行程面板（T09）。
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final RouteLineRenderer _routeRenderer = RouteLineRenderer();
  MapLibreMapController? _mapController;
  TripPlannerPhase? _lastPhase;

  String get _styleJson => buildRasterStyleJson(
        tileUrlTemplate: AppConfig.tileUrlTemplate,
        attribution: AppConfig.attribution,
      );

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
    _routeRenderer.markStyleLoaded();
    await _syncRoutesFromState();
  }

  Future<void> _syncRoutesFromState() async {
    final TripPlannerState planner = ref.read(tripPlannerProvider);
    if (planner.phase != TripPlannerPhase.routes || planner.routes.isEmpty) {
      await _routeRenderer.clear();
      return;
    }
    await _routeRenderer.updateRoutes(
      planner.routes,
      selectedRouteId: planner.selectedRouteId,
    );
    await _fitCameraToRoutes(planner.routes, planner.selectedRouteId);
  }

  Future<void> _fitCameraToRoutes(
    List<RouteOption> routes,
    String? selectedRouteId,
  ) async {
    if (_mapController == null || routes.isEmpty) {
      return;
    }

    RouteOption? target;
    for (final RouteOption route in routes) {
      if (route.id == selectedRouteId) {
        target = route;
        break;
      }
    }
    target ??= routes.first;
    if (target.geometry.isEmpty) {
      return;
    }

    double minLat = target.geometry.first.lat;
    double maxLat = minLat;
    double minLng = target.geometry.first.lng;
    double maxLng = minLng;

    for (final Wgs84LngLat point in target.geometry) {
      minLat = math.min(minLat, point.lat);
      maxLat = math.max(maxLat, point.lat);
      minLng = math.min(minLng, point.lng);
      maxLng = math.max(maxLng, point.lng);
    }

    final double centerLat = (minLat + maxLat) / 2;
    final double centerLng = (minLng + maxLng) / 2;
    final double span = math.max(maxLat - minLat, maxLng - minLng);
    final double zoom = span > 0.25
        ? 10.5
        : span > 0.12
            ? 11.5
            : 12.5;

    await _mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(centerLat, centerLng),
          zoom: zoom,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<TripPlannerState>(tripPlannerProvider, (
      TripPlannerState? previous,
      TripPlannerState next,
    ) {
      final bool routesChanged = previous?.routes != next.routes ||
          previous?.selectedRouteId != next.selectedRouteId ||
          previous?.phase != next.phase;
      if (routesChanged) {
        // ignore: discarded_futures
        _syncRoutesFromState();
      }

      if (_lastPhase != next.phase && next.phase == TripPlannerPhase.routes) {
        // 进入路线态时略微抬高面板（由 DraggableScrollableSheet 默认 snap 处理）。
      }
      _lastPhase = next.phase;
    });

    const LngLat center = AppConfig.wuhanCenter;
    final TripPlannerState planner = ref.watch(tripPlannerProvider);
    final double initialSheetSize =
        planner.phase == TripPlannerPhase.routes ? 0.52 : 0.38;

    return Scaffold(
      body: Stack(
        children: <Widget>[
          MapLibreMap(
            styleString: _styleJson,
            initialCameraPosition: CameraPosition(
              target: LatLng(center.lat, center.lng),
              zoom: AppConfig.initialZoom,
            ),
            minMaxZoomPreference: const MinMaxZoomPreference(
              AppConfig.minZoom,
              AppConfig.maxZoom,
            ),
            myLocationEnabled: false,
            compassEnabled: true,
            onMapCreated: _onMapCreated,
            onStyleLoadedCallback: _onStyleLoaded,
          ),
          const _AttributionBadge(),
          if (AppConfig.usingPlaceholderTiles) const _PlaceholderTilesBadge(),
          DraggableScrollableSheet(
            key: ValueKey<TripPlannerPhase>(planner.phase),
            initialChildSize: initialSheetSize,
            minChildSize: 0.22,
            maxChildSize: 0.86,
            snap: true,
            snapSizes: planner.phase == TripPlannerPhase.routes
                ? const <double>[0.38, 0.52, 0.86]
                : const <double>[0.28, 0.38, 0.62],
            builder: (BuildContext context, ScrollController scrollController) {
              return TripPlannerSheet(scrollController: scrollController);
            },
          ),
        ],
      ),
    );
  }
}

class _AttributionBadge extends StatelessWidget {
  const _AttributionBadge();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 8,
      bottom: 8,
      child: SafeArea(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            child: Text(
              AppConfig.attribution,
              style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
            ),
          ),
        ),
      ),
    );
  }
}

class _PlaceholderTilesBadge extends StatelessWidget {
  const _PlaceholderTilesBadge();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 8,
      top: 8,
      child: SafeArea(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Text(
              '演示占位瓦片（非自建/非实时）',
              style: TextStyle(
                fontSize: 11,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
