# @wuhan-nav/ops-admin

Demo-grade operations page for T16 report review.

```bash
npm run start --workspace @wuhan-nav/ops-admin
```

The server listens on `OPS_ADMIN_PORT` and defaults to `3002`. It calls
`REPORT_SERVICE_BASE_URL`, defaulting to `http://localhost:3001`.

Run `@wuhan-nav/report-service` first, then open the admin page to list pending
reports and mark them approved or rejected.
