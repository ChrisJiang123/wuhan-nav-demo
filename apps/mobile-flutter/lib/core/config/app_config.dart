import 'env.dart';

/// WGS-84 经纬度坐标。
///
/// 全链路统一 WGS-84，`[lng, lat]` 顺序，禁止任何 GCJ-02 / BD-09 坐标转换。
/// 注意：MapLibre 的 `LatLng` 是 `(lat, lng)` 顺序，转换只在地图边界处发生，
/// 见 [features/map] 内的用法，不引入坐标系偏转。
class LngLat {
  const LngLat({required this.lng, required this.lat});

  final double lng;
  final double lat;
}

/// 应用级静态配置（非密钥）。
class AppConfig {
  const AppConfig._();

  /// 武汉城区中心（WGS-84）。无定位权限时回落到此处。
  static const LngLat wuhanCenter = LngLat(lng: 114.305393, lat: 30.593099);

  /// 初始/默认缩放级别。
  static const double initialZoom = 11.0;
  static const double minZoom = 3.0;
  static const double maxZoom = 19.0;

  /// 占位瓦片源（OpenStreetMap 栅格，开放数据）。
  ///
  /// 仅用于 T04 演示“空地图可见”；生产改走 BFF `/tiles`（矢量瓦片）。
  /// 使用需署名：© OpenStreetMap contributors（ODbL）。
  static const String placeholderTileTemplate =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  static const String attribution = '© OpenStreetMap contributors';

  /// 实际使用的瓦片模板：优先环境注入（BFF），否则回落占位源。
  static String get tileUrlTemplate =>
      Env.tilesUrlTemplate.isNotEmpty
          ? Env.tilesUrlTemplate
          : placeholderTileTemplate;

  /// 是否正在使用占位瓦片源（用于 UI 上明确标注“演示占位”）。
  static bool get usingPlaceholderTiles => Env.tilesUrlTemplate.isEmpty;
}
