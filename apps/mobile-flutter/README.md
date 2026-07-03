# mobile-flutter — 武汉导航 Demo Android 客户端

仅 Android 的 Flutter 客户端。地图渲染用 **MapLibre GL**，状态管理用 **Riverpod**。
本目录当前对应 **T04：Flutter 骨架 + 空地图**——启动即显示可缩放的武汉城区地图。

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
│  └─ theme/app_theme.dart       # 视觉 token（与 .cursor/rules 一致）
└─ features/
   └─ map/presentation/map_page.dart   # 空地图首页
test/
└─ map_style_test.dart           # style 构建纯函数单测
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

## 校验

```bash
flutter analyze
flutter test
```

## 边界（本任务不做）

定位跟随/回中（T12）、路线渲染与路况着色（T11）、搜索与路线页（T09）均不在 T04 内，
本页不提前实现。数据署名：© OpenStreetMap contributors（ODbL）。
