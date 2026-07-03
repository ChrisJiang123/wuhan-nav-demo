import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../../core/config/app_config.dart';
import '../../../core/map/map_style.dart';
import '../../../core/theme/app_theme.dart';

/// 首页：武汉城区空地图（T04）。
///
/// 目标仅为“启动即可见、可缩放的武汉地图”。定位跟随、路线渲染、路况着色
/// 等分别在 T11/T12 落地，本页不提前实现，避免扩大范围。
class MapPage extends ConsumerStatefulWidget {
  const MapPage({super.key});

  @override
  ConsumerState<MapPage> createState() => _MapPageState();
}

class _MapPageState extends ConsumerState<MapPage> {
  String get _styleJson => buildRasterStyleJson(
        tileUrlTemplate: AppConfig.tileUrlTemplate,
        attribution: AppConfig.attribution,
      );

  @override
  Widget build(BuildContext context) {
    const LngLat center = AppConfig.wuhanCenter;
    return Scaffold(
      body: Stack(
        children: <Widget>[
          MapLibreMap(
            styleString: _styleJson,
            // MapLibre 的 LatLng 是 (lat, lng)；WGS-84 值不做任何偏转转换。
            initialCameraPosition: CameraPosition(
              target: LatLng(center.lat, center.lng),
              zoom: AppConfig.initialZoom,
            ),
            minMaxZoomPreference: const MinMaxZoomPreference(
              AppConfig.minZoom,
              AppConfig.maxZoom,
            ),
            // 定位相关权限与跟随留到 T12，本任务不请求定位。
            myLocationEnabled: false,
            compassEnabled: true,
          ),
          const _AttributionBadge(),
          if (AppConfig.usingPlaceholderTiles) const _PlaceholderTilesBadge(),
        ],
      ),
    );
  }
}

/// OSM 数据署名（ODbL 要求）。
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

/// 明确标注当前用的是演示占位瓦片，而非自建/实时数据。
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
