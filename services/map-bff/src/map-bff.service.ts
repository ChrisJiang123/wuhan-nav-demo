import { HttpStatus, Inject, Injectable, Optional } from "@nestjs/common";

import type {
  Poi,
  RouteOption,
  RouteResponse,
  SearchResponse,
  Wgs84LngLat,
} from "@wuhan-nav/shared-types";

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

    const url = new URL(joinUrl(this.config.searchBaseUrl, "search"));
    url.searchParams.set("q", q);

    if (request.near) {
      url.searchParams.set("near", formatLngLat(parseLngLatQuery(request.near, "near")));
    }

    const payload = await this.fetchJson<SearchResponse>(url.toString(), "SEARCH_UPSTREAM_ERROR");
    const pois = Array.isArray(payload.pois) ? payload.pois.map(toPoi) : [];

    return { pois };
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
