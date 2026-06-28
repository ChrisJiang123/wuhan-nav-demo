/**
 * WGS-84 longitude/latitude coordinate pair.
 *
 * The tuple order is always [lng, lat]. Do not pass GCJ-02 or BD-09
 * coordinates through these DTOs.
 */
export type Wgs84LngLat = readonly [lng: number, lat: number];

export type RouteTag = "recommended" | "fastest" | "shortest" | "alternative" | string;

export interface ErrorBody {
  error: {
    code: string;
    message: string;
  };
}

export interface RouteQuery {
  /** WGS-84 origin coordinate encoded as "lng,lat". */
  origin: string;
  /** WGS-84 destination coordinate encoded as "lng,lat". */
  destination: string;
  /** Return 1-3 route options when supported by the routing engine. */
  alternatives?: boolean;
}

export interface RouteOption {
  id: string;
  /** Duration in seconds. */
  durationSec: number;
  /** Distance in meters. */
  distanceM: number;
  /** Placeholder or estimated toll in yuan. */
  tollEstimateYuan: number;
  tag: RouteTag;
  summary: string;
  /** Route polyline in WGS-84 [lng, lat] coordinates. */
  geometry: readonly Wgs84LngLat[];
}

export interface RouteResponse {
  routes: readonly RouteOption[];
}

export interface SearchQuery {
  q: string;
  /** Optional WGS-84 search bias encoded as "lng,lat". */
  near?: string;
}

export interface Poi {
  id: string;
  name: string;
  category: string;
  /** POI location in WGS-84 [lng, lat] coordinates. */
  location: Wgs84LngLat;
}

export interface SearchResponse {
  pois: readonly Poi[];
}

export interface TileParams {
  z: number;
  x: number;
  y: number;
}

export type ReportType =
  | "accident"
  | "construction"
  | "jam"
  | "closure"
  | "illegal_parking"
  | "pothole"
  | "checkpoint";

export type ReportStatus = "pending" | "approved" | "rejected";

export interface ReportCreateRequest {
  type: ReportType;
  /** Report location in WGS-84 [lng, lat] coordinates. */
  location: Wgs84LngLat;
  description?: string;
  imageRef?: string;
  anonymous: boolean;
}

export interface ReportCreateResponse {
  id: string;
  status: "pending";
}

export interface Report {
  id: string;
  type: ReportType;
  /** Report location in WGS-84 [lng, lat] coordinates. */
  location: Wgs84LngLat;
  description?: string;
  imageRef?: string;
  anonymous: boolean;
  status: ReportStatus;
  createdAt?: string;
  updatedAt?: string;
}

export interface ReportListQuery {
  status?: ReportStatus;
}

export interface ReportListResponse {
  reports: readonly Report[];
}

export interface ReportReviewRequest {
  status: "approved" | "rejected";
}
