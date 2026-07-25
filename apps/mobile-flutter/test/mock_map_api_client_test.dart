import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_types/shared_types.dart';
import 'package:wuhan_nav/core/map_provider/mock_map_api_client.dart';

const String _poisJson = '''
[
  {
    "id": "osm-poi-wuhan-railway-station",
    "name": "武汉站",
    "category": "railway_station",
    "location": [114.4249, 30.6073],
    "aliases": ["武汉火车站"]
  },
  {
    "id": "osm-poi-hankou-railway-station",
    "name": "汉口站",
    "category": "railway_station",
    "location": [114.2546, 30.618],
    "aliases": ["汉口火车站"]
  }
]
''';

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
          "summary": "mock·经二环过长江（武汉站→汉口站）",
          "geometry": [[114.4249, 30.6073], [114.2546, 30.618]]
        }
      ]
    }
  }
]
''';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  MockMapApiClient newClient() {
    return MockMapApiClient(
      assetLoader: (String path) async {
        if (path.contains('wuhan-pois')) {
          return _poisJson;
        }
        if (path.contains('wuhan-routes')) {
          return _routesJson;
        }
        throw FlutterError('unknown asset: $path');
      },
    );
  }

  group('MockMapApiClient', () {
    test('search 返回匹配的 POI', () async {
      final MockMapApiClient client = newClient();
      final SearchResponse response = await client.search(query: '武汉站');

      expect(response.pois.single.name, '武汉站');
      expect(response.pois.single.location.lng, 114.4249);
    });

    test('getRoute 返回 mock 路线且 distance 贴近实测', () async {
      final MockMapApiClient client = newClient();
      final RouteResponse response = await client.getRoute(
        origin: const Wgs84LngLat(lng: 114.4249, lat: 30.6073),
        destination: const Wgs84LngLat(lng: 114.2546, lat: 30.618),
      );

      expect(response.routes.single.id, startsWith('mock-'));
      expect(response.routes.single.distanceM, 19884);
      expect(response.routes.single.durationSec, 1043);
      expect(response.routes.single.summary, contains('mock'));
    });
  });
}
