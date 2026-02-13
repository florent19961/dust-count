import 'package:flutter/material.dart';
import 'package:dust_count/shared/strings.dart';
import 'package:dust_count/shared/models/household.dart';
import 'package:dust_count/shared/models/household_category.dart';
import 'package:dust_count/shared/utils/category_helpers.dart';
import 'package:dust_count/core/constants/app_constants.dart';

/// Widget for selecting a predefined task via a single grouped dropdown.
///
/// Shows "Tâches favorites" at the top, then tasks grouped by category.
class PredefinedTaskSelector extends StatefulWidget {
  /// List of predefined tasks from household
  final List<PredefinedTask> tasks;

  /// Callback when a task is selected or deselected (null = deselection)
  final void Function(PredefinedTask? task) onTaskSelected;

  /// Optional initial selection (for edit mode)
  final PredefinedTask? initialTask;

  /// Optional custom quick task IDs (from member preferences)
  final List<String>? quickTaskIds;

  /// Custom categories for resolving category labels
  final List<HouseholdCategory> customCategories;

  const PredefinedTaskSelector({
    required this.tasks,
    required this.onTaskSelected,
    this.initialTask,
    this.quickTaskIds,
    this.customCategories = const [],
    super.key,
  });

  @override
  State<PredefinedTaskSelector> createState() => _PredefinedTaskSelectorState();
}

class _PredefinedTaskSelectorState extends State<PredefinedTaskSelector> {
  late PredefinedTask? _selectedTask = widget.initialTask;

  /// Quick/favorite tasks resolved from quickTaskIds or fallback
  List<PredefinedTask> get _favoriteTasks {
    if (widget.quickTaskIds != null && widget.quickTaskIds!.isNotEmpty) {
      final taskMap = {for (final t in widget.tasks) t.id: t};
      return widget.quickTaskIds!
          .where((id) => taskMap.containsKey(id))
          .map((id) => taskMap[id]!)
          .toList();
    }
    final quickNames = AppConstants.predefinedTasks
        .take(AppConstants.quickTaskCount)
        .map((t) => t['nameFr'] as String)
        .toSet();
    return widget.tasks
        .where((t) => quickNames.contains(t.nameFr))
        .toList();
  }

  /// Group non-favorite, non-archived tasks by category
  Map<String, List<PredefinedTask>> _groupByCategory(
    List<PredefinedTask> tasks,
  ) {
    final grouped = <String, List<PredefinedTask>>{};
    for (final task in tasks) {
      grouped.putIfAbsent(task.categoryId, () => []).add(task);
    }
    return grouped;
  }

  void _selectTask(PredefinedTask? task) {
    setState(() {
      _selectedTask = task;
    });
    widget.onTaskSelected(task);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final favorites = _favoriteTasks;
    final favoriteIds = favorites.map((t) => t.id).toSet();

    // Remaining tasks: exclude favorites and archived
    final remainingTasks = widget.tasks
        .where((t) => !favoriteIds.contains(t.id) && t.categoryId != 'archivees')
        .toList();
    final grouped = _groupByCategory(remainingTasks);

    return DropdownButtonFormField<PredefinedTask>(
      value: _selectedTask,
      decoration: InputDecoration(
        labelText: S.selectTask,
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.task),
      ),
      isExpanded: true,
      items: _buildDropdownItems(favorites, grouped, colorScheme),
      onChanged: (task) {
        _selectTask(task);
      },
      validator: (value) {
        if (value == null) {
          return S.pleaseSelectTask;
        }
        return null;
      },
    );
  }

  /// Build dropdown items: favorites section then category groups
  List<DropdownMenuItem<PredefinedTask>> _buildDropdownItems(
    List<PredefinedTask> favorites,
    Map<String, List<PredefinedTask>> grouped,
    ColorScheme colorScheme,
  ) {
    final items = <DropdownMenuItem<PredefinedTask>>[];

    // Favorites section
    if (favorites.isNotEmpty) {
      items.add(
        DropdownMenuItem<PredefinedTask>(
          enabled: false,
          child: Row(
            children: [
              Icon(
                Icons.star,
                size: 16,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                S.favoriteTasks,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
      for (final task in favorites) {
        items.add(
          DropdownMenuItem<PredefinedTask>(
            value: task,
            child: Padding(
              padding: const EdgeInsets.only(left: 24),
              child: Text(task.nameFr),
            ),
          ),
        );
      }
    }

    // Category groups
    for (final entry in grouped.entries) {
      final categoryEmoji = getCategoryEmoji(entry.key, widget.customCategories);
      items.add(
        DropdownMenuItem<PredefinedTask>(
          enabled: false,
          child: Row(
            children: [
              if (categoryEmoji != null)
                Text(categoryEmoji, style: const TextStyle(fontSize: 16))
              else
                Icon(
                  getCategoryIcon(entry.key, widget.customCategories),
                  size: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
              const SizedBox(width: 8),
              Text(
                getCategoryLabel(entry.key, widget.customCategories),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );

      for (final task in entry.value) {
        items.add(
          DropdownMenuItem<PredefinedTask>(
            value: task,
            child: Padding(
              padding: const EdgeInsets.only(left: 24),
              child: Text(task.nameFr),
            ),
          ),
        );
      }
    }

    return items;
  }
}
