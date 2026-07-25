import { Body, Controller, Get, Param, Patch, Post, Query } from "@nestjs/common";

import type {
  Report,
  ReportCreateResponse,
  ReportListResponse,
} from "@wuhan-nav/shared-types";

import { ReportService } from "./report-service.service";

@Controller()
export class ReportServiceController {
  constructor(private readonly reportService: ReportService) {}

  @Post("reports")
  createReport(@Body() body: unknown): ReportCreateResponse {
    return this.reportService.createReport(body);
  }

  @Get("reports")
  listReports(@Query("status") status?: string): ReportListResponse {
    return this.reportService.listReports(status === undefined ? {} : { status });
  }

  @Patch("reports/:id")
  reviewReport(@Param("id") id: string, @Body() body: unknown): Report {
    return this.reportService.reviewReport(id, body);
  }
}
