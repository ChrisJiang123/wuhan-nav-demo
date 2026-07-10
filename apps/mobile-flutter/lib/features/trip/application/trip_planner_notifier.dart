import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_types/shared_types.dart';

import '../../../core/map_provider/map_api_client.dart';
import '../../../core/map_provider/map_api_exception.dart';
import '../../../core/map_provider/map_provider.dart';
import 'trip_planner_state.dart';

final tripPlannerProvider =
    NotifierProvider<TripPlannerNotifier, TripPlannerState>(
  TripPlannerNotifier.new,
);

class TripPlannerNotifier extends Notifier<TripPlannerState> {
  Timer? _debounce;

  @override
  TripPlannerState build() {
    ref.onDispose(() => _debounce?.cancel());
    return const TripPlannerState();
  }

  MapApiClient get _client => ref.read(mapApiClientProvider);

  void setActiveField(ActiveEndpointField field) {
    state = state.copyWith(activeField: field, clearError: true);
  }

  void updateSearchQuery(String query) {
    state = state.copyWith(searchQuery: query, clearError: true);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      // ignore: discarded_futures
      _runSearch(query);
    });
  }

  Future<void> _runSearch(String query) async {
    final String trimmed = query.trim();
    if (trimmed.isEmpty) {
      state = state.copyWith(searchResults: const <Poi>[], isSearching: false);
      return;
    }

    state = state.copyWith(isSearching: true, clearError: true);
    try {
      final Wgs84LngLat? near = _nearBias();
      final SearchResponse response =
          await _client.search(query: trimmed, near: near);
      state = state.copyWith(
        searchResults: response.pois,
        isSearching: false,
      );
    } on MapApiException catch (error) {
      state = state.copyWith(
        isSearching: false,
        searchResults: const <Poi>[],
        errorMessage: error.message,
      );
    } catch (error) {
      state = state.copyWith(
        isSearching: false,
        searchResults: const <Poi>[],
        errorMessage: '搜索失败：$error',
      );
    }
  }

  Wgs84LngLat? _nearBias() {
    if (state.activeField == ActiveEndpointField.destination &&
        state.origin != null) {
      return state.origin!.location;
    }
    if (state.activeField == ActiveEndpointField.origin &&
        state.destination != null) {
      return state.destination!.location;
    }
    return null;
  }

  void selectPoi(Poi poi) {
    if (state.activeField == ActiveEndpointField.origin) {
      state = state.copyWith(
        origin: poi,
        activeField: state.destination == null
            ? ActiveEndpointField.destination
            : state.activeField,
        searchQuery: '',
        searchResults: const <Poi>[],
        phase: TripPlannerPhase.search,
        routes: const <RouteOption>[],
        clearSelectedRoute: true,
        clearError: true,
      );
      return;
    }

    state = state.copyWith(
      destination: poi,
      searchQuery: '',
      searchResults: const <Poi>[],
      phase: TripPlannerPhase.search,
      routes: const <RouteOption>[],
      clearSelectedRoute: true,
      clearError: true,
    );
  }

  void swapEndpoints() {
    final Poi? origin = state.origin;
    final Poi? destination = state.destination;
    state = state.copyWith(
      origin: destination,
      destination: origin,
      routes: const <RouteOption>[],
      clearSelectedRoute: true,
      phase: TripPlannerPhase.search,
      clearError: true,
    );
  }

  void backToSearch() {
    state = state.copyWith(
      phase: TripPlannerPhase.search,
      routes: const <RouteOption>[],
      clearSelectedRoute: true,
      clearError: true,
    );
  }

  Future<void> fetchRoutes() async {
    final Poi? origin = state.origin;
    final Poi? destination = state.destination;
    if (origin == null || destination == null) {
      state = state.copyWith(errorMessage: '请先选择起点和终点。');
      return;
    }

    state = state.copyWith(
      isLoadingRoutes: true,
      clearError: true,
      routes: const <RouteOption>[],
      clearSelectedRoute: true,
    );

    try {
      final RouteResponse response = await _client.getRoute(
        origin: origin.location,
        destination: destination.location,
        alternatives: true,
      );
      final List<RouteOption> routes = response.routes;
      if (routes.isEmpty) {
        state = state.copyWith(
          isLoadingRoutes: false,
          errorMessage: '未找到可用路线。',
        );
        return;
      }

      state = state.copyWith(
        isLoadingRoutes: false,
        phase: TripPlannerPhase.routes,
        routes: routes,
        selectedRouteId: routes.first.id,
      );
    } on MapApiException catch (error) {
      state = state.copyWith(
        isLoadingRoutes: false,
        errorMessage: error.message,
      );
    } catch (error) {
      state = state.copyWith(
        isLoadingRoutes: false,
        errorMessage: '路线规划失败：$error',
      );
    }
  }

  void selectRoute(String routeId) {
    state = state.copyWith(selectedRouteId: routeId, clearError: true);
  }
}
