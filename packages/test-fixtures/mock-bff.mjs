import { createServer } from "node:http";
import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";

const currentDir = dirname(fileURLToPath(import.meta.url));
const routeFixtures = readJson("wuhan-routes.json");
const poiFixtures = readJson("wuhan-pois.json");
const port = Number(process.env.MOCK_BFF_PORT ?? "3109");

if (!Number.isInteger(port) || port <= 0 || port > 65535) {
  throw new Error(`Invalid MOCK_BFF_PORT: ${process.env.MOCK_BFF_PORT}`);
}

const server = createServer((request, response) => {
  const url = new URL(request.url ?? "/", `http://${request.headers.host ?? "localhost"}`);

  if (request.method === "GET" && url.pathname === "/search") {
    writeJson(response, lookupSearch(url.searchParams.get("q") ?? ""));
    return;
  }

  if (request.method === "GET" && url.pathname === "/route") {
    const route = lookupRoute(
      url.searchParams.get("origin") ?? "",
      url.searchParams.get("destination") ?? "",
      url.searchParams.get("alternatives") ?? "true",
    );

    if (route) {
      writeJson(response, route);
      return;
    }

    writeJson(
      response,
      { error: { code: "ROUTE_NOT_FOUND", message: "Mock route is not defined for these coordinates." } },
      404,
    );
    return;
  }

  writeJson(response, { error: { code: "NOT_FOUND", message: "Mock endpoint not found." } }, 404);
});

server.listen(port, "0.0.0.0", () => {
  console.log(`Mock BFF listening on http://0.0.0.0:${port}`);
});

function readJson(fileName) {
  return JSON.parse(readFileSync(join(currentDir, fileName), "utf8"));
}

function normalizeSearchText(value) {
  return value.toLocaleLowerCase("zh-CN").replace(/\s+/g, "");
}

function lookupSearch(query) {
  const normalized = normalizeSearchText(query);
  const pois = poiFixtures
    .map((poi) => ({ poi, score: scorePoi(poi, normalized) }))
    .filter(({ score }) => score > 0)
    .sort((left, right) => right.score - left.score)
    .slice(0, 10)
    .map(({ poi }) => ({
      id: poi.id,
      name: poi.name,
      category: poi.category,
      location: poi.location,
    }));

  return { pois };
}

function scorePoi(poi, normalizedQuery) {
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

  return score;
}

function lookupRoute(origin, destination, alternatives) {
  const originKey = toMatchKey(origin);
  const destinationKey = toMatchKey(destination);
  const fixture = routeFixtures.find(
    (route) => toMatchKey(route.origin.join(",")) === originKey && toMatchKey(route.destination.join(",")) === destinationKey,
  );

  if (!fixture) {
    return undefined;
  }

  if (["false", "0"].includes(alternatives.toLocaleLowerCase("zh-CN"))) {
    return { routes: fixture.response.routes.slice(0, 1) };
  }

  return fixture.response;
}

function toMatchKey(value) {
  const [lng, lat] = value.split(",").map(Number);
  return `${lng.toFixed(4)},${lat.toFixed(4)}`;
}

function writeJson(response, body, statusCode = 200) {
  response.writeHead(statusCode, {
    "access-control-allow-origin": "*",
    "content-type": "application/json; charset=utf-8",
  });
  response.end(JSON.stringify(body));
}
