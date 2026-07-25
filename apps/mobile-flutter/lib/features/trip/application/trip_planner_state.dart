import 'package:shared_types/shared_types.dart';

enum TripPlannerPhase { search, routes }

enum ActiveEndpointField { origin, destination }

class TripPlannerState {
  const TripPlannerState({
    this.phase = TripPlannerPhase.search,
    this.origin,
    this.destination,
    this.activeField = ActiveEndpointField.origin,
    this.searchQuery = '',
    this.searchResults = const <Poi>[],
    this.isSearching = false,
    this.routes = const <RouteOption>[],
    this.isLoadingRoutes = false,
    this.selectedRouteId,
    this.errorMessage,
  });

  final TripPlannerPhase phase;
  final Poi? origin;
  final Poi? destination;
  final ActiveEndpointField activeField;
  final String searchQuery;
  final List<Poi> searchResults;
  final bool isSearching;
  final List<RouteOption> routes;
  final bool isLoadingRoutes;
  final String? selectedRouteId;
  final String? errorMessage;

  bool get canPlanRoute => origin != null && destination != null;

  RouteOption? get selectedRoute {
    if (selectedRouteId == null) {
      return null;
    }
    for (final RouteOption route in routes) {
      if (route.id == selectedRouteId) {
        return route;
      }
    }
    return null;
  }

  TripPlannerState copyWith({
    TripPlannerPhase? phase,
    Poi? origin,
    bool clearOrigin = false,
    Poi? destination,
    bool clearDestination = false,
    ActiveEndpointField? activeField,
    String? searchQuery,
    List<Poi>? searchResults,
    bool? isSearching,
    List<RouteOption>? routes,
    bool? isLoadingRoutes,
    String? selectedRouteId,
    bool clearSelectedRoute = false,
    String? errorMessage,
    bool clearError = false,
  }) {
    return TripPlannerState(
      phase: phase ?? this.phase,
      origin: clearOrigin ? null : (origin ?? this.origin),
      destination: clearDestination ? null : (destination ?? this.destination),
      activeField: activeField ?? this.activeField,
      searchQuery: searchQuery ?? this.searchQuery,
      searchResults: searchResults ?? this.searchResults,
      isSearching: isSearching ?? this.isSearching,
      routes: routes ?? this.routes,
      isLoadingRoutes: isLoadingRoutes ?? this.isLoadingRoutes,
      selectedRouteId:
          clearSelectedRoute ? null : (selectedRouteId ?? this.selectedRouteId),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
