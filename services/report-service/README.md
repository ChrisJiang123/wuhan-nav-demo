# @wuhan-nav/report-service

Demo-grade report intake and review API for T16.

```bash
npm run start:dev --workspace @wuhan-nav/report-service
```

The service listens on `REPORT_PORT` and defaults to `3001`.

Implemented endpoints:

- `POST /reports`
- `GET /reports?status=pending`
- `PATCH /reports/:id`

Reports are stored in memory for the current process. Coordinates are WGS-84
`[lng, lat]`, matching `docs/api-contract.md` and `@wuhan-nav/shared-types`.
