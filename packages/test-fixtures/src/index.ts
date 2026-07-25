import type { Poi, Wgs84LngLat } from "@wuhan-nav/shared-types";

import wuhanPois from "../wuhan-pois.json";

export { wuhanRouteFixtures, type RouteFixture } from "./wuhan-routes.js";

export interface PoiFixture extends Poi {
  aliases: readonly string[];
}

interface RawPoiFixture extends Omit<PoiFixture, "location"> {
  location: readonly number[];
}

export const wuhanPoiFixtures: readonly PoiFixture[] = (wuhanPois as readonly RawPoiFixture[]).map((poi) => ({
  ...poi,
  location: toWgs84LngLat(poi.location),
}));

function toWgs84LngLat(location: readonly number[]): Wgs84LngLat {
  if (location.length !== 2) {
    throw new Error("Fixture POI location must be [lng, lat].");
  }

  const [lng, lat] = location;

  if (typeof lng !== "number" || typeof lat !== "number") {
    throw new Error("Fixture POI location must contain numbers.");
  }

  return [lng, lat];
}
