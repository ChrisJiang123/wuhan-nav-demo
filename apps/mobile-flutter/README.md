# mobile-flutter — 武汉导航 Demo Android 客户端

仅 Android 的 Flutter 客户端。地图渲染用 **MapLibre GL**，状态管理用 **Riverpod**。
本目录当前对应 **T04 空地图** + **T10 API client / mock**。

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
   └─ map/presentation/map_page.dart   # 空地图首页
test/
├─ map_style_test.dart
├─ mock_map_api_client_test.dart
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

## 校验

```bash
flutter analyze
flutter test
```

## 边界（T04/T10 不做）

定位跟随/回中（T12）、路线渲染与路况着色（T11）、搜索与路线**页面 UI**（T09）均不在本任务内。
数据署名：© OpenStreetMap contributors（ODbL）。
