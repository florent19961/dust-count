import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dust_count/shared/strings.dart';
import 'package:dust_count/shared/models/household.dart';
import 'package:dust_count/shared/models/household_category.dart';
import 'package:dust_count/shared/utils/category_helpers.dart';
import 'package:dust_count/core/constants/app_constants.dart';
import 'package:dust_count/shared/widgets/difficulty_badge.dart';
import 'package:dust_count/features/household/domain/household_providers.dart';
import 'package:dust_count/features/household/presentation/widgets/add_predefined_task_sheet.dart';
import 'package:dust_count/features/household/presentation/widgets/edit_predefined_task_sheet.dart';
import 'package:dust_count/features/household/presentation/widgets/add_category_sheet.dart';
import 'package:dust_count/features/tasks/data/task_repository.dart';

/// Unified screen for managing predefined tasks and quick task selection
class ManagePredefinedTasksScreen extends ConsumerStatefulWidget {
  final String householdId;

  const ManagePredefinedTasksScreen({
    super.key,
    required this.householdId,
  });

  @override
  ConsumerState<ManagePredefinedTasksScreen> createState() =>
      _ManagePredefinedTasksScreenState();
}

class _ManagePredefinedTasksScreenState
    extends ConsumerState<ManagePredefinedTasksScreen> {
  List<String> _quickTaskIds = [];
  bool _initialized = false;
  bool _dirty = false;
  bool _isDragging = false;
  final Set<String> _expandedTaskIds = {};

  @override
  Widget build(BuildContext context) {
    final householdAsync = ref.watch(currentHouseholdProvider);
    final prefsAsync = ref.watch(memberPreferencesProvider(widget.householdId));

    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _saveAndPop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(S.managePredefinedTasks),
        ),
        body: Column(
          children: [
            Material(
              color: Theme.of(context).colorScheme.surface,
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.add),
                      label: Text(S.addTask),
                      onPressed: () => _showAddTaskSheet(context),
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.add),
                      label: Text(S.addCategory),
                      onPressed: () => _showAddCategorySheet(context),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: Stack(
                children: [
                  householdAsync.when(
          data: (household) {
            if (household == null) {
              return Center(child: Text(S.householdNotFound));
            }

            // Initialize quick task IDs once — wait for prefs stream
            if (!_initialized) {
              if (prefsAsync.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              final prefs = prefsAsync.value;
              if (prefs != null && prefs.quickTaskIds.isNotEmpty) {
                final validIds =
                    household.predefinedTasks.map((t) => t.id).toSet();
                _quickTaskIds = prefs.quickTaskIds
                    .where((id) => validIds.contains(id))
                    .toList();
              } else {
                final quickNames = AppConstants.predefinedTasks
                    .take(AppConstants.quickTaskCount)
                    .map((t) => t.nameFr)
                    .toSet();
                _quickTaskIds = household.predefinedTasks
                    .where((t) => quickNames.contains(t.nameFr))
                    .take(8)
                    .map((t) => t.id)
                    .toList();
              }
              _initialized = true;
            }

            final tasks = household.predefinedTasks;
            if (tasks.isEmpty) {
              return Center(child: Text(S.noPredefinedTasks));
            }

            final grouped = _groupByCategory(tasks);
            final customCats = household.customCategories;
            // Include ALL categories even when empty
            for (final cat in builtInCategories) {
              grouped.putIfAbsent(cat.id, () => []);
            }
            for (final cat in customCats) {
              grouped.putIfAbsent(cat.id, () => []);
            }
            final categories = grouped.keys.toList()
              ..sort((a, b) {
                if (a == AppConstants.archivedCategoryId) return 1;
                if (b == AppConstants.archivedCategoryId) return -1;
                // Built-in categories first, then custom
                final aBuiltIn = builtInCategories.any((c) => c.id == a);
                final bBuiltIn = builtInCategories.any((c) => c.id == b);
                if (aBuiltIn && !bBuiltIn) return -1;
                if (!aBuiltIn && bBuiltIn) return 1;
                if (aBuiltIn && bBuiltIn) {
                  final aIdx =
                      builtInCategories.indexWhere((c) => c.id == a);
                  final bIdx =
                      builtInCategories.indexWhere((c) => c.id == b);
                  return aIdx.compareTo(bIdx);
                }
                return a.compareTo(b);
              });

            return SingleChildScrollView(
              padding: EdgeInsets.only(bottom: _isDragging ? 88 : 16),
              child: Column(
                children: categories.map((categoryId) {
                  final categoryTasks = grouped[categoryId]!;
                  final isArchived = categoryId == AppConstants.archivedCategoryId;
                  return _buildCategorySection(
                    context,
                    household,
                    categoryId,
                    categoryTasks,
                    isArchived,
                    customCats,
                  );
                }).toList(),
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Text('${S.error}: $error'),
          ),
        ),
                  if (_isDragging) _buildTrashZone(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrashZone() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: DragTarget<PredefinedTask>(
        onWillAcceptWithDetails: (_) => true,
        onAcceptWithDetails: (details) => _confirmDeleteTaskViaDrag(details.data),
        builder: (context, candidateData, rejectedData) {
          final isHovered = candidateData.isNotEmpty;
          final theme = Theme.of(context);
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 72,
            decoration: BoxDecoration(
              color: isHovered
                  ? theme.colorScheme.error
                  : theme.colorScheme.errorContainer,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isHovered ? Icons.delete_forever : Icons.delete_outline,
                  color: isHovered
                      ? theme.colorScheme.onError
                      : theme.colorScheme.onErrorContainer,
                ),
                const SizedBox(width: 8),
                Text(
                  S.dropToDelete,
                  style: TextStyle(
                    color: isHovered
                        ? theme.colorScheme.onError
                        : theme.colorScheme.onErrorContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmDeleteTaskViaDrag(PredefinedTask task) async {
    final taskRepo = ref.read(taskRepositoryProvider);
    final count = await taskRepo.countTaskLogsByName(
      widget.householdId,
      task.nameFr,
    );

    if (!mounted) return;

    final message = count > 0
        ? S.deleteTaskWarningMessage(task.nameFr, count)
        : S.deleteTaskNoLogsMessage(task.nameFr);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(S.deleteTaskWarningTitle),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(S.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: Text(S.delete),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref
          .read(householdControllerProvider.notifier)
          .deletePredefinedTask(widget.householdId, task);
      setState(() {
        _quickTaskIds.remove(task.id);
        _expandedTaskIds.remove(task.id);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.taskRemovedFromPredefined)),
        );
      }
    }
  }

  Map<String, List<PredefinedTask>> _groupByCategory(
    List<PredefinedTask> tasks,
  ) {
    final grouped = <String, List<PredefinedTask>>{};
    for (final task in tasks) {
      grouped.putIfAbsent(task.categoryId, () => []).add(task);
    }
    return grouped;
  }

  Widget _buildCategorySection(
    BuildContext context,
    Household household,
    String categoryId,
    List<PredefinedTask> tasks,
    bool isArchived,
    List<HouseholdCategory> customCategories,
  ) {
    final theme = Theme.of(context);
    final color = getCategoryColor(categoryId, customCategories);
    final isCustom = !builtInCategories.any((c) => c.id == categoryId) &&
        categoryId != AppConstants.archivedCategoryId;
    final isEmpty = tasks.isEmpty;
    final emoji = getCategoryEmoji(categoryId, customCategories);
    final label = getCategoryLabel(categoryId, customCategories);

    final expansionTile = ExpansionTile(
      leading: emoji != null
          ? Text(emoji, style: const TextStyle(fontSize: 20))
          : Icon(
              getCategoryIcon(categoryId, customCategories),
              color: color,
              size: 20,
            ),
      title: Text(
        '$label (${S.taskCount(tasks.length)})',
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: isCustom && isEmpty
          ? IconButton(
              icon: Icon(Icons.delete_outline,
                  size: 20, color: theme.colorScheme.error),
              tooltip: S.delete,
              onPressed: () => _confirmDeleteCategory(categoryId),
            )
          : null,
      children: [
        ...tasks.map((task) => _buildTaskTile(
              context,
              household,
              task,
              isArchived,
              customCategories,
            )),
        if (isEmpty)
          ListTile(
            leading: Icon(Icons.add_circle_outline, color: color),
            title: Text(
              S.addTaskToCategory,
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
            onTap: () => _showAddTaskSheet(context,
                initialCategoryId: categoryId, lockCategory: true),
          ),
      ],
    );

    if (isArchived) return expansionTile;

    return DragTarget<PredefinedTask>(
      onWillAcceptWithDetails: (details) {
        return details.data.categoryId != categoryId;
      },
      onAcceptWithDetails: (details) {
        _onTaskDroppedOnCategory(
          household,
          details.data,
          categoryId,
        );
      },
      builder: (context, candidateData, rejectedData) {
        final isHighlighted = candidateData.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isHighlighted
                ? color.withOpacity(0.25)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: isHighlighted
                ? Border.all(color: color, width: 2)
                : null,
          ),
          child: expansionTile,
        );
      },
    );
  }

  Future<void> _confirmDeleteCategory(String categoryId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(S.deleteCategoryTitle),
        content: Text(S.deleteCategoryMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(S.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: Text(S.delete),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref
          .read(householdControllerProvider.notifier)
          .deleteCustomCategory(widget.householdId, categoryId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.categoryDeleted)),
        );
      }
    }
  }

  Widget _buildTaskTile(
    BuildContext context,
    Household household,
    PredefinedTask task,
    bool isArchived,
    List<HouseholdCategory> customCategories,
  ) {
    final theme = Theme.of(context);
    final isQuick = _quickTaskIds.contains(task.id);

    final isExpanded = _expandedTaskIds.contains(task.id);

    final tile = ListTile(
      leading: isArchived
          ? null
          : Icon(
              Icons.drag_handle,
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
              size: 20,
            ),
      title: Text(
        task.nameFr,
        style: TextStyle(
          color: isArchived
              ? theme.colorScheme.onSurfaceVariant.withOpacity(0.5)
              : null,
        ),
      ),
      subtitle: isExpanded
          ? Row(
              children: [
                Text(
                  '${task.defaultDurationMinutes} min',
                  style: TextStyle(
                    color: isArchived
                        ? theme.colorScheme.onSurfaceVariant.withOpacity(0.4)
                        : null,
                  ),
                ),
                const SizedBox(width: 8),
                DifficultyBadge(difficulty: task.defaultDifficulty, compact: true),
              ],
            )
          : null,
      onTap: () => setState(() {
        if (_expandedTaskIds.contains(task.id)) {
          _expandedTaskIds.remove(task.id);
        } else {
          _expandedTaskIds.add(task.id);
        }
      }),
      trailing: isArchived
          ? null
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    isQuick ? Icons.favorite : Icons.favorite_border,
                    color: isQuick
                        ? Colors.pinkAccent
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  tooltip: S.quickTask,
                  onPressed: () => _toggleQuickTask(task.id),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: S.editPredefinedTask,
                  onPressed: () =>
                      _showEditTaskSheet(context, household, task),
                ),
              ],
            ),
    );

    // Wrap non-archived tiles in LongPressDraggable
    if (isArchived) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: tile,
      );
    }

    final categoryColor = getCategoryColor(task.categoryId, customCategories);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: LongPressDraggable<PredefinedTask>(
        data: task,
        delay: const Duration(milliseconds: 200),
        onDragStarted: () => setState(() => _isDragging = true),
        onDragEnd: (_) => setState(() => _isDragging = false),
        onDraggableCanceled: (_, __) => setState(() => _isDragging = false),
        feedback: Material(
          elevation: 6,
          borderRadius: BorderRadius.circular(12),
          color: theme.colorScheme.surfaceContainerHighest,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: categoryColor, width: 2),
            ),
            child: tile,
          ),
        ),
        childWhenDragging: Opacity(
          opacity: 0.3,
          child: tile,
        ),
        child: tile,
      ),
    );
  }

  void _onTaskDroppedOnCategory(
    Household household,
    PredefinedTask task,
    String newCategoryId,
  ) {
    final updatedTask = PredefinedTask(
      id: task.id,
      nameFr: task.nameFr,
      nameEn: task.nameEn,
      categoryId: newCategoryId,
      defaultDurationMinutes: task.defaultDurationMinutes,
      defaultDifficulty: task.defaultDifficulty,
    );

    ref
        .read(householdControllerProvider.notifier)
        .editPredefinedTask(widget.householdId, task, updatedTask);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(S.categoryChanged)),
    );
  }

  void _toggleQuickTask(String taskId) {
    setState(() {
      if (_quickTaskIds.contains(taskId)) {
        _quickTaskIds.remove(taskId);
        _dirty = true;
      } else {
        if (_quickTaskIds.length >= AppConstants.maxQuickTasks) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(S.maxQuickTasksReached)),
          );
          return;
        }
        _quickTaskIds.add(taskId);
        _dirty = true;
      }
    });
  }

  Future<void> _saveAndPop() async {
    await ref
        .read(householdControllerProvider.notifier)
        .updateQuickTaskIds(widget.householdId, _quickTaskIds);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _showAddTaskSheet(
    BuildContext context, {
    String? initialCategoryId,
    bool lockCategory = false,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => AddPredefinedTaskSheet(
        householdId: widget.householdId,
        initialCategoryId: initialCategoryId,
        categoryLocked: lockCategory,
      ),
    );
  }

  void _showEditTaskSheet(
    BuildContext context,
    Household household,
    PredefinedTask task,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => EditPredefinedTaskSheet(
        householdId: widget.householdId,
        household: household,
        task: task,
      ),
    );
  }

  void _showAddCategorySheet(BuildContext context) {
    final household = ref.read(currentHouseholdProvider).value;
    final totalCategories =
        builtInCategories.length + (household?.customCategories.length ?? 0);
    if (totalCategories >= 9) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.maxCategoriesReached)),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => AddCategorySheet(
        onCategoryCreated: (category) async {
          await ref
              .read(householdControllerProvider.notifier)
              .addCustomCategory(widget.householdId, category);
          if (sheetContext.mounted) {
            ScaffoldMessenger.of(sheetContext).showSnackBar(
              SnackBar(content: Text(S.categoryAdded)),
            );
          }
        },
      ),
    );
  }
}
