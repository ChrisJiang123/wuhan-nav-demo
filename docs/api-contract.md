# API 契约 — map-bff / report-service

> 前端只调这些接口。坐标一律 WGS-84，顺序 `[lng, lat]`。所有错误用统一结构。

## 通用

错误结构：
```json
{ "error": { "code": "ROUTE_NOT_FOUND", "message": "可读说明" } }
```

## map-bff

### GET /route
驾车路径规划，底层走 OSRM。

请求参数：
- `origin`：`lng,lat`
- `destination`：`lng,lat`
- `alternatives`：bool，默认 true（返回 1–3 条）

响应：
```json
{
  "routes": [
    {
      "id": "r1",
      "durationSec": 1440,
      "distanceM": 12400,
      "tollEstimateYuan": 6,
      "tag": "推荐",
      "summary": "拥堵少，过桥一次",
      "geometry": [[114.30,30.59],[114.31,30.60]]
    }
  ]
}
```
说明：`tollEstimateYuan` 为估算/占位；`geometry` 为 WGS-84 折线。

### GET /search
POI 搜索，底层走 OSM POI 数据。

请求参数：`q`（关键字），可选 `near`（`lng,lat` 偏置）。

响应：
```json
{
  "pois": [
    { "id": "p1", "name": "武汉站", "category": "railway_station", "location": [114.42,30.61] }
  ]
}
```

### GET /tiles/{z}/{x}/{y}
矢量瓦片代理。透传自建 tileserver，按需缓存。

## report-service

### POST /reports
```json
{
  "type": "construction",          // accident|construction|jam|closure|illegal_parking|pothole|checkpoint
  "location": [114.30,30.59],
  "description": "可选文本",
  "imageRef": "可选，图片存储引用",
  "anonymous": true
}
```
响应：`{ "id": "rep_123", "status": "pending" }`

### GET /reports
列出上报（运营后台用）。支持 `status` 过滤。

### PATCH /reports/{id}
审核：`{ "status": "approved" }` 或 `"rejected"`。

## 字段约定

- 时间：秒（int）。距离：米（int）。坐标：WGS-84，`[lng,lat]`。
- 类型枚举集中定义在 `packages/shared-types`，前后端复用，禁止各写一份。
