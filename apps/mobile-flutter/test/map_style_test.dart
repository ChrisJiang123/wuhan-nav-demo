import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuhan_nav/core/map/map_style.dart';

void main() {
  group('buildRasterStyleJson', () {
    test('产出合法的 MapLibre style JSON', () {
      final String json = buildRasterStyleJson(
        tileUrlTemplate: 'https://example.com/tiles/{z}/{x}/{y}.png',
      );
      final Map<String, dynamic> style =
          jsonDecode(json) as Map<String, dynamic>;

      expect(style['version'], 8);
      expect(style['sources'], isA<Map<String, dynamic>>());
      expect(style['layers'], isA<List<dynamic>>());
    });

    test('瓦片模板与署名被写入 source', () {
      const String template = 'http://10.0.2.2:3000/tiles/{z}/{x}/{y}';
      const String attribution = '© OpenStreetMap contributors';
      final String json = buildRasterStyleJson(
        tileUrlTemplate: template,
        attribution: attribution,
      );
      final Map<String, dynamic> style =
          jsonDecode(json) as Map<String, dynamic>;
      final Map<String, dynamic> source =
          (style['sources'] as Map<String, dynamic>)['base-raster']
              as Map<String, dynamic>;

      expect((source['tiles'] as List<dynamic>).first, template);
      expect(source['attribution'], attribution);
      expect(source['type'], 'raster');
    });

    test('包含 background 与 raster 两个图层', () {
      final String json = buildRasterStyleJson(
        tileUrlTemplate: 'https://example.com/{z}/{x}/{y}.png',
      );
      final List<dynamic> layers =
          (jsonDecode(json) as Map<String, dynamic>)['layers']
              as List<dynamic>;
      final List<String> ids = layers
          .map((dynamic l) => (l as Map<String, dynamic>)['id'] as String)
          .toList();

      expect(ids, containsAll(<String>['background', 'base-raster']));
    });
  });
}
