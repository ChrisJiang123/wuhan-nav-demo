import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_types/shared_types.dart';
import 'package:wuhan_nav/core/map_provider/bff_map_api_client.dart';
import 'package:wuhan_nav/core/map_provider/map_api_exception.dart';

void main() {
  group('BffMapApiClient', () {
    test('getRoute 调 BFF /route 并解析 RouteResponse', () async {
      final MockClient httpClient = MockClient((http.Request request) async {
        expect(request.url.path, '/route');
        expect(request.url.queryParameters['origin'], '114.4249,30.6073');
        expect(request.url.queryParameters['destination'], '114.2546,30.618');
        expect(request.url.queryParameters['alternatives'], 'true');
        return http.Response(
          jsonEncode(<String, dynamic>{
            'routes': <Map<String, dynamic>>[
              <String, dynamic>{
                'id': 'r1',
                'durationSec': 1043,
                'distanceM': 19884,
                'tollEstimateYuan': 0,
                'tag': '推荐',
                'summary': '经二环',
                'geometry': <List<double>>[
                  <double>[114.4249, 30.6073],
                  <double>[114.2546, 30.618],
                ],
              },
            ],
          }),
          200,
          headers: <String, String>{'content-type': 'application/json'},
        );
      });

      final BffMapApiClient client = BffMapApiClient(
        baseUrl: 'http://localhost:3000',
        httpClient: httpClient,
      );

      final RouteResponse response = await client.getRoute(
        origin: const Wgs84LngLat(lng: 114.4249, lat: 30.6073),
        destination: const Wgs84LngLat(lng: 114.2546, lat: 30.618),
      );

      expect(response.routes.single.distanceM, 19884);
      httpClient.close();
    });

    test('search 调 BFF /search', () async {
      final MockClient httpClient = MockClient((http.Request request) async {
        expect(request.url.path, '/search');
        expect(request.url.queryParameters['q'], '武汉站');
        return http.Response(
          jsonEncode(<String, dynamic>{
            'pois': <Map<String, dynamic>>[
              <String, dynamic>{
                'id': 'osm-poi-wuhan-railway-station',
                'name': '武汉站',
                'category': 'railway_station',
                'location': <double>[114.4249, 30.6073],
              },
            ],
          }),
          200,
        );
      });

      final BffMapApiClient client = BffMapApiClient(
        baseUrl: 'http://localhost:3000',
        httpClient: httpClient,
      );

      final SearchResponse response = await client.search(query: '武汉站');
      expect(response.pois.single.name, '武汉站');
      httpClient.close();
    });

    test('BFF 错误体映射为 MapApiException', () async {
      final MockClient httpClient = MockClient((http.Request request) async {
        return http.Response(
          jsonEncode(<String, dynamic>{
            'error': <String, String>{
              'code': 'ROUTE_NOT_FOUND',
              'message': '未找到路线',
            },
          }),
          404,
        );
      });

      final BffMapApiClient client = BffMapApiClient(
        baseUrl: 'http://localhost:3000',
        httpClient: httpClient,
      );

      expect(
        () => client.getRoute(
          origin: const Wgs84LngLat(lng: 114.4249, lat: 30.6073),
          destination: const Wgs84LngLat(lng: 114.2546, lat: 30.618),
        ),
        throwsA(
          isA<MapApiException>()
              .having((MapApiException e) => e.code, 'code', 'ROUTE_NOT_FOUND')
              .having((MapApiException e) => e.statusCode, 'statusCode', 404),
        ),
      );
      httpClient.close();
    });
  });
}
