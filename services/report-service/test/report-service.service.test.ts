import assert from "node:assert/strict";
import { describe, it } from "node:test";

import { HttpException, HttpStatus } from "@nestjs/common";

import { ReportService } from "../src/report-service.service";

describe("ReportService", () => {
  it("creates pending reports with WGS-84 [lng, lat] coordinates", () => {
    const service = new ReportService();
    const response = service.createReport({
      type: "construction",
      location: [114.3, 30.59],
      description: "  江汉路施工  ",
      imageRef: "demo://image-1",
      anonymous: true,
    });

    assert.deepEqual(response, {
      id: "rep_000001",
      status: "pending",
    });

    const list = service.listReports({});
    assert.equal(list.reports.length, 1);
    assert.deepEqual(list.reports[0], {
      id: "rep_000001",
      type: "construction",
      location: [114.3, 30.59],
      description: "江汉路施工",
      imageRef: "demo://image-1",
      anonymous: true,
      status: "pending",
      createdAt: list.reports[0]?.createdAt,
      updatedAt: list.reports[0]?.updatedAt,
    });
    assert.match(list.reports[0]?.createdAt ?? "", /^\d{4}-\d{2}-\d{2}T/);
  });

  it("filters reports by status and reviews pending reports", () => {
    const service = new ReportService();
    const created = service.createReport({
      type: "accident",
      location: [114.32, 30.56],
      anonymous: false,
    });

    assert.equal(service.listReports({ status: "approved" }).reports.length, 0);

    const reviewed = service.reviewReport(created.id, { status: "approved" });

    assert.equal(reviewed.status, "approved");
    assert.equal(service.listReports({ status: "pending" }).reports.length, 0);
    assert.equal(service.listReports({ status: "approved" }).reports[0]?.id, created.id);
  });

  it("rejects unsupported report types", () => {
    const service = new ReportService();

    assertHttpError(
      () =>
        service.createReport({
          type: "speed_camera",
          location: [114.3, 30.59],
          anonymous: true,
        }),
      HttpStatus.BAD_REQUEST,
      "INVALID_REPORT_TYPE",
    );
  });

  it("validates WGS-84 [lng, lat] report coordinates", () => {
    const service = new ReportService();

    assertHttpError(
      () =>
        service.createReport({
          type: "jam",
          location: [30.59, 114.3],
          anonymous: true,
        }),
      HttpStatus.BAD_REQUEST,
      "INVALID_COORDINATE",
    );
  });

  it("rejects unsupported review status and unknown report ids", () => {
    const service = new ReportService();

    assertHttpError(() => service.reviewReport("rep_missing", { status: "approved" }), HttpStatus.NOT_FOUND, "REPORT_NOT_FOUND");
    assertHttpError(() => service.reviewReport("rep_missing", { status: "pending" }), HttpStatus.BAD_REQUEST, "INVALID_REPORT_STATUS");
  });
});

function assertHttpError(action: () => unknown, status: HttpStatus, code: string): void {
  assert.throws(
    action,
    (error: unknown) => {
      assert.ok(error instanceof HttpException);
      assert.equal(error.getStatus(), status);
      assert.equal((error.getResponse() as { error?: { code?: string } }).error?.code, code);
      return true;
    },
  );
}
