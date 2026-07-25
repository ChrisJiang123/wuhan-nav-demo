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
    const rawPort = this.env.REPORT_PORT ?? "3001";
    const port = Number(rawPort);

    if (!Number.isInteger(port) || port <= 0 || port > 65535) {
      throw new Error(`Invalid REPORT_PORT: ${rawPort}`);
    }

    return port;
  }
}
