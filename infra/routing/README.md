# OSRM Routing For Wuhan

This folder contains Docker-based OSRM helpers for T03. They are intended to help
the human owner import data and verify routes locally. This repo does not include
OSM `.pbf` data or generated OSRM files.

Codex has only statically checked these scripts and compose files. The real data
download, OSRM import, route responses, and route quality remain manual T03
verification items.

## Prepare OSM Data

From the repository root:

```bash
./infra/osm/download-wuhan-osm.sh
```

Expected input for OSRM:

```text
infra/osm/data/wuhan.osm.pbf
```

## Build OSRM Data

From `infra/routing`:

```bash
mkdir -p data
docker compose run --rm osrm-extract
docker compose run --rm osrm-contract
```

This uses OSRM's default `car.lua` profile. Route profile tuning belongs to T05.

## Run OSRM

From `infra/routing`:

```bash
docker compose up osrm-routed
```

The service listens on `http://localhost:5000` by default. On macOS, port 5000
is often occupied by AirPlay Receiver; use `OSRM_PORT=5001` when that happens:

```bash
OSRM_PORT=5001 docker compose up osrm-routed
```

## Verify Locally

In another terminal, from the repository root:

```bash
./infra/routing/verify-route.sh
```

The script sends three public-landmark route requests inside Wuhan and checks
that OSRM returns at least one route. Passing this script only proves that the
local service returns non-empty responses. Human review is still required for
route quality, one-way streets, bridges, tunnels, ramps, and demo suitability.

## Manual Checklist

- [ ] Install and verify `curl`, `osmium`, Docker, and Docker Compose.
- [ ] Run `./infra/osm/download-wuhan-osm.sh`.
- [ ] Confirm `infra/osm/data/wuhan.osm.pbf` exists and covers the intended Wuhan demo area.
- [ ] If the default bbox is too broad or too narrow, rerun with a manually verified `WUHAN_BBOX` or `WUHAN_POLY_FILE`.
- [ ] Run `docker compose run --rm osrm-extract` from `infra/routing`.
- [ ] Run `docker compose run --rm osrm-contract` from `infra/routing`.
- [ ] Run `docker compose up osrm-routed` from `infra/routing`; on macOS prefer `OSRM_PORT=5001 docker compose up osrm-routed` if AirPlay Receiver occupies port 5000.
- [ ] Run `./infra/routing/verify-route.sh` and confirm all three responses contain non-empty `routes`.
- [ ] Manually inspect route quality for the selected demo cases.
- [ ] Confirm no `.pbf`, `.osrm*`, or generated data files are staged for git.
