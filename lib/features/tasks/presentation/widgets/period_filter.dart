import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dust_count/shared/models/filter_period.dart';
import 'package:dust_count/shared/models/household.dart';
import 'package:dust_count/shared/models/household_category.dart';
import 'package:dust_count/shared/widgets/filter_panel.dart';
import 'package:dust_count/features/tasks/domain/task_providers.dart';
import 'package:dust_count/core/extensions/date_extensions.dart';

/// Widget for filtering tasks by period, category, member, and task name.
///
/// Wraps [FilterPanel] and wires it to [taskFilterProvider].
class PeriodFilter extends ConsumerWidget {
  final List<HouseholdMember> members;
  final List<HouseholdCategory> customCategories;
  final List<PredefinedTask> predefinedTasks;
  final bool showTaskFilter;

  const PeriodFilter({
    required this.members,
    this.customCategories = const [],
    this.predefinedTasks = const [],
    this.showTaskFilter = false,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(taskFilterProvider);

    return FilterPanel(
      period: filter.period,
      startDate: filter.startDate,
      endDate: filter.endDate,
      categoryId: filter.categoryId,
      difficulty: filter.difficulty,
      taskNameFr: filter.taskNameFr,
      performedBy: filter.performedBy,
      personalFilterIndex: filter.personalFilter.index,
      customCategories: customCategories,
      predefinedTasks: predefinedTasks,
      members: members,
      showMemberFilter: true,
      showTaskFilter: showTaskFilter,
      showPersonalFilter: true,
      showDifficultyInAdvanced: true,
      showPersonalFilterInAdvanced: true,
      onPeriodChanged: (period) => _setPeriod(ref, period, context),
      onCustomDatePicker: () => _showCustomDatePicker(ref, context),
      onPersonalFilterChanged: (index) {
        final current = ref.read(taskFilterProvider);
        ref.read(taskFilterProvider.notifier).state = current.copyWith(
          personalFilter: PersonalFilter.values[index],
        );
      },
      onCategoryChanged: (categoryId) {
        final current = ref.read(taskFilterProvider);
        ref.read(taskFilterProvider.notifier).state = current.copyWith(
          categoryId: categoryId,
          clearCategory: categoryId == null,
          clearTaskNameFr: true,
        );
      },
      onDifficultyChanged: (difficulty) {
        final current = ref.read(taskFilterProvider);
        ref.read(taskFilterProvider.notifier).state = current.copyWith(
          difficulty: difficulty,
          clearDifficulty: difficulty == null,
        );
      },
      onTaskNameChanged: (taskNameFr) {
        final current = ref.read(taskFilterProvider);
        ref.read(taskFilterProvider.notifier).state = current.copyWith(
          taskNameFr: taskNameFr,
          clearTaskNameFr: taskNameFr == null,
        );
      },
      onMemberChanged: (userId) {
        final current = ref.read(taskFilterProvider);
        ref.read(taskFilterProvider.notifier).state = current.copyWith(
          performedBy: userId,
          clearPerformedBy: userId == null,
        );
      },
      onResetAdvanced: () {
        final current = ref.read(taskFilterProvider);
        ref.read(taskFilterProvider.notifier).state = current.copyWith(
          clearTaskNameFr: true,
          clearDifficulty: true,
          personalFilter: PersonalFilter.all,
        );
      },
      onAutoClearCategory: () {
        final current = ref.read(taskFilterProvider);
        ref.read(taskFilterProvider.notifier).state = current.copyWith(
          clearCategory: true,
          clearTaskNameFr: true,
        );
      },
    );
  }

  Future<void> _showCustomDatePicker(WidgetRef ref, BuildContext context) async {
    final now = DateTime.now();
    final dateRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange: DateTimeRange(
        start: now.startOfWeek,
        end: now,
      ),
    );

    if (dateRange != null) {
      ref.read(taskFilterProvider.notifier).state = ref
          .read(taskFilterProvider)
          .copyWith(
            startDate: dateRange.start.startOfDay,
            endDate: dateRange.end.endOfDay,
            period: FilterPeriod.custom,
          );
    }
  }

  void _setPeriod(WidgetRef ref, FilterPeriod period, BuildContext context) {
    final now = DateTime.now();
    DateTime? startDate;
    DateTime? endDate;

    switch (period) {
      case FilterPeriod.thisWeek:
        startDate = now.startOfWeek;
        endDate = now.endOfWeek;
        break;
      case FilterPeriod.thisMonth:
        startDate = now.startOfMonth;
        endDate = now.endOfMonth;
        break;
      case FilterPeriod.custom:
        _showCustomDatePicker(ref, context);
        return;
    }

    ref.read(taskFilterProvider.notifier).state = ref
        .read(taskFilterProvider)
        .copyWith(
          startDate: startDate,
          endDate: endDate,
          period: period,
        );
  }
}
