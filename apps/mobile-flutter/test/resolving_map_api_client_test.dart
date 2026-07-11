import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_types/shared_types.dart';
import 'package:wuhan_nav/core/config/env.dart';
import 'package:wuhan_nav/core/map_provider/bff_map_api_client.dart';
import 'package:wuhan_nav/core/map_provider/mock_map_api_client.dart';
import 'package:wuhan_nav/core/map_provider/resolving_map_api_client.dart';

const String _routesJson = '''
[
  {
    "id": "mock-wuhan-station-to-hankou-station",
    "origin": [114.4249, 30.6073],
    "destination": [114.2546, 30.618],
    "response": {
      "routes": [
        {
          "id": "mock-r1",
          "durationSec": 1043,
          "distanceM": 19884,
          "tollEstimateYuan": 0,
          "tag": "推荐",
          "summary": "mock",
          "geometry": [[114.4249, 30.6073], [114.2546, 30.618]]
        }
      ]
    }
  }
]
''';

void main() {
  test('ResolvingMapApiClient BFF 成功时标记 bff', () async {
    MapDataSource? source;
    final MockClient httpClient = MockClient((http.Request request) async {
      return http.Response(
        jsonEncode(<String, dynamic>{
          'routes': <Map<String, dynamic>>[
            <String, dynamic>{
              'id': 'r1',
              'durationSec': 1043,
              'distanceM': 19884,
              'tollEstimateYuan': 0,
              'tag': '推荐',
              'summary': 'OSRM',
              'geometry': <List<double>>[
                <double>[114.42, 30.60],
                <double>[114.40, 30.61],
                <double>[114.25, 30.62],
              ],
            },
          ],
        }),
        200,
      );
    });

    final ResolvingMapApiClient client = ResolvingMapApiClient(
      bffBaseUrl: 'http://localhost:3000',
      mockClient: MockMapApiClient(assetLoader: (_) async => _routesJson),
      onSourceChanged: (MapDataSource s) => source = s,
      bffClient: BffMapApiClient(
        baseUrl: 'http://localhost:3000',
        httpClient: httpClient,
      ),
    );

    final RouteResponse response = await client.getRoute(
      origin: const Wgs84LngLat(lng: 114.4249, lat: 30.6073),
      destination: const Wgs84LngLat(lng: 114.2546, lat: 30.618),
    );

    expect(source, MapDataSource.bff);
    expect(response.routes.single.summary, 'OSRM');
    httpClient.close();
  });

  test('ResolvingMapApiClient BFF 失败时回落 mock', () async {
    MapDataSource? source;
    final MockClient httpClient = MockClient((http.Request request) async {
      return http.Response('{}', 502);
    });

    final ResolvingMapApiClient client = ResolvingMapApiClient(
      bffBaseUrl: 'http://localhost:3000',
      mockClient: MockMapApiClient(assetLoader: (_) async => _routesJson),
      onSourceChanged: (MapDataSource s) => source = s,
      bffClient: BffMapApiClient(
        baseUrl: 'http://localhost:3000',
        httpClient: httpClient,
      ),
    );

    await client.getRoute(
      origin: const Wgs84LngLat(lng: 114.4249, lat: 30.6073),
      destination: const Wgs84LngLat(lng: 114.2546, lat: 30.618),
    );

    expect(source, MapDataSource.mockFallback);
    httpClient.close();
  });
}
