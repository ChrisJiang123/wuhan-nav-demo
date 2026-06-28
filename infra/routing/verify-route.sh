#!/usr/bin/env bash
set -euo pipefail

osrm_base_url="${OSRM_BASE_URL:-http://localhost:5000}"

cases=(
  "wuhan_station_to_hankou_station|114.4249,30.6073;114.2546,30.6180"
  "wuchang_station_to_yellow_crane_tower|114.3162,30.5290;114.3063,30.5449"
  "hankou_station_to_optics_valley|114.2546,30.6180;114.3972,30.5050"
)

for case_def in "${cases[@]}"; do
  name="${case_def%%|*}"
  coordinates="${case_def#*|}"
  url="${osrm_base_url}/route/v1/driving/${coordinates}?overview=false&alternatives=true&steps=false"

  echo "Checking $name"
  response="$(curl --fail --silent --show-error "$url")"

  ROUTE_RESPONSE="$response" node <<'NODE'
const payload = JSON.parse(process.env.ROUTE_RESPONSE);
if (!Array.isArray(payload.routes) || payload.routes.length === 0) {
  console.error("OSRM response did not include non-empty routes");
  process.exit(1);
}
const first = payload.routes[0];
console.log(`routes=${payload.routes.length} distance=${Math.round(first.distance)}m duration=${Math.round(first.duration)}s`);
NODE
done
