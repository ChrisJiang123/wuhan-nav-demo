import 'dart:io';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:permission_handler/permission_handler.dart';

/// 导航态前台服务封装。
///
/// 职责：显示持续通知，降低导航中被系统杀掉的概率。
/// **不确定点（需真机验证）**：
/// - 息屏后 OEM 是否仍允许 location FGS；
/// - 部分机型需「忽略电池优化」才稳定；
/// - Android 14+ 必须在持有定位权限后才能 startForeground(location)。
class NavigationForegroundService {
  NavigationForegroundService._();

  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) {
      return;
    }
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'wuhan_nav_guidance',
        channelName: '导航进行中',
        channelDescription: '保持导航定位，避免被系统清理。',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(15000),
        autoRunOnBoot: false,
        autoRunOnMyPackageReplaced: false,
        allowWakeLock: true,
        allowWifiLock: false,
      ),
    );
    _initialized = true;
  }

  /// 请求通知权限（Android 13+）。定位权限由 geolocator 负责。
  static Future<String?> ensureNotificationPermission() async {
    if (!Platform.isAndroid) {
      return null;
    }
    final PermissionStatus status = await Permission.notification.status;
    if (status.isGranted || status.isLimited) {
      return null;
    }
    final PermissionStatus requested = await Permission.notification.request();
    if (requested.isGranted || requested.isLimited) {
      return null;
    }
    return '未授予通知权限：前台服务通知可能无法显示（导航仍可前台运行）。';
  }

  static Future<bool> start({
    required String destinationName,
  }) async {
    await init();
    final String? notice = await ensureNotificationPermission();
    // 通知权限缺失不阻断导航，但调用方应展示 notice。
    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.updateService(
        notificationTitle: '武汉导航进行中',
        notificationText: '前往 $destinationName · 请勿强制结束应用',
      );
      return true;
    }

    final ServiceRequestResult result =
        await FlutterForegroundTask.startService(
      serviceId: 1201,
      notificationTitle: '武汉导航进行中',
      notificationText: '前往 $destinationName · 请勿强制结束应用',
      callback: navigationStartCallback,
    );

    if (result is ServiceRequestFailure) {
      // 真机上可能因权限/OEM 限制失败；不抛死，由上层标注。
      return false;
    }
    // ignore: unused_local_variable
    final String? _ = notice;
    return true;
  }

  static Future<void> stop() async {
    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.stopService();
    }
  }
}

@pragma('vm:entry-point')
void navigationStartCallback() {
  FlutterForegroundTask.setTaskHandler(_NavigationTaskHandler());
}

/// 任务 handler：当前仅保活 + 刷新通知时间戳。
/// 定位主链路仍在 UI isolate（geolocator stream）。
/// 若息屏后 UI isolate 被挂起导致不更新，需在真机上验证并考虑把定位迁入此 handler。
class _NavigationTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {}

  @override
  void onRepeatEvent(DateTime timestamp) {
    // 轻量心跳，证明 FGS 仍在跑。
    FlutterForegroundTask.updateService(
      notificationTitle: '武汉导航进行中',
      notificationText: '定位保活中 · ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}',
    );
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}
}
