import 'dart:convert';

/// 构建 MapLibre GL 的 style JSON 字符串（栅格占位底图）。
///
/// 纯函数、无副作用，便于单测。生产接入 BFF 矢量瓦片时可替换为矢量 style，
/// 但对外接口（tileUrlTemplate）保持不变。
///
/// - [tileUrlTemplate]：形如 `https://.../{z}/{x}/{y}.png` 的瓦片模板。
/// - [attribution]：数据署名（OSM 数据需注明 © OpenStreetMap contributors）。
/// - [backgroundColorHex]：底图空白处的背景色（白天底色）。
/// - [tileSize]：瓦片像素尺寸，栅格通常 256。
String buildRasterStyleJson({
  required String tileUrlTemplate,
  String attribution = '© OpenStreetMap contributors',
  String backgroundColorHex = '#F8FAFC',
  int tileSize = 256,
}) {
  final Map<String, dynamic> style = <String, dynamic>{
    'version': 8,
    'name': 'wuhan-nav-placeholder-raster',
    'sources': <String, dynamic>{
      'base-raster': <String, dynamic>{
        'type': 'raster',
        'tiles': <String>[tileUrlTemplate],
        'tileSize': tileSize,
        'attribution': attribution,
      },
    },
    'layers': <Map<String, dynamic>>[
      <String, dynamic>{
        'id': 'background',
        'type': 'background',
        'paint': <String, dynamic>{'background-color': backgroundColorHex},
      },
      <String, dynamic>{
        'id': 'base-raster',
        'type': 'raster',
        'source': 'base-raster',
        'minzoom': 0,
        'maxzoom': 22,
      },
    ],
  };

  return jsonEncode(style);
}
