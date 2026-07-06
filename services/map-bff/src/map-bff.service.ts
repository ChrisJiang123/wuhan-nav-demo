import { HttpStatus, Inject, Injectable, Optional } from "@nestjs/common";

import type {
  Poi,
  RouteOption,
  RouteResponse,
  SearchResponse,
  Wgs84LngLat,
} from "@wuhan-nav/shared-types";
import wuhanPoiFixtures from "@wuhan-nav/test-fixtures/wuhan-pois.json";

import { AppConfigService } from "./config.service";
import { apiError } from "./errors";

type HttpClient = (url: string, init?: RequestInit) => Promise<Response>;
export const HTTP_CLIENT = "HTTP_CLIENT";

interface RouteRequest {
  origin: string | undefined;
  destination: string | undefined;
  alternatives: string | undefined;
}

interface SearchRequest {
  q: string | undefined;
  near: string | undefined;
}

interface TileRequest {
  z: string;
  x: string;
  y: string;
}

interface TileResponse {
  status: number;
  headers: Record<string, string>;
  body: ArrayBuffer;
}

interface OsrmRoute {
  duration?: number;
  distance?: number;
  geometry?: {
    coordinates?: unknown;
  };
  legs?: Array<{
    summary?: string;
  }>;
}

interface OsrmRouteResponse {
  routes?: OsrmRoute[];
}

interface RawPoiFixture extends Omit<Poi, "location"> {
  location: readonly number[];
  aliases?: readonly string[];
}

@Injectable()
export class MapBffService {
  private readonly httpClient: HttpClient;

  constructor(
    private readonly config: AppConfigService,
    @Optional() @Inject(HTTP_CLIENT) httpClient?: HttpClient,
  ) {
    this.httpClient = httpClient ?? globalThis.fetch.bind(globalThis);
  }

  async getRoute(request: RouteRequest): Promise<RouteResponse> {
    const origin = parseLngLatQuery(request.origin, "origin");
    const destination = parseLngLatQuery(request.destination, "destination");
    const alternatives = parseAlternatives(request.alternatives);

    const url = new URL(joinUrl(this.config.osrmBaseUrl, "route/v1/driving", `${formatLngLat(origin)};${formatLngLat(destination)}`));
    url.searchParams.set("overview", "full");
    url.searchParams.set("geometries", "geojson");
    url.searchParams.set("alternatives", String(alternatives));
    url.searchParams.set("steps", "false");

    const payload = await this.fetchJson<OsrmRouteResponse>(url.toString(), "ROUTE_UPSTREAM_ERROR");
    const osrmRoutes = Array.isArray(payload.routes) ? payload.routes : [];

    if (osrmRoutes.length === 0) {
      throw apiError("ROUTE_NOT_FOUND", "OSRM did not return a route for the requested coordinates.", HttpStatus.NOT_FOUND);
    }

    return {
      routes: osrmRoutes.slice(0, 3).map(toRouteOption),
    };
  }

  async search(request: SearchRequest): Promise<SearchResponse> {
    const q = request.q?.trim();

    if (!q) {
      throw apiError("INVALID_QUERY", "q is required.", HttpStatus.BAD_REQUEST);
    }

    const near = request.near ? parseLngLatQuery(request.near, "near") : undefined;
    const fixturePois = searchFixturePois(q, near);
    const url = new URL(joinUrl(this.config.searchBaseUrl, "search"));
    url.searchParams.set("q", q);

    if (near) {
      url.searchParams.set("near", formatLngLat(near));
    }

    const upstreamPois = await this.tryFetchSearchPois(url.toString());

    return {
      pois: mergePois(upstreamPois, fixturePois),
    };
  }

  async getTile(request: TileRequest): Promise<TileResponse> {
    const z = parseTileParam(request.z, "z");
    const x = parseTileParam(request.x, "x");
    const y = parseTileParam(request.y, "y");
    const upstreamResponse = await this.fetchUpstream(joinUrl(this.config.tileserverBaseUrl, String(z), String(x), String(y)), "TILE_UPSTREAM_ERROR");
    const headers: Record<string, string> = {};

    for (const header of ["content-type", "cache-control", "etag"]) {
      const value = upstreamResponse.headers.get(header);
      if (value) {
        headers[header] = value;
      }
    }

    return {
      status: upstreamResponse.status,
      headers,
      body: await upstreamResponse.arrayBuffer(),
    };
  }

  private async fetchJson<T>(url: string, errorCode: string): Promise<T> {
    const response = await this.fetchUpstream(url, errorCode);

    try {
      return (await response.json()) as T;
    } catch {
      throw apiError(errorCode, "Upstream returned invalid JSON.", HttpStatus.BAD_GATEWAY);
    }
  }

  private async fetchUpstream(url: string, errorCode: string): Promise<Response> {
    let response: Response;

    try {
      response = await this.httpClient(url);
    } catch {
      throw apiError(errorCode, "Upstream service is unavailable.", HttpStatus.BAD_GATEWAY);
    }

    if (!response.ok) {
      throw apiError(errorCode, `Upstream service returned HTTP ${response.status}.`, HttpStatus.BAD_GATEWAY);
    }

    return response;
  }

  private async tryFetchSearchPois(url: string): Promise<Poi[]> {
    try {
      const payload = await this.fetchJson<SearchResponse>(url, "SEARCH_UPSTREAM_ERROR");
      return Array.isArray(payload.pois) ? payload.pois.map(toPoi) : [];
    } catch {
      return [];
    }
  }
}

function parseLngLatQuery(value: string | undefined, name: string): Wgs84LngLat {
  if (!value) {
    throw apiError("INVALID_QUERY", `${name} is required as lng,lat.`, HttpStatus.BAD_REQUEST);
  }

  const parts = value.split(",");
  if (parts.length !== 2) {
    throw apiError("INVALID_QUERY", `${name} must use lng,lat order.`, HttpStatus.BAD_REQUEST);
  }

  const lng = Number(parts[0]);
  const lat = Number(parts[1]);

  if (!Number.isFinite(lng) || !Number.isFinite(lat) || lng < -180 || lng > 180 || lat < -90 || lat > 90) {
    throw apiError("INVALID_QUERY", `${name} must be valid WGS-84 lng,lat.`, HttpStatus.BAD_REQUEST);
  }

  return [lng, lat];
}

function parseAlternatives(value: string | undefined): boolean {
  if (value === undefined || value === "") {
    return true;
  }

  if (["true", "1"].includes(value.toLowerCase())) {
    return true;
  }

  if (["false", "0"].includes(value.toLowerCase())) {
    return false;
  }

  throw apiError("INVALID_QUERY", "alternatives must be a boolean.", HttpStatus.BAD_REQUEST);
}

function parseTileParam(value: string, name: string): number {
  const parsed = Number(value);

  if (!Number.isInteger(parsed) || parsed < 0) {
    throw apiError("INVALID_QUERY", `${name} must be a non-negative integer.`, HttpStatus.BAD_REQUEST);
  }

  return parsed;
}

function formatLngLat(coordinate: Wgs84LngLat): string {
  return `${coordinate[0]},${coordinate[1]}`;
}

function joinUrl(baseUrl: string, ...paths: string[]): string {
  const trimmedBase = baseUrl.replace(/\/+$/, "");
  const trimmedPath = paths.map((path) => path.replace(/^\/+|\/+$/g, "")).filter(Boolean).join("/");
  return trimmedPath ? `${trimmedBase}/${trimmedPath}` : trimmedBase;
}

function searchFixturePois(query: string, near: Wgs84LngLat | undefined): Poi[] {
  const normalizedQuery = normalizeSearchText(query);
  const scoredPois = (wuhanPoiFixtures as readonly RawPoiFixture[])
    .map((poi) => ({ poi, score: scoreFixturePoi(poi, normalizedQuery, near) }))
    .filter(({ score }) => score > 0)
    .sort((left, right) => right.score - left.score);

  return scoredPois.map(({ poi }) => ({
    id: poi.id,
    name: poi.name,
    category: poi.category,
    location: toWgs84Coordinate(poi.location, "fixture poi location", "SEARCH_UPSTREAM_ERROR"),
  }));
}

function scoreFixturePoi(poi: RawPoiFixture, normalizedQuery: string, near: Wgs84LngLat | undefined): number {
  const name = normalizeSearchText(poi.name);
  const category = normalizeSearchText(poi.category);
  const aliases = (poi.aliases ?? []).map(normalizeSearchText);
  let score = 0;

  if (name === normalizedQuery) {
    score += 100;
  } else if (name.includes(normalizedQuery)) {
    score += 80;
  }

  for (const alias of aliases) {
    if (alias === normalizedQuery) {
      score += 70;
      break;
    }

    if (alias.includes(normalizedQuery)) {
      score += 50;
      break;
    }
  }

  if (category.includes(normalizedQuery)) {
    score += 20;
  }

  if (score === 0) {
    return 0;
  }

  if (near) {
    const distanceKm = approximateDistanceKm(near, toWgs84Coordinate(poi.location, "fixture poi location", "SEARCH_UPSTREAM_ERROR"));
    score += Math.max(0, 20 - Math.min(distanceKm, 20));
  }

  return score;
}

function normalizeSearchText(value: string): string {
  return value.toLocaleLowerCase("zh-CN").replace(/\s+/g, "");
}

function approximateDistanceKm(from: Wgs84LngLat, to: Wgs84LngLat): number {
  const lngDeltaKm = (from[0] - to[0]) * 111.32 * Math.cos((((from[1] + to[1]) / 2) * Math.PI) / 180);
  const latDeltaKm = (from[1] - to[1]) * 110.57;
  return Math.sqrt(lngDeltaKm ** 2 + latDeltaKm ** 2);
}

function mergePois(upstreamPois: readonly Poi[], fixturePois: readonly Poi[]): Poi[] {
  const seen = new Set<string>();
  const merged: Poi[] = [];

  for (const poi of [...upstreamPois, ...fixturePois]) {
    const key = poi.id || `${poi.name}:${poi.location[0]},${poi.location[1]}`;

    if (seen.has(key)) {
      continue;
    }

    seen.add(key);
    merged.push(poi);
  }

  return merged.slice(0, 10);
}

function toRouteOption(route: OsrmRoute, index: number): RouteOption {
  const coordinates = route.geometry?.coordinates;

  if (!Array.isArray(coordinates)) {
    throw apiError("ROUTE_UPSTREAM_ERROR", "OSRM route geometry is missing.", HttpStatus.BAD_GATEWAY);
  }

  return {
    id: `r${index + 1}`,
    durationSec: Math.round(assertNumber(route.duration, "duration")),
    distanceM: Math.round(assertNumber(route.distance, "distance")),
    tollEstimateYuan: 0,
    tag: index === 0 ? "推荐" : `备选${index + 1}`,
    summary: summarizeRoute(route, index),
    geometry: coordinates.map((coordinate) => toWgs84Coordinate(coordinate, "route geometry", "ROUTE_UPSTREAM_ERROR")),
  };
}

function summarizeRoute(route: OsrmRoute, index: number): string {
  const summaries = route.legs?.map((leg) => leg.summary?.trim()).filter((summary): summary is string => Boolean(summary));

  if (summaries && summaries.length > 0) {
    return summaries.join("，");
  }

  return index === 0 ? "OSRM 推荐路线" : "OSRM 备选路线";
}

function toPoi(value: unknown): Poi {
  const poi = value as Partial<Poi>;

  if (typeof poi.id !== "string" || typeof poi.name !== "string" || typeof poi.category !== "string") {
    throw apiError("SEARCH_UPSTREAM_ERROR", "Search POI fields are invalid.", HttpStatus.BAD_GATEWAY);
  }

  return {
    id: poi.id,
    name: poi.name,
    category: poi.category,
    location: toWgs84Coordinate(poi.location, "poi location", "SEARCH_UPSTREAM_ERROR"),
  };
}

function toWgs84Coordinate(value: unknown, name: string, errorCode: string): Wgs84LngLat {
  if (!Array.isArray(value) || value.length !== 2) {
    throw apiError(errorCode, `${name} must be [lng, lat].`, HttpStatus.BAD_GATEWAY);
  }

  const lng = Number(value[0]);
  const lat = Number(value[1]);

  if (!Number.isFinite(lng) || !Number.isFinite(lat) || lng < -180 || lng > 180 || lat < -90 || lat > 90) {
    throw apiError(errorCode, `${name} must be valid WGS-84 [lng, lat].`, HttpStatus.BAD_GATEWAY);
  }

  return [lng, lat];
}

function assertNumber(value: number | undefined, name: string): number {
  if (typeof value !== "number" || !Number.isFinite(value)) {
    throw apiError("ROUTE_UPSTREAM_ERROR", `OSRM route ${name} is missing.`, HttpStatus.BAD_GATEWAY);
  }

  return value;
}
