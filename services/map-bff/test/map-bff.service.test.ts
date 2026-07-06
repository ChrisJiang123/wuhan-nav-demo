import assert from "node:assert/strict";
import { describe, it } from "node:test";

import { HttpException, HttpStatus } from "@nestjs/common";

import { AppConfigService } from "../src/config.service";
import { MapBffService } from "../src/map-bff.service";

function jsonResponse(body: unknown, init: ResponseInit = {}): Response {
  return new Response(JSON.stringify(body), {
    status: init.status ?? 200,
    headers: {
      "content-type": "application/json",
      ...init.headers,
    },
  });
}

describe("MapBffService", () => {
  it("maps OSRM route responses to the shared RouteResponse DTO", async () => {
    const requestedUrls: string[] = [];
    const service = new MapBffService(
      new AppConfigService({ OSRM_BASE_URL: "http://localhost:5001" }),
      async (url) => {
        requestedUrls.push(url);
        return jsonResponse({
          routes: [
            {
              duration: 1440.4,
              distance: 12400.2,
              geometry: {
                coordinates: [
                  [114.3, 30.59],
                  [114.31, 30.6],
                ],
              },
              legs: [{ summary: "武汉大道" }],
            },
          ],
        });
      },
    );

    const response = await service.getRoute({
      origin: "114.30,30.59",
      destination: "114.31,30.60",
      alternatives: undefined,
    });

    assert.equal(requestedUrls.length, 1);
    assert.match(requestedUrls[0], /^http:\/\/localhost:5001\/route\/v1\/driving\/114.3,30.59;114.31,30.6\?/);
    assert.equal(new URL(requestedUrls[0]).searchParams.get("alternatives"), "true");
    assert.deepEqual(response, {
      routes: [
        {
          id: "r1",
          durationSec: 1440,
          distanceM: 12400,
          tollEstimateYuan: 0,
          tag: "推荐",
          summary: "武汉大道",
          geometry: [
            [114.3, 30.59],
            [114.31, 30.6],
          ],
        },
      ],
    });
  });

  it("validates WGS-84 lng,lat query coordinates", async () => {
    const service = new MapBffService(new AppConfigService(), async () => {
      throw new Error("unexpected upstream request");
    });

    await assert.rejects(
      () => service.getRoute({ origin: "30.59,114.30", destination: "114.31,30.60", alternatives: undefined }),
      (error: unknown) => {
        assert.ok(error instanceof HttpException);
        assert.equal(error.getStatus(), HttpStatus.BAD_REQUEST);
        assert.deepEqual(error.getResponse(), {
          error: {
            code: "INVALID_QUERY",
            message: "origin must be valid WGS-84 lng,lat.",
          },
        });
        return true;
      },
    );
  });

  it("proxies search through SEARCH_BASE_URL and keeps WGS-84 POI locations", async () => {
    const requestedUrls: string[] = [];
    const service = new MapBffService(
      new AppConfigService({ SEARCH_BASE_URL: "http://search.local/api" }),
      async (url) => {
        requestedUrls.push(url);
        return jsonResponse({
          pois: [
            {
              id: "p1",
              name: "武汉站",
              category: "railway_station",
              location: [114.42, 30.61],
            },
          ],
        });
      },
    );

    const response = await service.search({ q: "武汉站", near: "114.3,30.59" });

    assert.equal(requestedUrls.length, 1);
    assert.equal(requestedUrls[0], "http://search.local/api/search?q=%E6%AD%A6%E6%B1%89%E7%AB%99&near=114.3%2C30.59");
    assert.deepEqual(response, {
      pois: [
        {
          id: "p1",
          name: "武汉站",
          category: "railway_station",
          location: [114.42, 30.61],
        },
      ],
    });
  });

  it("proxies vector tile requests through TILESERVER_BASE_URL", async () => {
    const requestedUrls: string[] = [];
    const service = new MapBffService(
      new AppConfigService({ TILESERVER_BASE_URL: "http://tiles.local/data/wuhan" }),
      async (url) => {
        requestedUrls.push(url);
        return new Response(new Uint8Array([1, 2, 3]), {
          headers: {
            "content-type": "application/vnd.mapbox-vector-tile",
            etag: "tile-etag",
          },
        });
      },
    );

    const response = await service.getTile({ z: "12", x: "3376", y: "1662" });

    assert.equal(requestedUrls[0], "http://tiles.local/data/wuhan/12/3376/1662");
    assert.equal(response.status, 200);
    assert.equal(response.headers["content-type"], "application/vnd.mapbox-vector-tile");
    assert.equal(response.headers.etag, "tile-etag");
    assert.deepEqual(Array.from(new Uint8Array(response.body)), [1, 2, 3]);
  });
});
