import 'package:flutter/material.dart';
import 'package:dust_count/shared/strings.dart';
import 'package:dust_count/shared/models/household.dart';
import 'package:dust_count/shared/models/household_category.dart';
import 'package:dust_count/shared/utils/category_helpers.dart';
import 'package:dust_count/core/constants/app_constants.dart';

/// Compact task selector field that opens a bottom sheet picker.
class PredefinedTaskSelector extends StatefulWidget {
  final List<PredefinedTask> tasks;
  final void Function(PredefinedTask? task) onTaskSelected;
  final PredefinedTask? initialTask;
  final List<String>? quickTaskIds;
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

  void _selectTask(PredefinedTask? task) {
    setState(() {
      _selectedTask = task;
    });
    widget.onTaskSelected(task);
  }

  Future<void> _showTaskPickerSheet(BuildContext context) async {
    final result = await showModalBottomSheet<PredefinedTask>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _TaskPickerSheet(
        tasks: widget.tasks,
        favoriteTasks: _favoriteTasks,
        selectedTask: _selectedTask,
        customCategories: widget.customCategories,
      ),
    );
    if (result != null) {
      _selectTask(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final emoji = _selectedTask != null
        ? getCategoryEmoji(_selectedTask!.categoryId, widget.customCategories)
        : null;

    return FormField<PredefinedTask>(
      initialValue: _selectedTask,
      validator: (value) {
        if (_selectedTask == null) return S.pleaseSelectTask;
        return null;
      },
      builder: (state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => _showTaskPickerSheet(context),
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: S.selectTask,
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  suffixIcon: const Icon(Icons.arrow_drop_down),
                  errorText: state.hasError ? state.errorText : null,
                ),
                child: _selectedTask != null
                    ? Row(
                        children: [
                          if (emoji != null) ...[
                            Text(emoji, style: const TextStyle(fontSize: 18)),
                            const SizedBox(width: 8),
                          ],
                          Expanded(
                            child: Text(
                              _selectedTask!.nameFr,
                              style: TextStyle(
                                fontSize: 16,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      )
                    : Text(
                        S.selectTask,
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Bottom sheet content for picking a predefined task.
class _TaskPickerSheet extends StatelessWidget {
  final List<PredefinedTask> tasks;
  final List<PredefinedTask> favoriteTasks;
  final PredefinedTask? selectedTask;
  final List<HouseholdCategory> customCategories;

  const _TaskPickerSheet({
    required this.tasks,
    required this.favoriteTasks,
    required this.selectedTask,
    required this.customCategories,
  });

  /// Categories that have at least one non-favorite task (excluding archivees).
  List<_CategorySection> _visibleCategories() {
    final favoriteIds = favoriteTasks.map((t) => t.id).toSet();
    final allCats = getAllCategories(customCategories);
    final sections = <_CategorySection>[];

    for (final cat in allCats) {
      final catTasks = tasks
          .where((t) =>
              t.categoryId == cat.id &&
              !favoriteIds.contains(t.id) &&
              t.categoryId != 'archivees')
          .toList();
      if (catTasks.isNotEmpty) {
        sections.add(_CategorySection(category: cat, tasks: catTasks));
      }
    }
    return sections;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final sections = _visibleCategories();

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Drag handle
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Center(
                child: Container(
                  width: 32,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.onSurfaceVariant.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  S.selectTask,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ),
            // Scrollable content
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  // Favorites section
                  if (favoriteTasks.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.favorite, size: 18, color: Colors.pinkAccent),
                          const SizedBox(width: 8),
                          Text(
                            S.favoriteTasks,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        for (final task in favoriteTasks)
                          ChoiceChip(
                            label: Text(task.nameFr),
                            selected: selectedTask?.id == task.id,
                            onSelected: (_) => Navigator.pop(context, task),
                          ),
                      ],
                    ),
                    const Divider(height: 24),
                  ],
                  // Category sections
                  for (final section in sections) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 4),
                      child: Row(
                        children: [
                          _buildCategoryLeading(section.category, colorScheme),
                          const SizedBox(width: 8),
                          Text(
                            getCategoryLabel(section.category.id, customCategories),
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                    for (final task in section.tasks)
                      ListTile(
                        title: Text(task.nameFr),
                        trailing: selectedTask?.id == task.id
                            ? Icon(Icons.check, color: colorScheme.primary)
                            : null,
                        onTap: () => Navigator.pop(context, task),
                        dense: true,
                        contentPadding: const EdgeInsets.only(left: 8),
                      ),
                  ],
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCategoryLeading(HouseholdCategory category, ColorScheme colorScheme) {
    if (category.hasEmoji) {
      return Text(category.emoji!, style: const TextStyle(fontSize: 18));
    }
    return Icon(
      category.icon,
      size: 18,
      color: colorScheme.onSurfaceVariant,
    );
  }
}

class _CategorySection {
  final HouseholdCategory category;
  final List<PredefinedTask> tasks;

  const _CategorySection({required this.category, required this.tasks});
}
