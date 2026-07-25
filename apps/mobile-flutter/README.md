# mobile-flutter — 武汉导航 Demo Android 客户端

仅 Android 的 Flutter 客户端。地图渲染用 **MapLibre GL**，状态管理用 **Riverpod**。
本目录当前对应 **T04 空地图** + **T10 API client / mock** + **T09 搜索/路线选择** + **T12 导航态核心**。

## 技术选型（首个 Flutter 任务锁定，后续不换）

| 项 | 选型 |
|---|---|
| 状态管理 | Riverpod（`flutter_riverpod ^3.3.2`） |
| 地图 | MapLibre GL（`maplibre_gl ^0.26.2`） |
| 目录风格 | feature-first：`features/<name>/`，共享逻辑入 `core/` |
| 坐标系 | 全链路 WGS-84，`[lng, lat]`，不做任何坐标转换 |

## 目录

```
lib/
├─ main.dart                     # 入口：ProviderScope + App
├─ app.dart                      # MaterialApp + 主题
├─ core/
│  ├─ config/env.dart            # --dart-define 注入的运行期地址
│  ├─ config/app_config.dart     # 武汉中心、缩放、瓦片源、署名
│  ├─ map/map_style.dart         # 纯函数：构建 MapLibre style JSON（有单测）
│  ├─ map_provider/              # T10：BFF client + mock client + Riverpod
│  │  ├─ map_api_client.dart     # 接口（只调 BFF /route /search）
│  │  ├─ bff_map_api_client.dart
│  │  ├─ mock_map_api_client.dart
│  │  └─ map_provider.dart
│  └─ theme/app_theme.dart       # 视觉 token（与 .cursor/rules 一致）
└─ features/
   ├─ home/presentation/home_page.dart      # 地图 + 可拖拽行程面板
   ├─ trip/                                 # T09 搜索 → 路线选择
   ├─ navigation/                           # T12 导航态（跟随/回中/前台服务）
   └─ map/presentation/map_page.dart       # T04 遗留（已由 HomePage 取代）
test/
├─ map_style_test.dart
├─ mock_map_api_client_test.dart
├─ route_progress_test.dart
└─ bff_map_api_client_test.dart
tool/
└─ bootstrap.sh                  # 生成 Android 平台层
```

> 说明：`android/` 平台层（gradle wrapper、launcher 图标等含二进制文件）不手写、不入库，
> 由 `tool/bootstrap.sh` 调 `flutter create` 生成。

## 首次运行

需要 Flutter SDK `>=3.29`、Android SDK/模拟器或真机。

```bash
cd apps/mobile-flutter
bash tool/bootstrap.sh      # 生成 android/ 平台层并 flutter pub get
flutter devices             # 确认有 Android 设备
flutter run                 # 默认用占位瓦片（OSM 栅格），无需后端
```

生成 `android/` 后，如需让另一台机器免 bootstrap 直接跑，可把 `android/` 一并提交。

## 瓦片源

- **默认（占位）**：OpenStreetMap 栅格瓦片，仅用于演示“地图可见”，UI 左上角标注“演示占位”。
- **接自建瓦片（经 BFF）**：

```bash
flutter run \
  --dart-define=TILES_URL_TEMPLATE=http://10.0.2.2:3000/tiles/{z}/{x}/{y} \
  --dart-define=BFF_BASE_URL=http://10.0.2.2:3000
```

Android 模拟器用 `10.0.2.2` 访问宿主机 localhost。前端一切外部数据经 BFF，不直连 tileserver/路由引擎。

## 路由 / 搜索 API（T10）

DTO 来自 `packages/shared-types/dart`（镜像 TS shared-types），不在本目录重复定义。

| 模式 | 条件 | 说明 |
|---|---|---|
| **mock（默认）** | 未设置 `BFF_BASE_URL` | 读 `packages/test-fixtures` 的 POI/路线 fixtures；`id`/`summary` 带 `mock` 前缀 |
| **真实 BFF** | `--dart-define=BFF_BASE_URL=http://10.0.2.2:3000` | 只调 `/route` `/search` |
| **强制 mock** | `--dart-define=USE_MOCK_MAP_API=true` | 即使有 BFF 也用 mock |

mock 路线量级贴近 T03 实测：武汉站→汉口站 19884m/1043s、武昌站→黄鹤楼 3001m、汉口站→光谷 24438m（2 条备选）。

```dart
// Riverpod 注入
final client = ref.read(mapApiClientProvider);
final routes = await client.getRoute(
  origin: Wgs84LngLat(lng: 114.4249, lat: 30.6073),
  destination: Wgs84LngLat(lng: 114.2546, lat: 30.618),
);
final pois = await client.search(query: '武汉站');
```

## T09 → T12 演示路径

1. 启动 App → 底部面板搜 **武汉站** / **汉口站** → **查看路线** → **开始导航**
2. 进入导航态：顶部下一动作 + 剩余里程/时间；底部 5 控件（上报占位 / 总览 / 结束 / 回中 / 静音）
3. Debug 默认 **模拟沿路线** 移动（验收跟随）；真机请切到 **真实 GPS**
4. 通知栏应出现「武汉导航进行中」（前台服务）；息屏/后台保活需真机验证

### 真机验收注意（不确定项）

- 首次进入导航会请求定位与通知权限；后台定位需在系统设置里额外授权。
- Android 14+ 前台服务类型为 `location`；若启动失败，导航仍可前台运行，但保活不保证。
- 部分 OEM 省电策略会杀后台；可能需关闭电池优化（未强制弹系统页，避免过度打扰）。
- TTS 播报在 T13；本任务静音只切换状态。

## 校验

```bash
flutter analyze
flutter test
```

## 边界（T12 不做）

TTS 播报（T13）、弱网缓存（T14）、完整上报（T15）、路况静态着色增强（T11）均不扩大范围。
数据署名：© OpenStreetMap contributors（ODbL）。
