import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dust_count/shared/models/filter_period.dart';
import 'package:dust_count/core/constants/app_constants.dart';
import 'package:dust_count/core/utils/firestore_retry.dart';
import 'package:dust_count/features/dashboard/data/dashboard_repository.dart';
import 'package:dust_count/features/household/domain/household_providers.dart';

/// Dashboard filter configuration
class DashboardFilter {
  final FilterPeriod period;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? categoryId;
  final String? taskNameFr;
  final TaskDifficulty? difficulty;

  const DashboardFilter({
    required this.period,
    this.startDate,
    this.endDate,
    this.categoryId,
    this.taskNameFr,
    this.difficulty,
  });

  /// Get the effective start date based on period
  DateTime get effectiveStartDate {
    switch (period) {
      case FilterPeriod.thisWeek:
        final now = DateTime.now();
        final weekday = now.weekday;
        return DateTime(now.year, now.month, now.day)
            .subtract(Duration(days: weekday - 1));
      case FilterPeriod.thisMonth:
        final now = DateTime.now();
        return DateTime(now.year, now.month, 1);
      case FilterPeriod.custom:
        return startDate ?? _defaultStartDate;
    }
  }

  /// Get the effective end date based on period
  DateTime get effectiveEndDate {
    switch (period) {
      case FilterPeriod.thisWeek:
        return DateTime.now();
      case FilterPeriod.thisMonth:
        return DateTime.now();
      case FilterPeriod.custom:
        return endDate ?? DateTime.now();
    }
  }

  /// Default start date (30 days ago)
  static DateTime get _defaultStartDate =>
      DateTime.now().subtract(const Duration(days: 30));

  DashboardFilter copyWith({
    FilterPeriod? period,
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
    String? taskNameFr,
    TaskDifficulty? difficulty,
    bool clearCategory = false,
    bool clearTaskNameFr = false,
    bool clearDifficulty = false,
  }) {
    return DashboardFilter(
      period: period ?? this.period,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      taskNameFr: clearTaskNameFr ? null : (taskNameFr ?? this.taskNameFr),
      difficulty: clearDifficulty ? null : (difficulty ?? this.difficulty),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is DashboardFilter &&
        other.period == period &&
        other.startDate == startDate &&
        other.endDate == endDate &&
        other.categoryId == categoryId &&
        other.taskNameFr == taskNameFr &&
        other.difficulty == difficulty;
  }

  @override
  int get hashCode =>
      Object.hash(period, startDate, endDate, categoryId, taskNameFr, difficulty);
}

/// Provider for dashboard repository
final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository();
});

/// Provider for dashboard filter state
final dashboardFilterProvider =
    StateProvider<DashboardFilter>((ref) {
  return const DashboardFilter(period: FilterPeriod.thisWeek);
});

/// Provider for total minutes per member
final minutesPerMemberProvider =
    FutureProvider<Map<String, int>>((ref) async {
  final householdId = ref.watch(currentHouseholdIdProvider);
  if (householdId == null) {
    return {};
  }

  final filter = ref.watch(dashboardFilterProvider);
  final repository = ref.watch(dashboardRepositoryProvider);

  return retryOnPermissionDenied(() => repository.getMinutesPerMember(
    householdId,
    filter.effectiveStartDate,
    filter.effectiveEndDate,
    categoryId: filter.categoryId,
    taskNameFr: filter.taskNameFr,
    difficulty: filter.difficulty,
  ));
});

/// Provider for daily cumulative minutes per member
final dailyCumulativeProvider =
    FutureProvider<Map<String, Map<String, int>>>((ref) async {
  final householdId = ref.watch(currentHouseholdIdProvider);
  if (householdId == null) {
    return {};
  }

  final filter = ref.watch(dashboardFilterProvider);
  final repository = ref.watch(dashboardRepositoryProvider);

  return retryOnPermissionDenied(() => repository.getDailyMinutesPerMember(
    householdId,
    filter.effectiveStartDate,
    filter.effectiveEndDate,
    categoryId: filter.categoryId,
    taskNameFr: filter.taskNameFr,
    difficulty: filter.difficulty,
  ));
});

/// Provider for category breakdown
final categoryBreakdownProvider =
    FutureProvider<List<CategoryBreakdownEntry>>((ref) async {
  final householdId = ref.watch(currentHouseholdIdProvider);
  if (householdId == null) {
    return [];
  }

  final filter = ref.watch(dashboardFilterProvider);
  final repository = ref.watch(dashboardRepositoryProvider);

  return retryOnPermissionDenied(() => repository.getCategoryBreakdown(
    householdId,
    filter.effectiveStartDate,
    filter.effectiveEndDate,
    categoryId: filter.categoryId,
    taskNameFr: filter.taskNameFr,
    difficulty: filter.difficulty,
  ));
});

/// Provider for leaderboard entries
final leaderboardProvider =
    FutureProvider<List<LeaderboardEntry>>((ref) async {
  final householdId = ref.watch(currentHouseholdIdProvider);
  if (householdId == null) {
    return [];
  }

  final filter = ref.watch(dashboardFilterProvider);
  final repository = ref.watch(dashboardRepositoryProvider);

  return retryOnPermissionDenied(() => repository.getLeaderboard(
    householdId,
    filter.effectiveStartDate,
    filter.effectiveEndDate,
    categoryId: filter.categoryId,
    taskNameFr: filter.taskNameFr,
    difficulty: filter.difficulty,
  ));
});
