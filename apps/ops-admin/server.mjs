import { createServer } from "node:http";
import { readFile } from "node:fs/promises";
import { extname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const currentDir = resolve(fileURLToPath(new URL(".", import.meta.url)));
const publicDir = join(currentDir, "public");
const port = parsePort(process.env.OPS_ADMIN_PORT ?? "3002", "OPS_ADMIN_PORT");
const reportServiceBaseUrl = parseBaseUrl(process.env.REPORT_SERVICE_BASE_URL ?? "http://localhost:3001", "REPORT_SERVICE_BASE_URL");

const contentTypes = new Map([
  [".css", "text/css; charset=utf-8"],
  [".html", "text/html; charset=utf-8"],
  [".js", "text/javascript; charset=utf-8"],
]);

const server = createServer(async (request, response) => {
  if (request.method !== "GET" && request.method !== "HEAD") {
    writeText(response, 405, "Method not allowed");
    return;
  }

  const url = new URL(request.url ?? "/", `http://${request.headers.host ?? "localhost"}`);
  const filePath = resolveAsset(url.pathname);

  if (!filePath) {
    writeText(response, 404, "Not found");
    return;
  }

  try {
    let body = await readFile(filePath, "utf8");
    const extension = extname(filePath);

    if (extension === ".html") {
      body = body.replace(
        "<!-- OPS_ADMIN_CONFIG -->",
        `<script>window.__OPS_ADMIN_CONFIG__ = ${JSON.stringify({ reportServiceBaseUrl })};</script>`,
      );
    }

    response.writeHead(200, {
      "cache-control": "no-store",
      "content-type": contentTypes.get(extension) ?? "text/plain; charset=utf-8",
    });
    response.end(request.method === "HEAD" ? undefined : body);
  } catch {
    writeText(response, 404, "Not found");
  }
});

server.listen(port, "0.0.0.0", () => {
  console.log(`Ops admin listening on http://0.0.0.0:${port}`);
});

function resolveAsset(pathname) {
  const assetPath = pathname === "/" ? "/index.html" : pathname;
  const decodedPath = decodeURIComponent(assetPath);
  const resolvedPath = resolve(publicDir, `.${decodedPath}`);
  const publicRoot = `${publicDir}/`;

  if (resolvedPath !== publicDir && !resolvedPath.startsWith(publicRoot)) {
    return undefined;
  }

  return resolvedPath;
}

function parsePort(value, name) {
  const parsed = Number(value);

  if (!Number.isInteger(parsed) || parsed <= 0 || parsed > 65535) {
    throw new Error(`Invalid ${name}: ${value}`);
  }

  return parsed;
}

function parseBaseUrl(value, name) {
  try {
    const url = new URL(value);
    return url.toString().replace(/\/$/, "");
  } catch {
    throw new Error(`Invalid ${name}: ${value}`);
  }
}

function writeText(response, statusCode, body) {
  response.writeHead(statusCode, {
    "content-type": "text/plain; charset=utf-8",
  });
  response.end(body);
}
