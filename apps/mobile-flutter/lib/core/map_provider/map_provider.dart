import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/env.dart';
import 'bff_map_api_client.dart';
import 'map_api_client.dart';
import 'mock_map_api_client.dart';

/// 当前使用的 [MapApiClient] 实现。
///
/// - 未配置 `BFF_BASE_URL` 或显式 `--dart-define=USE_MOCK_MAP_API=true` 时用 mock。
/// - 否则走 [BffMapApiClient]（只调 BFF `/route` `/search`）。
final mapApiClientProvider = Provider<MapApiClient>((Ref ref) {
  if (Env.shouldUseMockMapApi) {
    return MockMapApiClient();
  }
  return BffMapApiClient(baseUrl: Env.bffBaseUrl);
});

/// 是否正在使用 mock 客户端（UI 可用来标注「演示数据」）。
final useMockMapApiProvider = Provider<bool>((Ref ref) {
  return Env.shouldUseMockMapApi;
});
