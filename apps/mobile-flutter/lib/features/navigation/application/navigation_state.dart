import 'package:shared_types/shared_types.dart';

import 'route_progress.dart';

enum CameraPerspective {
  /// 北向上。
  northUp,

  /// 车头朝上（跟随方位角）。
  headingUp,
}

enum LocationMode {
  /// 真实 GPS / 系统模拟位置。
  gps,

  /// Debug：沿选定路线插值移动，便于模拟器验收跟随。
  simulateAlongRoute,
}

class NavigationSession {
  const NavigationSession({
    required this.originName,
    required this.destinationName,
    required this.route,
  });

  final String originName;
  final String destinationName;
  final RouteOption route;
}

class NavigationState {
  const NavigationState({
    this.session,
    this.isActive = false,
    this.isFollowing = true,
    this.isMuted = false,
    this.perspective = CameraPerspective.headingUp,
    this.locationMode = LocationMode.gps,
    this.currentPosition,
    this.progress,
    this.permissionMessage,
    this.foregroundServiceRunning = false,
    this.errorMessage,
  });

  final NavigationSession? session;
  final bool isActive;
  final bool isFollowing;
  final bool isMuted;
  final CameraPerspective perspective;
  final LocationMode locationMode;
  final Wgs84LngLat? currentPosition;
  final RouteProgress? progress;
  final String? permissionMessage;
  final bool foregroundServiceRunning;
  final String? errorMessage;

  NavigationState copyWith({
    NavigationSession? session,
    bool clearSession = false,
    bool? isActive,
    bool? isFollowing,
    bool? isMuted,
    CameraPerspective? perspective,
    LocationMode? locationMode,
    Wgs84LngLat? currentPosition,
    bool clearPosition = false,
    RouteProgress? progress,
    bool clearProgress = false,
    String? permissionMessage,
    bool clearPermissionMessage = false,
    bool? foregroundServiceRunning,
    String? errorMessage,
    bool clearError = false,
  }) {
    return NavigationState(
      session: clearSession ? null : (session ?? this.session),
      isActive: isActive ?? this.isActive,
      isFollowing: isFollowing ?? this.isFollowing,
      isMuted: isMuted ?? this.isMuted,
      perspective: perspective ?? this.perspective,
      locationMode: locationMode ?? this.locationMode,
      currentPosition:
          clearPosition ? null : (currentPosition ?? this.currentPosition),
      progress: clearProgress ? null : (progress ?? this.progress),
      permissionMessage: clearPermissionMessage
          ? null
          : (permissionMessage ?? this.permissionMessage),
      foregroundServiceRunning:
          foregroundServiceRunning ?? this.foregroundServiceRunning,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
