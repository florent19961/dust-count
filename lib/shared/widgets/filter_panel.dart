import 'package:flutter/material.dart';
import 'package:dust_count/shared/strings.dart';
import 'package:dust_count/shared/models/filter_period.dart';
import 'package:dust_count/shared/models/household.dart';
import 'package:dust_count/shared/models/household_category.dart';
import 'package:dust_count/shared/widgets/category_chip.dart';
import 'package:dust_count/shared/utils/category_helpers.dart';
import 'package:dust_count/app/theme/app_colors.dart';
import 'package:dust_count/core/constants/app_constants.dart';

/// Shared filter panel used by both the task history and dashboard screens.
///
/// Displays period chips, category chips, difficulty chips, optional member
/// chips, and an optional advanced task-name filter. Communicates state
/// changes via callbacks so it stays provider-agnostic.
class FilterPanel extends StatefulWidget {
  // --- current filter state ---
  final FilterPeriod period;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? categoryId;
  final TaskDifficulty? difficulty;
  final String? taskNameFr;
  final String? performedBy;

  // --- data ---
  final List<HouseholdCategory> customCategories;
  final List<PredefinedTask> predefinedTasks;
  final List<HouseholdMember> members;

  // --- personal filter ---
  /// Current personal filter index: 0 = all, 1 = household, 2 = personal
  final int personalFilterIndex;

  // --- feature flags ---
  final bool showMemberFilter;
  final bool showTaskFilter;
  final bool showPersonalFilter;
  final bool showDifficultyInAdvanced;
  final bool showPersonalFilterInAdvanced;

  // --- callbacks ---
  final ValueChanged<FilterPeriod> onPeriodChanged;
  final VoidCallback onCustomDatePicker;
  final ValueChanged<String?> onCategoryChanged;
  final ValueChanged<TaskDifficulty?> onDifficultyChanged;
  final ValueChanged<String?> onTaskNameChanged;
  final ValueChanged<String?>? onMemberChanged;
  final ValueChanged<int>? onPersonalFilterChanged;
  final VoidCallback onResetAdvanced;

  /// Called when the category filter should be auto-cleared (obsolete selection).
  final VoidCallback? onAutoClearCategory;

  const FilterPanel({
    super.key,
    required this.period,
    this.startDate,
    this.endDate,
    this.categoryId,
    this.difficulty,
    this.taskNameFr,
    this.performedBy,
    this.personalFilterIndex = 0,
    required this.customCategories,
    required this.predefinedTasks,
    this.members = const [],
    this.showMemberFilter = false,
    this.showTaskFilter = false,
    this.showPersonalFilter = false,
    this.showDifficultyInAdvanced = false,
    this.showPersonalFilterInAdvanced = false,
    required this.onPeriodChanged,
    required this.onCustomDatePicker,
    required this.onCategoryChanged,
    required this.onDifficultyChanged,
    required this.onTaskNameChanged,
    this.onMemberChanged,
    this.onPersonalFilterChanged,
    required this.onResetAdvanced,
    this.onAutoClearCategory,
  });

  @override
  State<FilterPanel> createState() => _FilterPanelState();
}

class _FilterPanelState extends State<FilterPanel> {
  bool _showAdvancedFilters = false;

  bool get _hasAdvancedSection =>
      widget.showTaskFilter ||
      widget.showDifficultyInAdvanced ||
      widget.showPersonalFilterInAdvanced;

  bool get _hasActiveAdvancedFilter {
    if (widget.taskNameFr != null) return true;
    if (widget.showDifficultyInAdvanced && widget.difficulty != null) return true;
    if (widget.showPersonalFilterInAdvanced && widget.personalFilterIndex != 0) {
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final categories = getFilterCategories(
      widget.customCategories,
      widget.predefinedTasks,
    );

    // Auto-clear obsolete category filter
    if (widget.categoryId != null &&
        !categories.any((c) => c.id == widget.categoryId)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onAutoClearCategory?.call();
      });
    }

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
            _buildPeriodChips(theme),
            const SizedBox(height: 12),
            // Category filter
            _buildSectionLabel(S.filterByCategory, theme),
            const SizedBox(height: 8),
            _buildCategoryChips(categories),
            // Difficulty filter (quick access only if not in advanced)
            if (!widget.showDifficultyInAdvanced) ...[
              const SizedBox(height: 12),
              _buildSectionLabel(S.filterByDifficulty, theme),
              const SizedBox(height: 8),
              _buildDifficultyChips(theme),
            ],
            // Member filter (optional)
            if (widget.showMemberFilter && widget.members.length > 1) ...[
              const SizedBox(height: 12),
              _buildSectionLabel(S.filterByMember, theme),
              const SizedBox(height: 8),
              _buildMemberChips(),
            ],
            // Personal/household scope filter (quick access only if not in advanced)
            if (widget.showPersonalFilter &&
                !widget.showPersonalFilterInAdvanced) ...[
              const SizedBox(height: 12),
              _buildPersonalFilterChips(theme),
            ],
            // Advanced filters section
            if (_hasAdvancedSection) ...[
              const SizedBox(height: 12),
              _buildAdvancedToggle(theme, _hasActiveAdvancedFilter),
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: _buildAdvancedContent(theme),
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

  Widget _buildSectionLabel(String text, ThemeData theme) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: theme.colorScheme.onSurface,
      ),
    );
  }

  Widget _buildPeriodChips(ThemeData theme) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ChoiceChip(
          label: Text(S.filterThisWeek),
          selected: widget.period == FilterPeriod.thisWeek,
          onSelected: (_) => widget.onPeriodChanged(FilterPeriod.thisWeek),
          selectedColor: theme.colorScheme.primaryContainer,
        ),
        ChoiceChip(
          label: Text(S.filterThisMonth),
          selected: widget.period == FilterPeriod.thisMonth,
          onSelected: (_) => widget.onPeriodChanged(FilterPeriod.thisMonth),
          selectedColor: theme.colorScheme.primaryContainer,
        ),
        ChoiceChip(
          label: widget.period == FilterPeriod.custom &&
                  widget.startDate != null &&
                  widget.endDate != null
              ? Text(
                  '${S.formatDateShort(widget.startDate!)} - ${S.formatDateShort(widget.endDate!)}',
                  overflow: TextOverflow.ellipsis,
                )
              : Text(S.filterCustom),
          selected: widget.period == FilterPeriod.custom,
          onSelected: (_) => widget.onCustomDatePicker(),
          selectedColor: theme.colorScheme.primaryContainer,
        ),
      ],
    );
  }

  Widget _buildCategoryChips(List<HouseholdCategory> categories) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: categories.map((category) {
        final isSelected = widget.categoryId == category.id;
        return CategoryChip(
          category: category,
          selected: isSelected,
          onTap: () =>
              widget.onCategoryChanged(isSelected ? null : category.id),
        );
      }).toList(),
    );
  }

  Widget _buildDifficultyChips(ThemeData theme) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: TaskDifficulty.values.map((d) {
        return _buildDifficultyChip(
          AppConstants.difficultyEmojis[d]!,
          d,
          AppColors.getDifficultyColor(d),
        );
      }).toList(),
    );
  }

  Widget _buildDifficultyChip(
    String emoji,
    TaskDifficulty difficulty,
    Color color,
  ) {
    final isSelected = widget.difficulty == difficulty;
    return ChoiceChip(
      label: Text(emoji, style: TextStyle(fontSize: 20)),
      selected: isSelected,
      selectedColor: color.withOpacity(0.3),
      onSelected: (_) =>
          widget.onDifficultyChanged(isSelected ? null : difficulty),
    );
  }

  Widget _buildMemberChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: widget.members.map((member) {
        final isSelected = widget.performedBy == member.userId;
        final memberColor = AppColors.getMemberColor(member.colorIndex);
        return ChoiceChip(
          label: Text(member.displayName),
          selected: isSelected,
          selectedColor: memberColor.withOpacity(0.3),
          onSelected: (_) =>
              widget.onMemberChanged?.call(isSelected ? null : member.userId),
          avatar: CircleAvatar(
            backgroundColor: memberColor,
            radius: 10,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPersonalFilterChips(ThemeData theme) {
    final labels = [S.filterAll, S.filterHousehold, S.filterPersonal];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(labels.length, (index) {
        return ChoiceChip(
          label: Text(labels[index]),
          selected: widget.personalFilterIndex == index,
          selectedColor: theme.colorScheme.primaryContainer,
          onSelected: (_) => widget.onPersonalFilterChanged?.call(index),
        );
      }),
    );
  }

  Widget _buildAdvancedToggle(ThemeData theme, bool hasActive) {
    return InkWell(
      onTap: () => setState(() {
        _showAdvancedFilters = !_showAdvancedFilters;
      }),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          children: [
            Icon(Icons.tune, size: 20, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              S.advancedFilters,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            if (hasActive) ...[
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
            if (hasActive)
              TextButton.icon(
                onPressed: widget.onResetAdvanced,
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
    );
  }

  Widget _buildAdvancedContent(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Task filter
          if (widget.showTaskFilter && widget.predefinedTasks.isNotEmpty)
            _buildTaskFilterContent(theme),
          // Difficulty in advanced
          if (widget.showDifficultyInAdvanced) ...[
            const SizedBox(height: 12),
            _buildSectionLabel(S.filterByDifficulty, theme),
            const SizedBox(height: 8),
            _buildDifficultyChips(theme),
          ],
          // Personal filter in advanced
          if (widget.showPersonalFilterInAdvanced &&
              widget.showPersonalFilter) ...[
            const SizedBox(height: 12),
            _buildPersonalFilterChips(theme),
          ],
        ],
      ),
    );
  }

  Widget _buildTaskFilterContent(ThemeData theme) {
    final availableTasks = widget.categoryId != null
        ? widget.predefinedTasks
            .where((t) => t.categoryId == widget.categoryId)
            .toList()
        : widget.predefinedTasks
            .where((t) => t.categoryId != AppConstants.archivedCategoryId)
            .toList();

    if (availableTasks.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionLabel(S.filterByTask, theme),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: availableTasks.map((task) {
              final isSelected = widget.taskNameFr == task.nameFr;
              return ChoiceChip(
                label: Text(
                  task.nameFr.length > 30
                      ? '${task.nameFr.substring(0, 27)}...'
                      : task.nameFr,
                ),
                selected: isSelected,
                onSelected: (_) => widget
                    .onTaskNameChanged(isSelected ? null : task.nameFr),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
