import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_types/shared_types.dart';

import '../../../../core/config/env.dart';
import '../../../../core/map_provider/map_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../application/trip_planner_notifier.dart';
import '../../application/trip_planner_state.dart';
import 'map_data_source_banner.dart';
import 'route_option_card.dart';

class RouteSelectionSection extends ConsumerWidget {
  const RouteSelectionSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TripPlannerState planner = ref.watch(tripPlannerProvider);
    final TripPlannerNotifier notifier = ref.read(tripPlannerProvider.notifier);
    final MapDataSource source = ref.watch(mapDataSourceProvider);

    if (planner.routes.isEmpty && !planner.isLoadingRoutes) {
      return const SizedBox.shrink();
    }

    final RouteOption? baseline =
        planner.routes.isNotEmpty ? planner.routes.first : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: notifier.backToSearch,
              tooltip: '返回修改起终点',
            ),
            const Expanded(
              child: Text(
                '选择路线',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.nightBackground,
                ),
              ),
            ),
            const MapDataSourceBanner(),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            mapDataSourceHint(source),
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        if (planner.origin != null && planner.destination != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              '${planner.origin!.name} → ${planner.destination!.name}',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        if (planner.isLoadingRoutes)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          )
        else
          ...planner.routes.map((RouteOption route) {
            return RouteOptionCard(
              route: route,
              selected: route.id == planner.selectedRouteId,
              baseline: baseline,
              onTap: () => notifier.selectRoute(route.id),
            );
          }),
      ],
    );
  }
}
