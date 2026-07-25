import 'package:flutter/foundation.dart';

/// 运行期环境配置。
///
/// 所有外部地址通过 `--dart-define` 注入，禁止硬编码密钥/地址到源码里。
/// 例：
///   flutter run \
///     --dart-define=BFF_BASE_URL=http://10.0.2.2:3000 \
///     --dart-define=TILES_URL_TEMPLATE=http://10.0.2.2:3000/tiles/{z}/{x}/{y}
///
/// 说明：Android 模拟器访问宿主机 localhost 用 `10.0.2.2`。
class Env {
  const Env._();

  /// BFF 基地址。前端一切外部数据都经 BFF，不直连路由引擎/数据库/tileserver。
  static const String bffBaseUrl = String.fromEnvironment(
    'BFF_BASE_URL',
    defaultValue: '',
  );

  /// 瓦片 URL 模板（`{z}/{x}/{y}`）。
  static const String tilesUrlTemplate = String.fromEnvironment(
    'TILES_URL_TEMPLATE',
    defaultValue: '',
  );

  /// 强制使用 mock map API（脱离真实 BFF 联调）。
  static const bool useMockMapApi = bool.fromEnvironment(
    'USE_MOCK_MAP_API',
    defaultValue: false,
  );

  /// Debug + Android 模拟器时默认尝试宿主机 BFF（免每次手写 dart-define）。
  static const String debugAndroidEmulatorBff = 'http://10.0.2.2:3000';

  /// 实际使用的 BFF 地址：显式配置 > Debug 模拟器默认 > 无。
  static String? get resolvedBffBaseUrl {
    if (bffBaseUrl.isNotEmpty) {
      return bffBaseUrl;
    }
    if (useMockMapApi) {
      return null;
    }
    if (kDebugMode && defaultTargetPlatform == TargetPlatform.android) {
      return debugAndroidEmulatorBff;
    }
    return null;
  }

  /// 是否配置了可尝试的 BFF（含 Debug 自动地址）。
  static bool get hasBffTarget => resolvedBffBaseUrl != null;
}

/// 当前路线/搜索数据的实际来源（用于 UI 标注）。
enum MapDataSource {
  /// 尚未请求或强制 mock。
  mock,

  /// 已成功走 BFF（OSRM 道路 geometry）。
  bff,

  /// 尝试过 BFF 但失败，已回落 fixtures。
  mockFallback,
}
