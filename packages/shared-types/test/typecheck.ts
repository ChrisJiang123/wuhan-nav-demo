import type {
  Poi,
  ReportCreateRequest,
  ReportReviewRequest,
  RouteResponse,
  Wgs84LngLat,
} from "../src/index";

const wuhanStation: Wgs84LngLat = [114.42, 30.61];

const routeResponse: RouteResponse = {
  routes: [
    {
      id: "r1",
      durationSec: 1440,
      distanceM: 12400,
      tollEstimateYuan: 6,
      tag: "recommended",
      summary: "Demo route",
      geometry: [
        [114.3, 30.59],
        [114.31, 30.6],
      ],
    },
  ],
};

const poi: Poi = {
  id: "p1",
  name: "Wuhan Railway Station",
  category: "railway_station",
  location: wuhanStation,
};

const report: ReportCreateRequest = {
  type: "construction",
  location: [114.3, 30.59],
  description: "Demo report text",
  anonymous: true,
};

const review: ReportReviewRequest = {
  status: "approved",
};

void routeResponse;
void poi;
void report;
void review;
