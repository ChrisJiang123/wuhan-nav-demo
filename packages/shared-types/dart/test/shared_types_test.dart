import 'package:flutter_test/flutter_test.dart';
import 'package:shared_types/shared_types.dart';

void main() {
  group('Wgs84LngLat', () {
    test('fromJson 解析 [lng, lat]', () {
      final Wgs84LngLat coord = Wgs84LngLat.fromJson(<dynamic>[114.4249, 30.6073]);
      expect(coord.lng, 114.4249);
      expect(coord.lat, 30.6073);
      expect(coord.toJson(), <double>[114.4249, 30.6073]);
    });

    test('toQueryParam 输出 lng,lat', () {
      const Wgs84LngLat coord = Wgs84LngLat(lng: 114.3, lat: 30.59);
      expect(coord.toQueryParam(), '114.3,30.59');
    });
  });

  group('RouteResponse', () {
    test('fromJson 解析 mock 路线字段', () {
      final RouteResponse response = RouteResponse.fromJson(<String, dynamic>{
        'routes': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'mock-r1',
            'durationSec': 1043,
            'distanceM': 19884,
            'tollEstimateYuan': 0,
            'tag': '推荐',
            'summary': 'mock·经二环过长江（武汉站→汉口站）',
            'geometry': <List<double>>[
              <double>[114.4249, 30.6073],
              <double>[114.2546, 30.618],
            ],
          },
        ],
      });

      expect(response.routes.single.id, 'mock-r1');
      expect(response.routes.single.distanceM, 19884);
      expect(response.routes.single.durationSec, 1043);
    });
  });
}
