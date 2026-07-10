import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_types/shared_types.dart';

import '../../../../core/map_provider/map_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../application/trip_planner_notifier.dart';
import '../../application/trip_planner_state.dart';

class SearchSection extends ConsumerStatefulWidget {
  const SearchSection({super.key});

  @override
  ConsumerState<SearchSection> createState() => _SearchSectionState();
}

class _SearchSectionState extends ConsumerState<SearchSection> {
  late final TextEditingController _queryController;

  @override
  void initState() {
    super.initState();
    _queryController = TextEditingController();
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final TripPlannerState planner = ref.watch(tripPlannerProvider);
    final TripPlannerNotifier notifier = ref.read(tripPlannerProvider.notifier);
    final bool useMock = ref.watch(useMockMapApiProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            const Expanded(
              child: Text(
                '去哪？',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.nightBackground,
                ),
              ),
            ),
            if (useMock)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'mock 数据',
                  style: TextStyle(fontSize: 11, color: AppColors.warning),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        _EndpointField(
          label: '起点',
          value: planner.origin?.name,
          active: planner.activeField == ActiveEndpointField.origin,
          dotColor: AppColors.brand,
          onTap: () {
            notifier.setActiveField(ActiveEndpointField.origin);
            _queryController.clear();
            notifier.updateSearchQuery('');
          },
        ),
        const SizedBox(height: 8),
        _EndpointField(
          label: '终点',
          value: planner.destination?.name,
          active: planner.activeField == ActiveEndpointField.destination,
          dotColor: AppColors.success,
          onTap: () {
            notifier.setActiveField(ActiveEndpointField.destination);
            _queryController.clear();
            notifier.updateSearchQuery('');
          },
        ),
        if (planner.origin != null && planner.destination != null)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: notifier.swapEndpoints,
              icon: const Icon(Icons.swap_vert, size: 18),
              label: const Text('交换起终点'),
            ),
          ),
        const SizedBox(height: 8),
        TextField(
          controller: _queryController,
          decoration: InputDecoration(
            hintText: planner.activeField == ActiveEndpointField.origin
                ? '搜索起点，如：武汉站'
                : '搜索终点，如：汉口站',
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE4E7EC)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE4E7EC)),
            ),
          ),
          onChanged: notifier.updateSearchQuery,
        ),
        if (planner.isSearching)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: LinearProgressIndicator(minHeight: 2),
          ),
        if (planner.searchResults.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: planner.searchResults.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (BuildContext context, int index) {
                final Poi poi = planner.searchResults[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(poi.name),
                  subtitle: Text(
                    poi.category,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textTertiary,
                    ),
                  ),
                  onTap: () {
                    notifier.selectPoi(poi);
                    _queryController.clear();
                  },
                );
              },
            ),
          ),
        if (planner.errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              planner.errorMessage!,
              style: const TextStyle(color: AppColors.danger, fontSize: 13),
            ),
          ),
        const SizedBox(height: 12),
        if (planner.phase == TripPlannerPhase.search)
          FilledButton(
            onPressed: planner.canPlanRoute && !planner.isLoadingRoutes
                ? () => notifier.fetchRoutes()
                : null,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.brand,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: planner.isLoadingRoutes
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('查看路线'),
          ),
      ],
    );
  }
}

class _EndpointField extends StatelessWidget {
  const _EndpointField({
    required this.label,
    required this.value,
    required this.active,
    required this.dotColor,
    required this.onTap,
  });

  final String label;
  final String? value;
  final bool active;
  final Color dotColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active
          ? AppColors.brand.withValues(alpha: 0.06)
          : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: active ? AppColors.brand : const Color(0xFFE4E7EC),
              width: active ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textTertiary,
                      ),
                    ),
                    Text(
                      value ?? '点击搜索$label',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: value == null
                            ? AppColors.textTertiary
                            : AppColors.nightBackground,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
