import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dust_count/shared/strings.dart';
import 'package:dust_count/shared/models/household.dart';
import 'package:dust_count/shared/models/filter_period.dart';
import 'package:dust_count/shared/widgets/category_chip.dart';
import 'package:dust_count/shared/utils/category_helpers.dart';
import 'package:dust_count/core/extensions/date_extensions.dart';
import 'package:dust_count/features/dashboard/domain/dashboard_providers.dart';
import 'package:dust_count/features/dashboard/presentation/widgets/time_distribution_chart.dart';
import 'package:dust_count/features/dashboard/presentation/widgets/cumulative_evolution_chart.dart';
import 'package:dust_count/features/dashboard/presentation/widgets/leaderboard_widget.dart';

/// Main dashboard screen showing charts and leaderboard
class DashboardScreen extends ConsumerStatefulWidget {
  /// Household for member name resolution
  final Household household;

  /// When true, renders without Scaffold (for embedding in tabs)
  final bool embedded;

  const DashboardScreen({
    required this.household,
    this.embedded = false,
    super.key,
  });

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _showAdvancedFilters = false;

  @override
  Widget build(BuildContext context) {
    Widget buildScrollView() {
      return CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _buildFiltersCard(),
          ),
          SliverToBoxAdapter(
            child: _buildChartSection(
              title: S.timeDistribution,
              icon: Icons.pie_chart,
              child: ref.watch(minutesPerMemberProvider).when(
                data: (minutesPerMember) {
                  final memberNames = _getMemberNames();
                  return TimeDistributionChart(
                    minutesPerMember: minutesPerMember,
                    memberNames: memberNames,
                  );
                },
                loading: () => _buildLoadingState(),
                error: (error, stack) => _buildErrorState(
                  error.toString(),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _buildChartSection(
              title: S.cumulativeEvolution,
              icon: Icons.show_chart,
              child: ref.watch(dailyCumulativeProvider).when(
                data: (dailyData) {
                  final filter = ref.watch(dashboardFilterProvider);
                  final memberNames = _getMemberNames();
                  return CumulativeEvolutionChart(
                    dailyCumulativeData: dailyData,
                    memberNames: memberNames,
                    startDate: filter.effectiveStartDate,
                    endDate: filter.effectiveEndDate,
                  );
                },
                loading: () => _buildLoadingState(),
                error: (error, stack) => _buildErrorState(
                  error.toString(),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _buildChartSection(
              title: S.leaderboard,
              icon: Icons.leaderboard,
              child: ref.watch(leaderboardProvider).when(
                data: (entries) => LeaderboardWidget(entries: entries),
                loading: () => _buildLoadingState(),
                error: (error, stack) => _buildErrorState(
                  error.toString(),
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: 24),
          ),
        ],
      );
    }

    if (widget.embedded) {
      return buildScrollView();
    }

    return Scaffold(body: buildScrollView());
  }

  /// Show date range picker for custom period
  Future<void> _showCustomDateRangePicker() async {
    final filter = ref.read(dashboardFilterProvider);
    final now = DateTime.now();
    final dateRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange: DateTimeRange(
        start: filter.startDate ?? now.startOfWeek,
        end: filter.endDate ?? now,
      ),
    );

    if (dateRange != null) {
      ref.read(dashboardFilterProvider.notifier).state = filter.copyWith(
        startDate: dateRange.start.startOfDay,
        endDate: dateRange.end.endOfDay,
        period: FilterPeriod.custom,
      );
    }
  }

  /// Update filter for predefined period
  void _setPeriod(FilterPeriod period) {
    final filter = ref.read(dashboardFilterProvider);
    if (period == FilterPeriod.custom) {
      _showCustomDateRangePicker();
      return;
    }
    ref.read(dashboardFilterProvider.notifier).state =
        filter.copyWith(period: period);
  }

  /// Build the unified filters card
  Widget _buildFiltersCard() {
    final theme = Theme.of(context);
    final filter = ref.watch(dashboardFilterProvider);
    final hasActiveAdvancedFilter = filter.taskNameFr != null;

    final categories = getAllCategories(widget.household.customCategories);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Period chips (same style as Historique)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: Text(S.filterThisWeek),
                selected: filter.period == FilterPeriod.thisWeek,
                onSelected: (_) => _setPeriod(FilterPeriod.thisWeek),
                selectedColor: theme.colorScheme.primaryContainer,
              ),
              ChoiceChip(
                label: Text(S.filterThisMonth),
                selected: filter.period == FilterPeriod.thisMonth,
                onSelected: (_) => _setPeriod(FilterPeriod.thisMonth),
                selectedColor: theme.colorScheme.primaryContainer,
              ),
              ChoiceChip(
                label: filter.period == FilterPeriod.custom &&
                        filter.startDate != null &&
                        filter.endDate != null
                    ? Text(
                        '${S.formatDateShort(filter.startDate!)} - ${S.formatDateShort(filter.endDate!)}',
                        overflow: TextOverflow.ellipsis,
                      )
                    : Text(S.filterCustom),
                selected: filter.period == FilterPeriod.custom,
                onSelected: (_) => _showCustomDateRangePicker(),
                selectedColor: theme.colorScheme.primaryContainer,
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Category filter (always visible)
          Text(
            S.filterByCategory,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: categories.map((category) {
              final isSelected = filter.categoryId == category.id;
              return CategoryChip(
                category: category,
                selected: isSelected,
                onTap: () {
                  if (isSelected) {
                    ref.read(dashboardFilterProvider.notifier).state =
                        filter.copyWith(
                      clearCategory: true,
                      clearTaskNameFr: true,
                    );
                  } else {
                    ref.read(dashboardFilterProvider.notifier).state =
                        filter.copyWith(
                      categoryId: category.id,
                      clearTaskNameFr: true,
                    );
                  }
                },
              );
            }).toList(),
          ),
          if (widget.household.predefinedTasks.isNotEmpty) ...[
            const SizedBox(height: 12),
            // Advanced filters toggle
            InkWell(
              onTap: () {
                setState(() {
                  _showAdvancedFilters = !_showAdvancedFilters;
                });
              },
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    Icon(
                      Icons.tune,
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      S.advancedFilters,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    if (hasActiveAdvancedFilter) ...[
                      const SizedBox(width: 8),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                    const Spacer(),
                    if (hasActiveAdvancedFilter)
                      TextButton.icon(
                        onPressed: () {
                          ref.read(dashboardFilterProvider.notifier).state =
                              filter.copyWith(clearTaskNameFr: true);
                        },
                        icon: const Icon(Icons.clear, size: 18),
                        label: Text(S.resetFilters),
                      ),
                    AnimatedRotation(
                      turns: _showAdvancedFilters ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: const Icon(Icons.expand_more),
                    ),
                  ],
                ),
              ),
            ),
            // Collapsible task filter content
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: _buildTaskFilterContent(filter),
              crossFadeState: _showAdvancedFilters
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 200),
            ),
          ],
        ],
      ),
    );
  }

  /// Build the task filter chips (advanced section)
  Widget _buildTaskFilterContent(DashboardFilter filter) {
    final theme = Theme.of(context);

    final availableTasks = filter.categoryId != null
        ? widget.household.predefinedTasks
            .where((t) => t.categoryId == filter.categoryId)
            .toList()
        : widget.household.predefinedTasks
            .where((t) => t.categoryId != 'archivees')
            .toList();

    if (availableTasks.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            S.filterByTask,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: availableTasks.map((task) {
              final isSelected = filter.taskNameFr == task.nameFr;
              return ChoiceChip(
                label: Text(
                  task.nameFr.length > 30
                      ? '${task.nameFr.substring(0, 27)}...'
                      : task.nameFr,
                ),
                selected: isSelected,
                onSelected: (_) {
                  if (isSelected) {
                    ref.read(dashboardFilterProvider.notifier).state =
                        filter.copyWith(clearTaskNameFr: true);
                  } else {
                    ref.read(dashboardFilterProvider.notifier).state =
                        filter.copyWith(taskNameFr: task.nameFr);
                  }
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// Build chart section with title and card
  Widget _buildChartSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              child,
            ],
          ),
        ),
      ),
    );
  }

  /// Build loading state
  Widget _buildLoadingState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32.0),
        child: CircularProgressIndicator(),
      ),
    );
  }

  /// Build error state
  Widget _buildErrorState(String error) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              S.errorLoadingDashboard,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Build member name map from household members
  Map<String, String> _getMemberNames() {
    return {
      for (final member in widget.household.members)
        member.userId: member.displayName,
    };
  }
}
