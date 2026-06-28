# 武汉市内导航 Demo（OSM 开源自搭）

一周内、仅 Android、完全基于开源栈（OpenStreetMap + MapLibre + 自建路由引擎）的武汉城区驾车导航演示应用。**不依赖任何商业地图厂商。** 用于内部演示与小范围试用。

## 这套仓库怎么用

本仓库为“人给计划、AI agent 执行”模式而组织：

- **想了解整体计划**：看随附的《武汉市内导航Demo_执行手册_v1.docx》（给人看的）。
- **AI agent 工作说明**：根目录 `AGENTS.md`（Codex）与 `.cursor/rules/`（Cursor）。
- **要做什么**：`docs/PRD.md`（需求）+ `docs/TASKS.md`（拆好的可执行任务，带验收标准）。
- **接口约定**：`docs/api-contract.md`。
- **环境配置**：复制 `.env.example` 为 `.env` 填值。

## 工作流（人 + AI）

1. 人按 `docs/TASKS.md` 的编号和依赖派发任务。
2. 标 `[agent]` 的任务可托管给 Codex 云端并行跑；标 `[mixed]` 的在 Cursor 里人驱动；标 `[human]` 的（OSM 导入、路由调优、导航保活、真机/路测）人主导、AI 仅辅助。
3. agent 完成单任务提 PR，人审阅合并。**AI 不自行合并、模糊处先问。**

## 技术栈

Flutter（Android）· MapLibre GL · 自建矢量瓦片 · OSRM 路由 · NestJS BFF · PostgreSQL + Redis。

## 仓库骨架

当前已按 `AGENTS.md` 初始化 monorepo 目录：`apps/mobile-flutter`、`apps/ops-admin`、`services/map-bff`、`services/report-service`、`infra/osm`、`infra/routing`、`infra/tiles`、`packages/shared-types`、`packages/test-fixtures` 与 `docs`。根目录 `package.json` 声明 npm workspaces，后续任务落地具体 Flutter、NestJS 与共享包时补充实际构建、lint 和测试脚本。

## CI 与 lint

GitHub Actions 在 push 与 pull request 时触发。当前骨架阶段会检查 `services/*` 下后端包的 `npm run lint` 入口，并在 `apps/mobile-flutter/pubspec.yaml` 出现后执行 `flutter analyze`；在 T04/T06 之前对应项目尚未落地时，CI 会明确跳过未出现的目标以保证空骨架 PR 可通过。

## 锁定口径（勿改）

开源自搭 / 仅 Android / 全链路 WGS-84 不做坐标转换 / 实时路况与事件本周不做真实数据源 / 内部小范围试用不公开上架。详见 `AGENTS.md`。

## 数据署名

地图数据来自 OpenStreetMap，采用 ODbL 许可，使用时需注明 “© OpenStreetMap contributors”。

## 已知限制

见 `docs/`（部署、测试、已知限制文档在周五由 T21 生成）。简言之：路径质量、POI 覆盖、实时性均为演示级，不等同商业导航。
