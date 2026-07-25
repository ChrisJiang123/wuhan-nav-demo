import { Module } from "@nestjs/common";

import { AppConfigService } from "./config.service";
import { ReportServiceController } from "./report-service.controller";
import { ReportService } from "./report-service.service";

@Module({
  controllers: [ReportServiceController],
  providers: [AppConfigService, ReportService],
})
export class AppModule {}
