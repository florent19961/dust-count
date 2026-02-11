import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dust_count/shared/strings.dart';
import 'package:dust_count/shared/models/filter_period.dart';
import 'package:dust_count/shared/models/household.dart';
import 'package:dust_count/features/tasks/domain/task_providers.dart';
import 'package:dust_count/core/extensions/date_extensions.dart';
import 'package:dust_count/shared/widgets/category_chip.dart';
import 'package:dust_count/shared/utils/category_helpers.dart';
import 'package:dust_count/shared/models/household_category.dart';
import 'package:dust_count/app/theme/app_colors.dart';

/// Widget for filtering tasks by period, category, member, and task name
class PeriodFilter extends ConsumerStatefulWidget {
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
  ConsumerState<PeriodFilter> createState() => _PeriodFilterState();
}

class _PeriodFilterState extends ConsumerState<PeriodFilter> {
  bool _showAdvancedFilters = false;

  /// Show date range picker for custom period
  Future<void> _showCustomDatePicker() async {
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

  /// Update filter for predefined period
  void _setPeriod(FilterPeriod period) {
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
        _showCustomDatePicker();
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

  /// Toggle category filter
  void _toggleCategory(String categoryId) {
    final currentFilter = ref.read(taskFilterProvider);
    final newCategoryId =
        currentFilter.categoryId == categoryId ? null : categoryId;

    ref.read(taskFilterProvider.notifier).state = currentFilter.copyWith(
      categoryId: newCategoryId,
      clearCategory: newCategoryId == null,
      clearTaskNameFr: true,
    );
  }

  /// Toggle member filter
  void _toggleMember(String userId) {
    final currentFilter = ref.read(taskFilterProvider);
    final newPerformedBy =
        currentFilter.performedBy == userId ? null : userId;

    ref.read(taskFilterProvider.notifier).state = currentFilter.copyWith(
      performedBy: newPerformedBy,
      clearPerformedBy: newPerformedBy == null,
    );
  }

  /// Toggle task name filter
  void _toggleTaskName(String taskNameFr) {
    final currentFilter = ref.read(taskFilterProvider);
    final newTaskNameFr =
        currentFilter.taskNameFr == taskNameFr ? null : taskNameFr;

    ref.read(taskFilterProvider.notifier).state = currentFilter.copyWith(
      taskNameFr: newTaskNameFr,
      clearTaskNameFr: newTaskNameFr == null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(taskFilterProvider);
    final theme = Theme.of(context);
    final hasActiveAdvancedFilter = filter.taskNameFr != null;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant,
            width: 1,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // Period chips
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
                onSelected: (_) => _showCustomDatePicker(),
                selectedColor: theme.colorScheme.primaryContainer,
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Category filter
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
            children: getAllCategoriesWithArchivees(widget.customCategories)
                .map((category) {
              return CategoryChip(
                category: category,
                selected: filter.categoryId == category.id,
                onTap: () => _toggleCategory(category.id),
              );
            }).toList(),
          ),
          if (widget.members.length > 1) ...[
            const SizedBox(height: 12),
            Text(
              S.filterByMember,
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
              children: widget.members.map((member) {
                final isSelected = filter.performedBy == member.userId;
                final memberColor =
                    AppColors.getMemberColor(member.colorIndex);
                return ChoiceChip(
                  label: Text(member.displayName),
                  selected: isSelected,
                  selectedColor: memberColor.withOpacity(0.3),
                  onSelected: (_) => _toggleMember(member.userId),
                  avatar: CircleAvatar(
                    backgroundColor: memberColor,
                    radius: 10,
                  ),
                );
              }).toList(),
            ),
          ],
          if (widget.showTaskFilter && widget.predefinedTasks.isNotEmpty) ...[
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
                          ref.read(taskFilterProvider.notifier).state =
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
      ),
    );
  }

  /// Build the task filter chips
  Widget _buildTaskFilterContent(TaskFilter filter) {
    final theme = Theme.of(context);

    final availableTasks = filter.categoryId != null
        ? widget.predefinedTasks
            .where((t) => t.categoryId == filter.categoryId)
            .toList()
        : widget.predefinedTasks
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
                onSelected: (_) => _toggleTaskName(task.nameFr),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
