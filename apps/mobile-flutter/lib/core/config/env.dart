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
  ///
  /// 生产路径应指向 BFF `/tiles/{z}/{x}/{y}`（自建矢量/栅格瓦片）。
  /// 未注入时回落到占位栅格源（见 [AppConfig.placeholderTileTemplate]），
  /// 以保证 T04 阶段“启动即可见可缩放的武汉地图”。
  static const String tilesUrlTemplate = String.fromEnvironment(
    'TILES_URL_TEMPLATE',
    defaultValue: '',
  );

  /// 强制使用 mock map API（脱离真实 BFF 联调）。
  static const bool useMockMapApi = bool.fromEnvironment(
    'USE_MOCK_MAP_API',
    defaultValue: false,
  );

  /// 未配置 BFF 或显式开启 mock 时，路由/搜索走 fixtures。
  static bool get shouldUseMockMapApi => useMockMapApi || bffBaseUrl.isEmpty;
}
