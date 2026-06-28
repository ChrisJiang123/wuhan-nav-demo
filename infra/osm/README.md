# OSM Wuhan Extract

This folder contains helper scripts for T03. The scripts download an OpenStreetMap
Hubei extract, then clip a Wuhan-area PBF for local OSRM import.

Coordinates are WGS-84 longitude/latitude. The default clipping area is a coarse
Wuhan bounding box:

```text
113.68,29.95,115.08,31.37
```

Override `WUHAN_BBOX` or pass `WUHAN_POLY_FILE` when you need a tighter manually
verified boundary.

## Prerequisites

- `curl`
- `osmium` (`brew install osmium-tool` on macOS)

## Usage

From the repository root:

```bash
./infra/osm/download-wuhan-osm.sh
```

Useful overrides:

```bash
WUHAN_BBOX="113.68,29.95,115.08,31.37" ./infra/osm/download-wuhan-osm.sh
WUHAN_POLY_FILE=/absolute/path/to/wuhan.poly ./infra/osm/download-wuhan-osm.sh
```

Outputs:

- `infra/osm/data/hubei-latest.osm.pbf`
- `infra/osm/data/wuhan.osm.pbf`

The `data/` directory is ignored by git. Do not commit `.pbf` files.
