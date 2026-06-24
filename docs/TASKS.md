# TASKS.md — 可执行任务清单

> 这是把一周 roadmap 拆成的 agent 可执行任务。每个任务边界清晰、有验收标准。
> 用法：人类按编号和依赖派发；agent 完成单个任务后提 PR，人类审阅合并。
> 标签：`[agent]` 适合托管给 AI 自主跑；`[human]` 必须人主导，AI 只做辅助；`[mixed]` 人定方向 AI 填充。

---

## 周一 — 立项 + 路由打地基

### T01 [agent] 初始化 monorepo 骨架
- 输入：本仓库的目录结构约定（见 AGENTS.md 第 3 节）。
- 产出：创建 `apps/ ` `services/` `infra/` `packages/` `docs/` 空骨架；根 `package.json` / workspace 配置；`.gitignore`；`README.md` 占位。
- 验收：`git status` 干净，结构与 AGENTS.md 一致，CI 能跑空构建。
- 依赖：无。

### T02 [agent] 配置 CI 与 lint
- 产出：CI（GitHub Actions）跑 `flutter analyze` 与后端 `npm run lint`；提交即触发。
- 验收：一个空 PR 能触发 CI 并通过。
- 依赖：T01。

### T03 [human] 下载 OSM 武汉数据并导入 OSRM，跑通第一条路径
- 输入：武汉行政区 OSM 提取（geofabrik 湖北提取后裁剪，或 BBBike 自定义区域）。
- 产出：`infra/osm/` 下载与裁剪脚本；`infra/routing/` 的 osrm-extract/contract/routed 配置；本地能 curl 一组武汉起终点返回路径。
- 验收：对至少 3 组武汉真实起终点返回非空路径（质量可粗糙）。
- 依赖：T01。**这是本周最大不确定项，优先做。**

### T04 [mixed] Flutter 工程骨架 + 空地图
- 产出：`apps/mobile-flutter` 可启动；集成 MapLibre 插件；显示一张武汉空白底图（瓦片源先用占位/本地）。
- 验收：真机/模拟器启动后能看到可缩放的武汉地图。
- 依赖：T01。

---

## 周二 — 路由调优 + 搜索/路线页

### T05 [human] OSRM 路由调优
- 产出：car profile 调整；检查武汉单行线、桥隧、快速路匝道转向；开启 alternatives（1–3 条）。
- 验收：之前明显绕路的用例修正；PR 附调优前后的起终点结果对比。
- 依赖：T03。

### T06 [agent] BFF 骨架与三组接口
- 产出：`services/map-bff`（NestJS）暴露 `/route` `/search` `/tiles`，全部经环境变量配置底层地址。
- 验收：本地起 BFF，`/route` 能透传 OSRM 结果并按 DTO 返回。
- 依赖：T03。

### T07 [agent] 共享 DTO / 类型
- 产出：`packages/shared-types` 定义 Route、RouteOption、Poi、Report 等 DTO，坐标 WGS-84 `[lng,lat]` 并注释。
- 验收：前后端均能引用，类型一致。
- 依赖：T01。

### T08 [agent] 搜索接口（POI）
- 产出：BFF `/search` 基于 OSM POI（可用本地 nominatim 或预处理 POI 表）返回匹配地点。
- 验收：搜“武汉站”等关键词返回合理结果（不足处由 fixtures 补）。
- 依赖：T06。

### T09 [mixed] 搜索页 + 路线选择页
- 产出：输入起终点 → 调 BFF → 展示 1–3 条路线（时间/距离/收费估算/特征）。
- 验收：输入一组起终点能看到多条路线并选定。
- 依赖：T06, T07, T08, T04。

### T10 [agent] API client / mock / 测试夹具
- 产出：`core/map_provider` client（只调 BFF）；`packages/test-fixtures` 的 mock 路线/POI；联调可脱离真实后端。
- 验收：前端用 mock 即可跑通搜索→路线页。
- 依赖：T07。（可交 Codex 并行）

---

## 周三 — 导航态 + 渲染

### T11 [mixed] MapLibre 路线渲染
- 产出：把选定路线折线画到地图，做 simplify；用 OSM highway 等级静态着色。
- 验收：路线高亮可见，长路线不掉帧；UI/代码注明“静态等级非实时”。
- 依赖：T09。

### T12 [human] 导航态核心
- 产出：定位跟随、回中、视角、静音；ETA/剩余里程时间/下一动作；前台服务保活。
- 验收：从路线页进入导航能跟随定位移动。
- 依赖：T11。

### T13 [agent] 基础 TTS 播报
- 产出：中文普通话转向播报；可静音。
- 验收：转向时有语音提示，静音生效。
- 依赖：T12。

### T14 [agent] 弱网缓存
- 产出：进导航前缓存路线摘要/拐点/TTS 脚本；断网显示已缓存。
- 验收：飞行模式下仍能看已缓存路线摘要。
- 依赖：T12。

---

## 周四 — 上报闭环 + 真机首测

### T15 [mixed] 一键上报前端
- 产出：驾驶态上报入口 → 类型选择 → 自动带坐标 → 可选语音/文本/图片 → 提交，≤ 2 步；匿名开关。
- 验收：驾驶态 2 步内完成上报。
- 依赖：T12。

### T16 [agent] 上报后端 + 后台
- 产出：`report-service` 的 `POST/GET/PATCH /reports`；`ops-admin` 列表+审核页。
- 验收：App 提交后，后台可见并可审核。
- 依赖：T06, T07。

### T17 [human] 真机首测（前置）
- 产出：武汉一小段实路跑 App，记录定位漂移/隧道/后台被杀等问题清单。
- 验收：产出问题清单，标出 blocker。
- 依赖：T12, T13。

### T18 [human] 可选：人工录入演示事件
- 产出：后台录入几条施工/事故点，前端能展示其对路线的提示。
- 验收：演示时可见事件标记。
- 依赖：T16。优先级 P2，时间不够可砍。

---

## 周五 — 联调 + 加固

### T19 [human] 全链路联调
- 验收：搜索→路线→导航→上报全程无阻断。
- 依赖：T09–T16。

### T20 [mixed] Crash 清零 + 性能优化
- 验收：blocker 崩溃归零；导航页 ≥ 50 FPS。
- 依赖：T19。

### T21 [agent] code review + 文档初稿 + 演示脚本
- 产出：Codex 审主要 PR；生成 README、部署说明、测试说明、已知限制、demo 脚本初稿。
- 验收：四份文档草稿就绪，见 `docs/`。
- 依赖：T19。

---

## 周末 — 路测 + 交付

### T22 [human] 武汉实车路测
- 场景：跨江桥隧、快速路匝道、密集红绿灯、商圈出入口。
- 验收：问题清单 + 高优修复。
- 依赖：T20。

### T23 [mixed] 打磨 + 内测包 + 录屏交付
- 产出：内测包上传分发平台；录屏；交付演示包与四份文档定稿。
- 验收：少数人可扫码安装；录屏完整呈现全流程。
- 依赖：T22, T21。

---

## 派发建议

- **可放心托管给 Codex 云端并行的**：T01、T02、T06、T07、T08、T10、T13、T14、T16、T21（标 `[agent]`）。
- **Cursor 主驱动、人在旁的**：T04、T09、T11、T15、T20、T23（标 `[mixed]`）。
- **必须人主导、AI 仅辅助的硬骨头**：T03、T05、T12、T17、T19、T22（标 `[human]`）——OSM 导入、路由调优、导航态保活、真机/路测，这些是 AI 帮不上太多的地方，别托管。
