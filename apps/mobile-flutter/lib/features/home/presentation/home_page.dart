import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../../core/config/app_config.dart';
import '../../../core/map/map_style.dart';
import '../../../core/map/route_camera.dart';
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
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  MapLibreMapController? _mapController;
  TripPlannerPhase? _lastPhase;

  /// 当前底部面板占屏比（用于全览 padding 与 attribution 位置）。
  double _sheetExtent = 0.32;

  static const double _sheetMin = 0.22;
  static const double _sheetSearchDefault = 0.32;
  static const double _sheetRoutesDefault = 0.28;

  String get _styleJson => buildRasterStyleJson(
        tileUrlTemplate: AppConfig.tileUrlTemplate,
        attribution: AppConfig.attribution,
      );

  @override
  void dispose() {
    _sheetController.dispose();
    _routeRenderer.dispose();
    super.dispose();
  }

  void _onMapCreated(MapLibreMapController controller) {
    _mapController = controller;
    _routeRenderer.attachController(controller);
  }

  Future<void> _onStyleLoaded() async {
    _routeRenderer.markStyleLoaded();
    await _syncRoutesFromState(animateSheet: false);
  }

  double _sheetBottomPadding(BuildContext context) {
    final double screenHeight = MediaQuery.sizeOf(context).height;
    return screenHeight * _sheetExtent + 24;
  }

  Future<void> _fitRouteOverview() async {
    if (_mapController == null) {
      return;
    }
    final TripPlannerState planner = ref.read(tripPlannerProvider);
    if (planner.routes.isEmpty) {
      return;
    }

    await animateCameraToRouteOverview(
      controller: _mapController!,
      routes: planner.routes,
      top: MediaQuery.paddingOf(context).top + 48,
      bottom: _sheetBottomPadding(context),
    );
  }

  Future<void> _syncRoutesFromState({required bool animateSheet}) async {
    final TripPlannerState planner = ref.read(tripPlannerProvider);
    if (planner.phase != TripPlannerPhase.routes || planner.routes.isEmpty) {
      await _routeRenderer.clear();
      return;
    }

    if (animateSheet && _sheetController.isAttached) {
      await _sheetController.animateTo(
        _sheetRoutesDefault,
        duration: AppMotion.medium,
        curve: Curves.easeOut,
      );
      if (mounted) {
        setState(() => _sheetExtent = _sheetRoutesDefault);
      }
    }

    await _routeRenderer.updateRoutes(
      planner.routes,
      selectedRouteId: planner.selectedRouteId,
    );
    await _fitRouteOverview();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<TripPlannerState>(tripPlannerProvider, (
      TripPlannerState? previous,
      TripPlannerState next,
    ) {
      final bool enteredRoutes =
          previous?.phase != TripPlannerPhase.routes &&
              next.phase == TripPlannerPhase.routes &&
              next.routes.isNotEmpty;

      final bool selectionChanged =
          next.phase == TripPlannerPhase.routes &&
              previous?.selectedRouteId != next.selectedRouteId &&
              previous?.routes.isNotEmpty == true;

      if (enteredRoutes) {
        // ignore: discarded_futures
        _syncRoutesFromState(animateSheet: true);
      } else if (selectionChanged) {
        // 切换选中路线只更新高亮，不抢用户缩放。
        // ignore: discarded_futures
        _routeRenderer.updateRoutes(
          next.routes,
          selectedRouteId: next.selectedRouteId,
        );
      } else if (previous?.routes != next.routes ||
          previous?.phase != next.phase) {
        // ignore: discarded_futures
        _syncRoutesFromState(animateSheet: false);
      }

      if (next.phase == TripPlannerPhase.search &&
          _lastPhase == TripPlannerPhase.routes &&
          _sheetController.isAttached) {
        // ignore: discarded_futures
        _sheetController.animateTo(
          _sheetSearchDefault,
          duration: AppMotion.short,
          curve: Curves.easeOut,
        );
      }
      _lastPhase = next.phase;
    });

    const LngLat center = AppConfig.wuhanCenter;
    final TripPlannerState planner = ref.watch(tripPlannerProvider);
    final bool showRoutesUi = planner.phase == TripPlannerPhase.routes;
    final double initialSheetSize = showRoutesUi
        ? _sheetRoutesDefault
        : _sheetSearchDefault;

    return Scaffold(
      body: Stack(
        children: <Widget>[
          // 地图全屏，手势不受底部面板阻挡（面板只覆盖底部区域）。
          Positioned.fill(
            child: MapLibreMap(
              styleString: _styleJson,
              initialCameraPosition: CameraPosition(
                target: LatLng(center.lat, center.lng),
                zoom: AppConfig.initialZoom,
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
              compassEnabled: true,
              onMapCreated: _onMapCreated,
              onStyleLoadedCallback: _onStyleLoaded,
            ),
          ),
          _AttributionBadge(bottomInset: _sheetBottomPadding(context)),
          if (AppConfig.usingPlaceholderTiles) const _PlaceholderTilesBadge(),
          if (showRoutesUi && planner.routes.isNotEmpty)
            Positioned(
              right: 12,
              bottom: _sheetBottomPadding(context) + 8,
              child: SafeArea(
                top: false,
                child: _OverviewButton(onPressed: _fitRouteOverview),
              ),
            ),
          NotificationListener<DraggableScrollableNotification>(
            onNotification: (DraggableScrollableNotification notification) {
              if ((_sheetExtent - notification.extent).abs() > 0.01) {
                setState(() => _sheetExtent = notification.extent);
              }
              return false;
            },
            child: DraggableScrollableSheet(
              controller: _sheetController,
              initialChildSize: initialSheetSize,
              minChildSize: _sheetMin,
              maxChildSize: 0.86,
              snap: true,
              snapSizes: showRoutesUi
                  ? const <double>[0.22, 0.28, 0.45, 0.86]
                  : const <double>[0.22, 0.32, 0.55, 0.86],
              builder: (BuildContext context, ScrollController scrollController) {
                return TripPlannerSheet(scrollController: scrollController);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewButton extends StatelessWidget {
  const _OverviewButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(20),
      color: Colors.white,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(Icons.fit_screen, size: 18, color: AppColors.brand),
              SizedBox(width: 4),
              Text(
                '全览',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.brand,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AttributionBadge extends StatelessWidget {
  const _AttributionBadge({required this.bottomInset});

  final double bottomInset;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 8,
      bottom: bottomInset,
      child: SafeArea(
        top: false,
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
