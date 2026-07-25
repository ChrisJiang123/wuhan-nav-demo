import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/route_format.dart';
import '../../application/navigation_notifier.dart';
import '../../application/navigation_state.dart';
import '../../application/route_progress.dart';

class NavigationTopBanner extends ConsumerWidget {
  const NavigationTopBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final NavigationState nav = ref.watch(navigationProvider);
    final RouteProgress? progress = nav.progress;
    final String nextAction =
        progress?.nextActionText ?? '正在获取位置…';
    final String eta = progress == null
        ? '--'
        : formatDurationSec(progress.remainingDurationSec);
    final String remain = progress == null
        ? '--'
        : formatDistanceM(progress.remainingDistanceM.round());

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
        child: Material(
          elevation: 3,
          borderRadius: BorderRadius.circular(14),
          color: AppColors.nightBackground,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  nextAction,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: <Widget>[
                    _Metric(label: '剩余', value: remain),
                    const SizedBox(width: 16),
                    _Metric(label: '预计', value: eta),
                    const Spacer(),
                    if (nav.foregroundServiceRunning)
                      const Icon(
                        Icons.shield_outlined,
                        size: 16,
                        color: AppColors.success,
                      ),
                  ],
                ),
                if (nav.permissionMessage != null) ...<Widget>[
                  const SizedBox(height: 8),
                  Text(
                    nav.permissionMessage!,
                    style: const TextStyle(
                      color: AppColors.warning,
                      fontSize: 11,
                    ),
                  ),
                ],
                if (nav.errorMessage != null) ...<Widget>[
                  const SizedBox(height: 6),
                  Text(
                    nav.errorMessage!,
                    style: const TextStyle(
                      color: AppColors.danger,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Text(
          label,
          style: const TextStyle(color: AppColors.textTertiary, fontSize: 12),
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// 驾驶态一级控件 ≤ 5：上报 / 总览 / 结束 / 回中 / 静音。
class NavigationBottomBar extends ConsumerWidget {
  const NavigationBottomBar({
    super.key,
    required this.onOverview,
    required this.onEnd,
  });

  final VoidCallback onOverview;
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final NavigationState nav = ref.watch(navigationProvider);
    final NavigationNotifier notifier = ref.read(navigationProvider.notifier);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (kDebugMode) _DebugLocationModeRow(nav: nav, notifier: notifier),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: <Widget>[
                    _NavAction(
                      icon: Icons.report_outlined,
                      label: '上报',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('上报功能将在 T15 落地'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                    _NavAction(
                      icon: Icons.fit_screen,
                      label: '总览',
                      onTap: onOverview,
                    ),
                    _NavAction(
                      icon: Icons.close,
                      label: '结束',
                      color: AppColors.danger,
                      onTap: onEnd,
                    ),
                    _NavAction(
                      icon: Icons.my_location,
                      label: '回中',
                      highlighted: nav.isFollowing,
                      onTap: notifier.recenter,
                    ),
                    _NavAction(
                      icon: nav.isMuted ? Icons.volume_off : Icons.volume_up,
                      label: nav.isMuted ? '已静音' : '静音',
                      highlighted: nav.isMuted,
                      onTap: notifier.toggleMute,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                TextButton.icon(
                  onPressed: notifier.togglePerspective,
                  icon: Icon(
                    nav.perspective == CameraPerspective.headingUp
                        ? Icons.navigation
                        : Icons.explore,
                    size: 16,
                  ),
                  label: Text(
                    nav.perspective == CameraPerspective.headingUp
                        ? '视角：车头朝上'
                        : '视角：北向上',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DebugLocationModeRow extends StatelessWidget {
  const _DebugLocationModeRow({
    required this.nav,
    required this.notifier,
  });

  final NavigationState nav;
  final NavigationNotifier notifier;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: <Widget>[
          const Text(
            '定位源',
            style: TextStyle(fontSize: 11, color: AppColors.textTertiary),
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text('模拟沿路线', style: TextStyle(fontSize: 11)),
            selected: nav.locationMode == LocationMode.simulateAlongRoute,
            onSelected: (_) =>
                notifier.setLocationMode(LocationMode.simulateAlongRoute),
          ),
          const SizedBox(width: 6),
          ChoiceChip(
            label: const Text('真实 GPS', style: TextStyle(fontSize: 11)),
            selected: nav.locationMode == LocationMode.gps,
            onSelected: (_) => notifier.setLocationMode(LocationMode.gps),
          ),
        ],
      ),
    );
  }
}

class _NavAction extends StatelessWidget {
  const _NavAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.highlighted = false,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool highlighted;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final Color tint = color ??
        (highlighted ? AppColors.brand : AppColors.nightBackground);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, color: tint, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: tint),
            ),
          ],
        ),
      ),
    );
  }
}
