import 'package:shared_types/shared_types.dart';

import '../config/env.dart';
import 'bff_map_api_client.dart';
import 'map_api_client.dart';
import 'map_api_exception.dart';
import 'mock_map_api_client.dart';

/// 优先调 BFF；失败时回落 mock fixtures（仅 Debug 联调便利，仍只经 BFF 不直连 OSRM）。
class ResolvingMapApiClient implements MapApiClient {
  ResolvingMapApiClient({
    required String bffBaseUrl,
    required MockMapApiClient mockClient,
    required void Function(MapDataSource source) onSourceChanged,
    BffMapApiClient? bffClient,
  })  : _bffClient = bffClient ?? BffMapApiClient(baseUrl: bffBaseUrl),
        _mockClient = mockClient,
        _onSourceChanged = onSourceChanged;

  final BffMapApiClient _bffClient;
  final MockMapApiClient _mockClient;
  final void Function(MapDataSource source) _onSourceChanged;

  void _mark(MapDataSource source) => _onSourceChanged(source);

  @override
  Future<RouteResponse> getRoute({
    required Wgs84LngLat origin,
    required Wgs84LngLat destination,
    bool alternatives = true,
  }) async {
    try {
      final RouteResponse response = await _bffClient.getRoute(
        origin: origin,
        destination: destination,
        alternatives: alternatives,
      );
      _mark(MapDataSource.bff);
      return response;
    } on MapApiException {
      final RouteResponse response = await _mockClient.getRoute(
        origin: origin,
        destination: destination,
        alternatives: alternatives,
      );
      _mark(MapDataSource.mockFallback);
      return response;
    } catch (_) {
      final RouteResponse response = await _mockClient.getRoute(
        origin: origin,
        destination: destination,
        alternatives: alternatives,
      );
      _mark(MapDataSource.mockFallback);
      return response;
    }
  }

  @override
  Future<SearchResponse> search({
    required String query,
    Wgs84LngLat? near,
  }) async {
    try {
      final SearchResponse response =
          await _bffClient.search(query: query, near: near);
      return response;
    } catch (_) {
      return _mockClient.search(query: query, near: near);
    }
  }
}
