import 'package:flutter/material.dart';
import 'package:shared_types/shared_types.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/route_format.dart';

class RouteOptionCard extends StatelessWidget {
  const RouteOptionCard({
    super.key,
    required this.route,
    required this.selected,
    required this.onTap,
    this.baseline,
  });

  final RouteOption route;
  final bool selected;
  final VoidCallback onTap;
  final RouteOption? baseline;

  @override
  Widget build(BuildContext context) {
    final bool isRecommended = baseline == null || route.id == baseline!.id;
    final String? deltaText = baseline != null && !isRecommended
        ? formatRouteDelta(
            baseDurationSec: baseline!.durationSec,
            baseDistanceM: baseline!.distanceM,
            durationSec: route.durationSec,
            distanceM: route.distanceM,
          )
        : null;

    return AnimatedContainer(
      duration: AppMotion.short,
      curve: Curves.easeOut,
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: selected
            ? AppColors.brand.withValues(alpha: 0.08)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected ? AppColors.brand : const Color(0xFFE4E7EC),
          width: selected ? 2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    _TagChip(label: route.tag),
                    const Spacer(),
                    Text(
                      formatDurationSec(route.durationSec),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.nightBackground,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: <Widget>[
                    Text(
                      formatDistanceM(route.distanceM),
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const Text(
                      ' · ',
                      style: TextStyle(color: AppColors.textTertiary),
                    ),
                    Text(
                      formatTollEstimate(route.tollEstimateYuan),
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                if (route.summary.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 8),
                  Text(
                    route.summary,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                if (deltaText != null) ...<Widget>[
                  const SizedBox(height: 6),
                  Text(
                    deltaText,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textTertiary,
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

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.brand.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.brand,
        ),
      ),
    );
  }
}
