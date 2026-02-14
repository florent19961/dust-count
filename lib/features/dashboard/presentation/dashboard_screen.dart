import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dust_count/shared/strings.dart';
import 'package:dust_count/shared/models/household.dart';
import 'package:dust_count/shared/models/filter_period.dart';
import 'package:dust_count/shared/widgets/filter_panel.dart';
import 'package:dust_count/core/extensions/date_extensions.dart';
import 'package:dust_count/features/dashboard/domain/dashboard_providers.dart';
import 'package:dust_count/features/dashboard/presentation/widgets/time_distribution_chart.dart';
import 'package:dust_count/features/dashboard/presentation/widgets/category_breakdown_chart.dart';
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
              title: S.categoryBreakdown,
              icon: Icons.bar_chart,
              child: ref.watch(categoryBreakdownProvider).when(
                data: (entries) => CategoryBreakdownChart(
                  entries: entries,
                  customCategories: widget.household.customCategories,
                ),
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
                data: (entries) => LeaderboardWidget(
                  entries: entries,
                  members: widget.household.members,
                ),
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

  /// Build the unified filters card using the shared [FilterPanel].
  Widget _buildFiltersCard() {
    final filter = ref.watch(dashboardFilterProvider);

    return FilterPanel(
      period: filter.period,
      startDate: filter.startDate,
      endDate: filter.endDate,
      categoryId: filter.categoryId,
      difficulty: filter.difficulty,
      taskNameFr: filter.taskNameFr,
      customCategories: widget.household.customCategories,
      predefinedTasks: widget.household.predefinedTasks,
      showTaskFilter: widget.household.predefinedTasks.isNotEmpty,
      onPeriodChanged: (period) {
        if (period == FilterPeriod.custom) {
          _showCustomDateRangePicker();
          return;
        }
        ref.read(dashboardFilterProvider.notifier).state =
            filter.copyWith(period: period);
      },
      onCustomDatePicker: _showCustomDateRangePicker,
      onCategoryChanged: (categoryId) {
        ref.read(dashboardFilterProvider.notifier).state = filter.copyWith(
          categoryId: categoryId,
          clearCategory: categoryId == null,
          clearTaskNameFr: true,
        );
      },
      onDifficultyChanged: (difficulty) {
        ref.read(dashboardFilterProvider.notifier).state = filter.copyWith(
          difficulty: difficulty,
          clearDifficulty: difficulty == null,
        );
      },
      onTaskNameChanged: (taskNameFr) {
        ref.read(dashboardFilterProvider.notifier).state = filter.copyWith(
          taskNameFr: taskNameFr,
          clearTaskNameFr: taskNameFr == null,
        );
      },
      onResetAdvanced: () {
        ref.read(dashboardFilterProvider.notifier).state = filter.copyWith(
          clearTaskNameFr: true,
          clearDifficulty: true,
        );
      },
      onAutoClearCategory: () {
        ref.read(dashboardFilterProvider.notifier).state = filter.copyWith(
          clearCategory: true,
          clearTaskNameFr: true,
        );
      },
    );
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
