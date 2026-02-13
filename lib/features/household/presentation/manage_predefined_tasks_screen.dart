import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:dust_count/shared/strings.dart';
import 'package:dust_count/shared/models/household.dart';
import 'package:dust_count/shared/models/household_category.dart';
import 'package:dust_count/shared/utils/category_helpers.dart';
import 'package:dust_count/core/constants/app_constants.dart';
import 'package:dust_count/shared/widgets/difficulty_badge.dart';
import 'package:dust_count/features/household/domain/household_providers.dart';
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
  static const int _maxQuickTasks = 12;
  List<String> _quickTaskIds = [];
  bool _initialized = false;
  bool _dirty = false;

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
          actions: [
            TextButton.icon(
              icon: const Icon(Icons.add),
              label: Text(S.addCategory),
              onPressed: () => _showAddCategorySheet(context),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showAddTaskSheet(context),
          child: const Icon(Icons.add),
        ),
        body: householdAsync.when(
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
                    .map((t) => t['nameFr'] as String)
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
                if (a == 'archivees') return 1;
                if (b == 'archivees') return -1;
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
              padding: const EdgeInsets.only(bottom: 88),
              child: Column(
                children: categories.map((categoryId) {
                  final categoryTasks = grouped[categoryId]!;
                  final isArchived = categoryId == 'archivees';
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
      ),
    );
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
        categoryId != 'archivees';
    final isEmpty = tasks.isEmpty;

    final emoji = getCategoryEmoji(categoryId, customCategories);
    final header = Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          if (emoji != null)
            Text(emoji, style: const TextStyle(fontSize: 18))
          else
            Icon(getCategoryIcon(categoryId, customCategories),
                size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              getCategoryLabel(categoryId, customCategories),
              style: theme.textTheme.titleSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (isCustom && isEmpty)
            IconButton(
              icon: Icon(Icons.delete_outline, size: 20, color: theme.colorScheme.error),
              tooltip: S.delete,
              onPressed: () => _confirmDeleteCategory(categoryId),
            ),
        ],
      ),
    );

    // Wrap entire category section in DragTarget for drag & drop
    final sectionContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        header,
        if (isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: ListTile(
              leading: Icon(Icons.add_circle_outline, color: color),
              title: Text(
                S.addTaskToCategory,
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              ),
              onTap: () => _showAddTaskSheet(context, initialCategoryId: categoryId),
            ),
          )
        else
          ...tasks.map((task) => _buildTaskTile(
                context,
                household,
                task,
                isArchived,
                customCategories,
              )),
      ],
    );

    if (isArchived) return sectionContent;

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
          child: sectionContent,
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
      subtitle: Row(
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
      ),
      trailing: isArchived
          ? null
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    isQuick ? Icons.flash_on : Icons.flash_off,
                    color: isQuick
                        ? Colors.amber
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
        if (_quickTaskIds.length >= _maxQuickTasks) {
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

  void _showAddTaskSheet(BuildContext context, {String? initialCategoryId}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _AddPredefinedTaskSheet(
        householdId: widget.householdId,
        ref: ref,
        initialCategoryId: initialCategoryId,
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
      builder: (context) => _EditPredefinedTaskSheet(
        householdId: widget.householdId,
        household: household,
        task: task,
        ref: ref,
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
      builder: (context) => _AddCategorySheet(
        householdId: widget.householdId,
        ref: ref,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Add sheet
// ---------------------------------------------------------------------------

class _AddPredefinedTaskSheet extends StatefulWidget {
  final String householdId;
  final WidgetRef ref;
  final String? initialCategoryId;

  const _AddPredefinedTaskSheet({
    required this.householdId,
    required this.ref,
    this.initialCategoryId,
  });

  @override
  State<_AddPredefinedTaskSheet> createState() =>
      _AddPredefinedTaskSheetState();
}

class _AddPredefinedTaskSheetState extends State<_AddPredefinedTaskSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  late String _categoryId = widget.initialCategoryId ?? 'menage';
  int _durationMinutes = 15;
  TaskDifficulty _difficulty = TaskDifficulty.reloo;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();

    final task = PredefinedTask(
      id: const Uuid().v4(),
      nameFr: name,
      nameEn: name,
      categoryId: _categoryId,
      defaultDurationMinutes: _durationMinutes,
      defaultDifficulty: _difficulty,
    );

    await widget.ref
        .read(householdControllerProvider.notifier)
        .addPredefinedTask(widget.householdId, task);

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.taskAddedToPredefined)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final householdAsync = widget.ref.watch(currentHouseholdProvider);
    final customCategories =
        householdAsync.value?.customCategories ?? const [];

    return _TaskFormSheet(
      title: S.addPredefinedTask,
      nameController: _nameController,
      categoryId: _categoryId,
      durationMinutes: _durationMinutes,
      difficulty: _difficulty,
      formKey: _formKey,
      customCategories: customCategories,
      onCategoryChanged: (v) => setState(() => _categoryId = v),
      onDurationChanged: (v) => setState(() => _durationMinutes = v),
      onDifficultyChanged: (v) => setState(() => _difficulty = v),
      submitLabel: S.addPredefinedTask,
      onSubmit: _submit,
    );
  }
}

// ---------------------------------------------------------------------------
// Edit sheet
// ---------------------------------------------------------------------------

class _EditPredefinedTaskSheet extends StatefulWidget {
  final String householdId;
  final Household household;
  final PredefinedTask task;
  final WidgetRef ref;

  const _EditPredefinedTaskSheet({
    required this.householdId,
    required this.household,
    required this.task,
    required this.ref,
  });

  @override
  State<_EditPredefinedTaskSheet> createState() =>
      _EditPredefinedTaskSheetState();
}

class _EditPredefinedTaskSheetState extends State<_EditPredefinedTaskSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late String _categoryId;
  late int _durationMinutes;
  late TaskDifficulty _difficulty;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.task.nameFr);
    _categoryId = widget.task.categoryId;
    _durationMinutes = widget.task.defaultDurationMinutes;
    _difficulty = widget.task.defaultDifficulty;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();

    final updatedTask = PredefinedTask(
      id: widget.task.id,
      nameFr: name,
      nameEn: name,
      categoryId: _categoryId,
      defaultDurationMinutes: _durationMinutes,
      defaultDifficulty: _difficulty,
    );

    await widget.ref
        .read(householdControllerProvider.notifier)
        .editPredefinedTask(widget.householdId, widget.task, updatedTask);

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.taskUpdatedInPredefined)),
      );
    }
  }

  Future<void> _delete() async {
    final taskRepo = widget.ref.read(taskRepositoryProvider);
    final count = await taskRepo.countTaskLogsByName(
      widget.householdId,
      widget.task.nameFr,
    );

    if (!mounted) return;

    final message = count > 0
        ? S.deleteTaskWarningMessage(widget.task.nameFr, count)
        : S.deleteTaskNoLogsMessage(widget.task.nameFr);

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
      await widget.ref
          .read(householdControllerProvider.notifier)
          .deletePredefinedTask(widget.householdId, widget.task);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.taskRemovedFromPredefined)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return _TaskFormSheet(
      title: S.editPredefinedTask,
      nameController: _nameController,
      categoryId: _categoryId,
      durationMinutes: _durationMinutes,
      difficulty: _difficulty,
      formKey: _formKey,
      customCategories: widget.household.customCategories,
      onCategoryChanged: (v) => setState(() => _categoryId = v),
      onDurationChanged: (v) => setState(() => _durationMinutes = v),
      onDifficultyChanged: (v) => setState(() => _difficulty = v),
      submitLabel: S.save,
      onSubmit: _submit,
      trailing: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: TextButton.icon(
          onPressed: _delete,
          icon: const Icon(Icons.delete_outline),
          label: Text(S.delete),
          style: TextButton.styleFrom(
            foregroundColor: colorScheme.error,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared form sheet widget (StatefulWidget for duration controller)
// ---------------------------------------------------------------------------

class _TaskFormSheet extends StatefulWidget {
  final String title;
  final TextEditingController nameController;
  final String categoryId;
  final int durationMinutes;
  final TaskDifficulty difficulty;
  final GlobalKey<FormState> formKey;
  final List<HouseholdCategory> customCategories;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<int> onDurationChanged;
  final ValueChanged<TaskDifficulty> onDifficultyChanged;
  final String submitLabel;
  final VoidCallback onSubmit;
  final Widget? trailing;

  const _TaskFormSheet({
    required this.title,
    required this.nameController,
    required this.categoryId,
    required this.durationMinutes,
    required this.difficulty,
    required this.formKey,
    required this.customCategories,
    required this.onCategoryChanged,
    required this.onDurationChanged,
    required this.onDifficultyChanged,
    required this.submitLabel,
    required this.onSubmit,
    this.trailing,
  });

  @override
  State<_TaskFormSheet> createState() => _TaskFormSheetState();
}

class _TaskFormSheetState extends State<_TaskFormSheet> {
  late final TextEditingController _durationController;

  @override
  void initState() {
    super.initState();
    _durationController =
        TextEditingController(text: widget.durationMinutes.toString());
  }

  @override
  void didUpdateWidget(_TaskFormSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.durationMinutes != widget.durationMinutes) {
      final text = widget.durationMinutes.toString();
      if (_durationController.text != text) {
        _durationController.text = text;
      }
    }
  }

  @override
  void dispose() {
    _durationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final allCategories = getAllCategories(widget.customCategories);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Form(
        key: widget.formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.title,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: widget.nameController,
                maxLength: 50,
                decoration: InputDecoration(
                  labelText: S.taskNameFrLabel,
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return S.pleaseEnterTaskName;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: widget.categoryId,
                decoration: InputDecoration(
                  labelText: S.category,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.category),
                ),
                items: allCategories.map((cat) {
                  return DropdownMenuItem(
                    value: cat.id,
                    child: Row(
                      children: [
                        if (cat.hasEmoji)
                          Text(cat.emoji!, style: const TextStyle(fontSize: 18))
                        else
                          Icon(cat.icon, size: 18, color: cat.color),
                        const SizedBox(width: 8),
                        Text(getCategoryLabel(
                            cat.id, widget.customCategories)),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) widget.onCategoryChanged(value);
                },
              ),
              const SizedBox(height: 16),
              Text(
                S.defaultDurationLabel,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  IconButton(
                    onPressed: widget.durationMinutes > 5
                        ? () {
                            final current =
                                int.tryParse(_durationController.text) ??
                                    widget.durationMinutes;
                            if (current > 5) {
                              widget.onDurationChanged(current - 5);
                            }
                          }
                        : null,
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  Expanded(
                    child: TextFormField(
                      controller: _durationController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(
                        suffixText: 'min',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        final parsed = int.tryParse(value);
                        if (parsed != null && parsed > 0) {
                          widget.onDurationChanged(parsed);
                        }
                      },
                      validator: (value) {
                        final parsed = int.tryParse(value ?? '');
                        if (parsed == null || parsed <= 0) {
                          return S.pleaseEnterValidDuration;
                        }
                        return null;
                      },
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      final current =
                          int.tryParse(_durationController.text) ??
                              widget.durationMinutes;
                      widget.onDurationChanged(current + 5);
                    },
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                S.defaultDifficultyLabel,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: TaskDifficulty.values.map((d) {
                  final isSelected = widget.difficulty == d;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: GestureDetector(
                        onTap: () => widget.onDifficultyChanged(d),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? colorScheme.primaryContainer
                                : colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? colorScheme.primary
                                  : colorScheme.outlineVariant,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Center(
                            child: DifficultyBadge(
                              difficulty: d,
                              compact: false,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: widget.onSubmit,
                child: Text(widget.submitLabel),
              ),
              if (widget.trailing != null) widget.trailing!,
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Add category sheet (Phase F)
// ---------------------------------------------------------------------------

class _AddCategorySheet extends StatefulWidget {
  final String householdId;
  final WidgetRef ref;

  const _AddCategorySheet({
    required this.householdId,
    required this.ref,
  });

  @override
  State<_AddCategorySheet> createState() => _AddCategorySheetState();
}

class _AddCategorySheetState extends State<_AddCategorySheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emojiController = TextEditingController();
  String? _selectedEmoji;
  int? _selectedColorValue;

  static const List<Color> _availableColors = [
    Color(0xFFE57373), // Red
    Color(0xFFFF8A65), // Deep Orange
    Color(0xFFFFB74D), // Orange
    Color(0xFFFFD54F), // Amber
    Color(0xFFAED581), // Light Green
    Color(0xFF81C784), // Green
    Color(0xFF4DB6AC), // Teal
    Color(0xFF4FC3F7), // Light Blue
    Color(0xFF64B5F6), // Blue
    Color(0xFF7986CB), // Indigo
    Color(0xFFBA68C8), // Purple
    Color(0xFFF06292), // Pink
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emojiController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedEmoji == null || _selectedColorValue == null) return;

    final category = HouseholdCategory(
      id: const Uuid().v4(),
      labelFr: _nameController.text.trim(),
      iconCodePoint: 0xe88a, // fallback Icons.home codepoint
      colorValue: _selectedColorValue!,
      emoji: _selectedEmoji,
    );

    await widget.ref
        .read(householdControllerProvider.notifier)
        .addCustomCategory(widget.householdId, category);

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.categoryAdded)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                S.addCategory,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: S.categoryNameLabel,
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return S.categoryNameRequired;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Text(
                S.chooseIcon,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  // Emoji preview
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _selectedEmoji != null
                            ? colorScheme.primary
                            : colorScheme.outlineVariant,
                        width: _selectedEmoji != null ? 2 : 1,
                      ),
                    ),
                    child: Center(
                      child: _selectedEmoji != null
                          ? Text(_selectedEmoji!,
                              style: const TextStyle(fontSize: 28))
                          : Icon(Icons.add_reaction_outlined,
                              color: colorScheme.onSurfaceVariant),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _emojiController,
                      decoration: InputDecoration(
                        hintText: S.chooseIcon,
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        // Extract the first emoji (may be multi-codepoint grapheme)
                        if (value.isNotEmpty) {
                          final chars = value.characters.first;
                          setState(() => _selectedEmoji = chars);
                          // Keep only the first emoji in the field
                          if (value.characters.length > 1) {
                            _emojiController.text = chars;
                            _emojiController.selection =
                                TextSelection.collapsed(offset: chars.length);
                          }
                        } else {
                          setState(() => _selectedEmoji = null);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                S.chooseColor,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _availableColors.map((color) {
                  final isSelected = _selectedColorValue == color.value;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedColorValue = color.value);
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? colorScheme.onSurface
                              : Colors.transparent,
                          width: isSelected ? 3 : 0,
                        ),
                      ),
                      child: isSelected
                          ? Icon(Icons.check,
                              color: colorScheme.onPrimary, size: 20)
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _selectedEmoji != null &&
                        _selectedColorValue != null
                    ? _submit
                    : null,
                child: Text(S.addCategory),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
