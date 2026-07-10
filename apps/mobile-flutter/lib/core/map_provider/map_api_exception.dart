import 'package:shared_types/shared_types.dart';

/// map-bff 客户端异常，对应 [ErrorBody] 或 HTTP 层错误。
class MapApiException implements Exception {
  const MapApiException({
    required this.code,
    required this.message,
    this.statusCode,
  });

  final String code;
  final String message;
  final int? statusCode;

  factory MapApiException.fromErrorBody(ErrorBody body, {int? statusCode}) {
    return MapApiException(
      code: body.code,
      message: body.message,
      statusCode: statusCode,
    );
  }

  @override
  String toString() => 'MapApiException($code: $message)';
}
