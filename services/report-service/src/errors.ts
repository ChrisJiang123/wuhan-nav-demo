import { HttpException, HttpStatus } from "@nestjs/common";

import type { ErrorBody } from "@wuhan-nav/shared-types";

export function apiError(code: string, message: string, status: HttpStatus): HttpException {
  const body: ErrorBody = {
    error: {
      code,
      message,
    },
  };

  return new HttpException(body, status);
}
