import 'package:flutter/material.dart';
import 'package:shared_types/shared_types.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/route_format.dart';

/// T09 选定路线后的占位页；完整导航态在 T12 实现。
class TripConfirmedPage extends StatelessWidget {
  const TripConfirmedPage({
    super.key,
    required this.originName,
    required this.destinationName,
    required this.route,
  });

  final String originName;
  final String destinationName;
  final RouteOption route;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dayBackground,
      appBar: AppBar(
        title: const Text('已选定路线'),
        backgroundColor: AppColors.dayBackground,
        foregroundColor: AppColors.nightBackground,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              '$originName → $destinationName',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.nightBackground,
              ),
            ),
            const SizedBox(height: 16),
            _InfoRow(
              label: '预计时间',
              value: formatDurationSec(route.durationSec),
            ),
            _InfoRow(
              label: '距离',
              value: formatDistanceM(route.distanceM),
            ),
            _InfoRow(
              label: '收费',
              value: formatTollEstimate(route.tollEstimateYuan),
            ),
            _InfoRow(label: '标签', value: route.tag),
            if (route.summary.isNotEmpty)
              _InfoRow(label: '特征', value: route.summary),
            const SizedBox(height: 24),
            const Text(
              '导航跟随、TTS 与驾驶态控件将在 T12 落地。',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const Spacer(),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brand,
                minimumSize: const Size.fromHeight(48),
              ),
              child: const Text('返回继续选路'),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textTertiary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.nightBackground,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
