# @wuhan-nav/test-fixtures

Mock data for local integration without real OSM search or OSRM services.

The JSON files mirror the BFF contract in `docs/api-contract.md` and are
type-checked against `@wuhan-nav/shared-types` in `src/index.ts`. Coordinates
are WGS-84 `[lng, lat]`; do not add GCJ-02 or BD-09 coordinates here.

## Mock BFF

Run a tiny BFF-shaped mock server:

```bash
npm run mock:bff --workspace @wuhan-nav/test-fixtures
```

It serves:

- `GET /search?q=武汉站`
- `GET /route?origin=114.4249,30.6073&destination=114.2546,30.618&alternatives=true`

Use `MOCK_BFF_PORT=3109` to change the port. Android emulators can point the
Flutter app at `http://10.0.2.2:3109` with `--dart-define=BFF_BASE_URL=...`.
