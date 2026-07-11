import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/env.dart';
import 'bff_map_api_client.dart';
import 'map_api_client.dart';
import 'mock_map_api_client.dart';
import 'resolving_map_api_client.dart';

/// 最近一次路线请求的数据来源（mock / BFF / BFF 失败回落）。
final mapDataSourceProvider = StateProvider<MapDataSource>(
  (Ref ref) => MapDataSource.mock,
);

/// 当前使用的 [MapApiClient] 实现。
///
/// - `USE_MOCK_MAP_API=true` → 纯 mock。
/// - 有 BFF 地址（含 Debug 下 Android 模拟器自动 `10.0.2.2:3000`）→ 优先 BFF，失败回落 mock。
/// - 否则 → mock。
final mapApiClientProvider = Provider<MapApiClient>((Ref ref) {
  final MockMapApiClient mock = MockMapApiClient();

  if (Env.useMockMapApi || !Env.hasBffTarget) {
    return mock;
  }

  return ResolvingMapApiClient(
    bffBaseUrl: Env.resolvedBffBaseUrl!,
    mockClient: mock,
    onSourceChanged: (MapDataSource source) {
      ref.read(mapDataSourceProvider.notifier).state = source;
    },
  );
});

/// 是否未走 BFF（mock 或回落）。
final useMockMapApiProvider = Provider<bool>((Ref ref) {
  return ref.watch(mapDataSourceProvider) != MapDataSource.bff;
});
