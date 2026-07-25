import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../navigation/application/navigation_state.dart';
import '../../../navigation/presentation/navigation_page.dart';
import '../../application/trip_planner_notifier.dart';
import '../../application/trip_planner_state.dart';
import 'route_selection_section.dart';
import 'search_section.dart';

class TripPlannerSheet extends ConsumerWidget {
  const TripPlannerSheet({super.key, required this.scrollController});

  final ScrollController scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TripPlannerState planner = ref.watch(tripPlannerProvider);

    return Material(
      elevation: 12,
      color: AppColors.dayBackground,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: Column(
        children: <Widget>[
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textTertiary.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              children: <Widget>[
                if (planner.phase == TripPlannerPhase.search)
                  const SearchSection()
                else
                  const RouteSelectionSection(),
              ],
            ),
          ),
          if (planner.phase == TripPlannerPhase.routes &&
              planner.selectedRouteId != null)
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: FilledButton(
                  onPressed: () {
                    final TripPlannerState current = ref.read(tripPlannerProvider);
                    final selected = current.selectedRoute;
                    if (selected == null ||
                        current.origin == null ||
                        current.destination == null) {
                      return;
                    }
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => NavigationPage(
                          session: NavigationSession(
                            originName: current.origin!.name,
                            destinationName: current.destination!.name,
                            route: selected,
                          ),
                        ),
                      ),
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.success,
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    '开始导航',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
