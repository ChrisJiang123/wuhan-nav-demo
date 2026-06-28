#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
data_dir="${OSM_DATA_DIR:-"$script_dir/data"}"

source_url="${OSM_SOURCE_URL:-https://download.geofabrik.de/asia/china/hubei-latest.osm.pbf}"
source_pbf="${OSM_SOURCE_PBF:-"$data_dir/hubei-latest.osm.pbf"}"
wuhan_pbf="${WUHAN_PBF:-"$data_dir/wuhan.osm.pbf"}"

# WGS-84 bbox in min_lng,min_lat,max_lng,max_lat order.
wuhan_bbox="${WUHAN_BBOX:-113.68,29.95,115.08,31.37}"
wuhan_poly_file="${WUHAN_POLY_FILE:-}"

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

require_command curl
require_command osmium

mkdir -p "$data_dir"

if [ ! -f "$source_pbf" ]; then
  partial="${source_pbf}.download"
  echo "Downloading $source_url"
  curl --fail --location --retry 3 --continue-at - --output "$partial" "$source_url"
  mv "$partial" "$source_pbf"
else
  echo "Using existing source PBF: $source_pbf"
fi

tmp_output="${wuhan_pbf}.tmp"
rm -f "$tmp_output"

if [ -n "$wuhan_poly_file" ]; then
  if [ ! -f "$wuhan_poly_file" ]; then
    echo "WUHAN_POLY_FILE does not exist: $wuhan_poly_file" >&2
    exit 1
  fi

  echo "Extracting Wuhan OSM PBF with polygon: $wuhan_poly_file"
  osmium extract --strategy smart --polygon "$wuhan_poly_file" --output "$tmp_output" --overwrite "$source_pbf"
else
  echo "Extracting Wuhan OSM PBF with WGS-84 bbox: $wuhan_bbox"
  osmium extract --strategy smart --bbox "$wuhan_bbox" --output "$tmp_output" --overwrite "$source_pbf"
fi

mv "$tmp_output" "$wuhan_pbf"

echo "Wuhan extract written to: $wuhan_pbf"
osmium fileinfo "$wuhan_pbf" | sed -n '1,40p'
