import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/env.dart';
import '../../../../core/map_provider/map_provider.dart';
import '../../../../core/theme/app_theme.dart';

/// 标注当前路线 geometry 来源：OSRM 道路路径 vs mock 示意折线。
class MapDataSourceBanner extends ConsumerWidget {
  const MapDataSourceBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final MapDataSource source = ref.watch(mapDataSourceProvider);

    if (source == MapDataSource.bff) {
      return _Chip(
        label: 'OSRM 道路路径',
        background: AppColors.success.withValues(alpha: 0.15),
        foreground: AppColors.success,
        icon: Icons.route,
      );
    }

    if (source == MapDataSource.mockFallback) {
      return _Chip(
        label: 'BFF 不可用 · 示意折线',
        background: AppColors.danger.withValues(alpha: 0.12),
        foreground: AppColors.danger,
        icon: Icons.warning_amber_rounded,
      );
    }

    return _Chip(
      label: '示意折线（mock）',
      background: AppColors.warning.withValues(alpha: 0.15),
      foreground: AppColors.warning,
      icon: Icons.info_outline,
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.background,
    required this.foreground,
    required this.icon,
  });

  final String label;
  final Color background;
  final Color foreground;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: foreground),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: foreground,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String mapDataSourceHint(MapDataSource source) {
  switch (source) {
    case MapDataSource.bff:
      return '地图折线为 OSRM 道路路径（道路距离）。';
    case MapDataSource.mockFallback:
      return 'BFF/OSRM 未连通，已显示 mock 示意折线（非道路路径）。请确认 map-bff 与 OSRM 5001 已启动。';
    case MapDataSource.mock:
      return 'mock 仅 5 个示意点，地图呈直线；距离数字为演示量级。接 BFF 后显示真实路网。';
  }
}