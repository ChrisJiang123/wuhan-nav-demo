import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_types/shared_types.dart';

import 'map_api_client.dart';
import 'map_api_exception.dart';

/// 经 BFF 访问路由/搜索的真实 HTTP 客户端。
///
/// 只调 map-bff 的 `/route` 与 `/search`，不直连底层服务。
class BffMapApiClient implements MapApiClient {
  BffMapApiClient({
    required String baseUrl,
    http.Client? httpClient,
  })  : _baseUrl = _normalizeBaseUrl(baseUrl),
        _httpClient = httpClient ?? http.Client();

  final String _baseUrl;
  final http.Client _httpClient;

  @override
  Future<RouteResponse> getRoute({
    required Wgs84LngLat origin,
    required Wgs84LngLat destination,
    bool alternatives = true,
  }) async {
    final Uri uri = Uri.parse('$_baseUrl/route').replace(
      queryParameters: <String, String>{
        'origin': origin.toQueryParam(),
        'destination': destination.toQueryParam(),
        'alternatives': alternatives ? 'true' : 'false',
      },
    );
    return _getJson(uri, RouteResponse.fromJson);
  }

  @override
  Future<SearchResponse> search({
    required String query,
    Wgs84LngLat? near,
  }) async {
    final Map<String, String> params = <String, String>{'q': query.trim()};
    if (near != null) {
      params['near'] = near.toQueryParam();
    }
    final Uri uri =
        Uri.parse('$_baseUrl/search').replace(queryParameters: params);
    return _getJson(uri, SearchResponse.fromJson);
  }

  Future<T> _getJson<T>(
    Uri uri,
    T Function(Map<String, dynamic> json) parser,
  ) async {
    final http.Response response;
    try {
      response = await _httpClient.get(uri);
    } catch (error) {
      throw MapApiException(
        code: 'NETWORK_ERROR',
        message: '无法连接 BFF：$error',
      );
    }

    Map<String, dynamic>? body;
    if (response.body.isNotEmpty) {
      try {
        body = jsonDecode(response.body) as Map<String, dynamic>;
      } on FormatException {
        throw MapApiException(
          code: 'INVALID_RESPONSE',
          message: 'BFF 返回非 JSON 响应（HTTP ${response.statusCode}）。',
          statusCode: response.statusCode,
        );
      }
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      if (body != null && body.containsKey('error')) {
        throw MapApiException.fromErrorBody(
          ErrorBody.fromJson(body),
          statusCode: response.statusCode,
        );
      }
      throw MapApiException(
        code: 'HTTP_${response.statusCode}',
        message: 'BFF 请求失败（HTTP ${response.statusCode}）。',
        statusCode: response.statusCode,
      );
    }

    if (body == null) {
      throw const MapApiException(
        code: 'INVALID_RESPONSE',
        message: 'BFF 返回空响应体。',
      );
    }

    try {
      return parser(body);
    } on FormatException catch (error) {
      throw MapApiException(
        code: 'INVALID_RESPONSE',
        message: 'BFF 响应字段不符合契约：$error',
        statusCode: response.statusCode,
      );
    }
  }

  void close() => _httpClient.close();

  static String _normalizeBaseUrl(String baseUrl) {
    final String trimmed = baseUrl.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('BFF baseUrl 不能为空。');
    }
    return trimmed.endsWith('/') ? trimmed.substring(0, trimmed.length - 1) : trimmed;
  }
}
