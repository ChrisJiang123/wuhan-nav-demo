import { Inject, Injectable, Optional } from "@nestjs/common";

type Env = Record<string, string | undefined>;

export const APP_ENV = "APP_ENV";

@Injectable()
export class AppConfigService {
  private readonly env: Env;

  constructor(@Optional() @Inject(APP_ENV) env?: Env) {
    this.env = env ?? process.env;
  }

  get port(): number {
    const rawPort = this.env.BFF_PORT ?? "3000";
    const port = Number(rawPort);

    if (!Number.isInteger(port) || port <= 0 || port > 65535) {
      throw new Error(`Invalid BFF_PORT: ${rawPort}`);
    }

    return port;
  }

  get osrmBaseUrl(): string {
    return this.readBaseUrl("OSRM_BASE_URL", "http://localhost:5001");
  }

  get searchBaseUrl(): string {
    return this.readBaseUrl("SEARCH_BASE_URL", "http://localhost:7070");
  }

  get tileserverBaseUrl(): string {
    return this.readBaseUrl("TILESERVER_BASE_URL", "http://localhost:8080");
  }

  private readBaseUrl(name: string, fallback: string): string {
    const rawUrl = this.env[name] ?? fallback;

    try {
      const url = new URL(rawUrl);
      return url.toString().replace(/\/$/, "");
    } catch {
      throw new Error(`Invalid ${name}: ${rawUrl}`);
    }
  }
}
