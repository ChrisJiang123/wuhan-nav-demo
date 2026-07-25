import { HttpStatus, Injectable } from "@nestjs/common";

import type {
  Report,
  ReportCreateRequest,
  ReportCreateResponse,
  ReportListResponse,
  ReportReviewRequest,
  ReportStatus,
  ReportType,
  Wgs84LngLat,
} from "@wuhan-nav/shared-types";

import { apiError } from "./errors";

interface ReportListRequest {
  status?: string;
}

const reportTypes = [
  "accident",
  "construction",
  "jam",
  "closure",
  "illegal_parking",
  "pothole",
  "checkpoint",
] as const satisfies readonly ReportType[];

const reportStatuses = ["pending", "approved", "rejected"] as const satisfies readonly ReportStatus[];
const reviewStatuses = ["approved", "rejected"] as const satisfies readonly ReportReviewRequest["status"][];

@Injectable()
export class ReportService {
  private readonly reports = new Map<string, Report>();
  private nextId = 1;

  createReport(body: unknown): ReportCreateResponse {
    const request = parseCreateRequest(body);
    const timestamp = new Date().toISOString();
    const report: Report = {
      id: this.createId(),
      type: request.type,
      location: request.location,
      anonymous: request.anonymous,
      status: "pending",
      createdAt: timestamp,
      updatedAt: timestamp,
      ...(request.description !== undefined ? { description: request.description } : {}),
      ...(request.imageRef !== undefined ? { imageRef: request.imageRef } : {}),
    };

    this.reports.set(report.id, report);

    return {
      id: report.id,
      status: "pending",
    };
  }

  listReports(query: ReportListRequest): ReportListResponse {
    const status = query.status === undefined ? undefined : parseReportStatus(query.status);
    const reports = Array.from(this.reports.values())
      .filter((report) => status === undefined || report.status === status)
      .sort((left, right) => compareNullableStrings(right.createdAt, left.createdAt));

    return { reports };
  }

  reviewReport(id: string, body: unknown): Report {
    const status = parseReviewRequest(body).status;
    const report = this.reports.get(id);

    if (!report) {
      throw apiError("REPORT_NOT_FOUND", "Report was not found.", HttpStatus.NOT_FOUND);
    }

    const updated: Report = {
      ...report,
      status,
      updatedAt: new Date().toISOString(),
    };

    this.reports.set(id, updated);
    return updated;
  }

  private createId(): string {
    const id = `rep_${String(this.nextId).padStart(6, "0")}`;
    this.nextId += 1;
    return id;
  }
}

function parseCreateRequest(body: unknown): ReportCreateRequest {
  const payload = readObject(body);
  const type = parseReportType(payload.type);
  const location = parseWgs84LngLat(payload.location, "location");
  const anonymous = parseBoolean(payload.anonymous, "anonymous");
  const description = parseOptionalString(payload.description, "description");
  const imageRef = parseOptionalString(payload.imageRef, "imageRef");

  return {
    type,
    location,
    anonymous,
    ...(description !== undefined ? { description } : {}),
    ...(imageRef !== undefined ? { imageRef } : {}),
  };
}

function parseReviewRequest(body: unknown): ReportReviewRequest {
  const payload = readObject(body);
  const rawStatus = payload.status;

  if (!isStringLiteral(rawStatus, reviewStatuses)) {
    throw apiError("INVALID_REPORT_STATUS", "status must be approved or rejected.", HttpStatus.BAD_REQUEST);
  }

  return { status: rawStatus };
}

function parseReportType(value: unknown): ReportType {
  if (!isStringLiteral(value, reportTypes)) {
    throw apiError("INVALID_REPORT_TYPE", "type is not supported.", HttpStatus.BAD_REQUEST);
  }

  return value;
}

function parseReportStatus(value: unknown): ReportStatus {
  if (!isStringLiteral(value, reportStatuses)) {
    throw apiError("INVALID_REPORT_STATUS", "status is not supported.", HttpStatus.BAD_REQUEST);
  }

  return value;
}

function parseWgs84LngLat(value: unknown, name: string): Wgs84LngLat {
  if (!Array.isArray(value) || value.length !== 2) {
    throw apiError("INVALID_COORDINATE", `${name} must be WGS-84 [lng, lat].`, HttpStatus.BAD_REQUEST);
  }

  const lng = Number(value[0]);
  const lat = Number(value[1]);

  if (!Number.isFinite(lng) || !Number.isFinite(lat) || lng < -180 || lng > 180 || lat < -90 || lat > 90) {
    throw apiError("INVALID_COORDINATE", `${name} must be valid WGS-84 [lng, lat].`, HttpStatus.BAD_REQUEST);
  }

  return [lng, lat];
}

function parseBoolean(value: unknown, name: string): boolean {
  if (typeof value !== "boolean") {
    throw apiError("INVALID_REPORT_FIELD", `${name} must be a boolean.`, HttpStatus.BAD_REQUEST);
  }

  return value;
}

function parseOptionalString(value: unknown, name: string): string | undefined {
  if (value === undefined || value === null) {
    return undefined;
  }

  if (typeof value !== "string") {
    throw apiError("INVALID_REPORT_FIELD", `${name} must be a string.`, HttpStatus.BAD_REQUEST);
  }

  const trimmed = value.trim();
  return trimmed === "" ? undefined : trimmed;
}

function readObject(value: unknown): Record<string, unknown> {
  if (typeof value !== "object" || value === null || Array.isArray(value)) {
    throw apiError("INVALID_REQUEST", "Request body must be a JSON object.", HttpStatus.BAD_REQUEST);
  }

  return value as Record<string, unknown>;
}

function isStringLiteral<T extends string>(value: unknown, literals: readonly T[]): value is T {
  return typeof value === "string" && literals.includes(value as T);
}

function compareNullableStrings(left: string | undefined, right: string | undefined): number {
  return (left ?? "").localeCompare(right ?? "");
}
