# map-bff

NestJS BFF for the demo app. It exposes the API contract in `docs/api-contract.md`
and keeps the mobile app away from the routing engine, search service, tileserver,
and databases.

## Environment

```bash
BFF_PORT=3000
OSRM_BASE_URL=http://localhost:5001
SEARCH_BASE_URL=http://localhost:7070
TILESERVER_BASE_URL=http://localhost:8080
```

`OSRM_BASE_URL` defaults to `http://localhost:5001` to avoid the common macOS
AirPlay Receiver conflict on port 5000.

## Local Run

From the repository root:

```bash
npm run build --workspace @wuhan-nav/map-bff
npm run start --workspace @wuhan-nav/map-bff
```

The `/route` endpoint expects OSRM to be available. The `/search` and `/tiles`
endpoints proxy the configured self-hosted services and do not use commercial
map APIs. `/search` also merges in Wuhan OSM POI fixtures from
`packages/test-fixtures` so demo-critical landmarks remain searchable while the
self-hosted POI backend is still sparse.
