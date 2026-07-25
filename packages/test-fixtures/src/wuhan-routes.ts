import type { RouteResponse, Wgs84LngLat } from "@wuhan-nav/shared-types";

import rawRoutes from "../wuhan-routes.json";

interface RawRouteFixture {
  id: string;
  description?: string;
  origin: readonly number[];
  destination: readonly number[];
  alternatives?: boolean;
  response: {
    routes: readonly {
      id: string;
      durationSec: number;
      distanceM: number;
      tollEstimateYuan: number;
      tag: string;
      summary: string;
      geometry: readonly (readonly number[])[];
    }[];
  };
}

export interface RouteFixture {
  id: string;
  description?: string;
  origin: Wgs84LngLat;
  destination: Wgs84LngLat;
  alternatives?: boolean;
  response: RouteResponse;
}

export const wuhanRouteFixtures: readonly RouteFixture[] = (rawRoutes as readonly RawRouteFixture[]).map((fixture) => {
  const mapped: RouteFixture = {
    id: fixture.id,
    origin: toWgs84LngLat(fixture.origin, "origin"),
    destination: toWgs84LngLat(fixture.destination, "destination"),
    response: {
      routes: fixture.response.routes.map((route, index) => ({
        id: route.id,
        durationSec: route.durationSec,
        distanceM: route.distanceM,
        tollEstimateYuan: route.tollEstimateYuan,
        tag: route.tag,
        summary: route.summary,
        geometry: route.geometry.map((coordinate, coordinateIndex) =>
          toWgs84LngLat(coordinate, `route ${index + 1} geometry[${coordinateIndex}]`),
        ),
      })),
    },
  };

  if (fixture.description !== undefined) {
    mapped.description = fixture.description;
  }

  if (fixture.alternatives !== undefined) {
    mapped.alternatives = fixture.alternatives;
  }

  return mapped;
});

function toWgs84LngLat(location: readonly number[], name: string): Wgs84LngLat {
  if (location.length !== 2) {
    throw new Error(`Fixture route ${name} must be [lng, lat].`);
  }

  const [lng, lat] = location;

  if (typeof lng !== "number" || typeof lat !== "number") {
    throw new Error(`Fixture route ${name} must contain numbers.`);
  }

  return [lng, lat];
}
