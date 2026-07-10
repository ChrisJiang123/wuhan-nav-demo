import 'package:shared_types/shared_types.dart';

/// 地图 BFF 客户端接口。
///
/// 前端一切路由/搜索数据经此 client 访问 BFF，禁止直连 OSRM / tileserver / DB。
abstract class MapApiClient {
  /// GET /route — 驾车路径规划。
  Future<RouteResponse> getRoute({
    required Wgs84LngLat origin,
    required Wgs84LngLat destination,
    bool alternatives = true,
  });

  /// GET /search — POI 搜索。
  Future<SearchResponse> search({
    required String query,
    Wgs84LngLat? near,
  });
}
