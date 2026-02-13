import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:dust_count/shared/strings.dart';
import 'package:dust_count/shared/models/household.dart';
import 'package:dust_count/shared/models/household_category.dart';
import 'package:dust_count/shared/utils/category_helpers.dart';
import 'package:dust_count/shared/widgets/difficulty_badge.dart';
import 'package:dust_count/core/constants/app_constants.dart';
import 'package:dust_count/features/household/domain/household_providers.dart';
import 'package:dust_count/features/household/presentation/widgets/task_form_sheet.dart';
import 'package:dust_count/features/household/presentation/widgets/add_category_sheet.dart';

/// Screen for creating a new household with a 2-step flow.
class CreateHouseholdScreen extends ConsumerStatefulWidget {
  const CreateHouseholdScreen({super.key});

  @override
  ConsumerState<CreateHouseholdScreen> createState() =>
      _CreateHouseholdScreenState();
}

class _CreateHouseholdScreenState
    extends ConsumerState<CreateHouseholdScreen> {
  static const _uuid = Uuid();
  static const int _maxQuickTasks = 12;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _isLoading = false;
  int _currentStep = 0;

  /// Local copy of predefined tasks (editable before household creation).
  late List<PredefinedTask> _tasks;

  /// IDs of tasks marked as quick tasks.
  List<String> _quickTaskIds = [];

  /// Custom categories created during setup.
  final List<HouseholdCategory> _customCategories = [];

  bool _isDragging = false;
  final Set<String> _expandedTaskIds = {};

  @override
  void initState() {
    super.initState();
    _tasks = AppConstants.predefinedTasks
        .map((t) => PredefinedTask(
              id: _uuid.v4(),
              nameFr: t['nameFr'] as String,
              nameEn: t['nameEn'] as String,
              categoryId: t['category'] as String,
              defaultDurationMinutes: t['durationMinutes'] as int,
              defaultDifficulty: t['difficulty'] as TaskDifficulty,
            ))
        .toList();
    _quickTaskIds = _tasks
        .take(AppConstants.quickTaskCount)
        .map((t) => t.id)
        .toList();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Navigation helpers
  // ---------------------------------------------------------------------------

  void _goToStep2() {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _currentStep = 1);
  }

  void _goBackToStep1() {
    setState(() => _currentStep = 0);
  }

  // ---------------------------------------------------------------------------
  // Household creation
  // ---------------------------------------------------------------------------

  Future<void> _createHousehold({bool useDefaults = false}) async {
    if (!(_formKey.currentState?.validate() ?? true)) return;

    setState(() => _isLoading = true);

    try {
      await ref
          .read(householdControllerProvider.notifier)
          .createHousehold(
            _nameController.text.trim(),
            customTasks: useDefaults ? null : _tasks,
            customCategories:
                useDefaults || _customCategories.isEmpty
                    ? null
                    : _customCategories,
          );

      if (!mounted) return;

      final currentHouseholdId = ref.read(currentHouseholdIdProvider);
      if (currentHouseholdId != null) {
        if (!useDefaults) {
          await ref
              .read(householdControllerProvider.notifier)
              .updateQuickTaskIds(currentHouseholdId, _quickTaskIds);
        }
        if (!mounted) return;
        context.go('/household/$currentHouseholdId');
      } else {
        context.go('/households');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${S.errorCreatingHousehold}: ${e.toString()}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Task CRUD (local state)
  // ---------------------------------------------------------------------------

  void _showAddTaskSheet(
    BuildContext context,
    String categoryId, {
    bool lockCategory = false,
  }) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    String catId = categoryId;
    int duration = 15;
    TaskDifficulty difficulty = TaskDifficulty.reloo;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => TaskFormSheet(
          title: S.addPredefinedTask,
          nameController: nameController,
          categoryId: catId,
          durationMinutes: duration,
          difficulty: difficulty,
          formKey: formKey,
          customCategories: _customCategories,
          categoryLocked: lockCategory,
          onCategoryChanged: (v) => setSheetState(() => catId = v),
          onDurationChanged: (v) => setSheetState(() => duration = v),
          onDifficultyChanged: (v) => setSheetState(() => difficulty = v),
          submitLabel: S.addPredefinedTask,
          onSubmit: () {
            if (!formKey.currentState!.validate()) return;
            final task = PredefinedTask(
              id: _uuid.v4(),
              nameFr: nameController.text.trim(),
              nameEn: nameController.text.trim(),
              categoryId: catId,
              defaultDurationMinutes: duration,
              defaultDifficulty: difficulty,
            );
            setState(() => _tasks.add(task));
            Navigator.of(ctx).pop();
          },
        ),
      ),
    );
  }

  void _showEditTaskSheet(BuildContext context, PredefinedTask task) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: task.nameFr);
    String catId = task.categoryId;
    int duration = task.defaultDurationMinutes;
    TaskDifficulty difficulty = task.defaultDifficulty;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => TaskFormSheet(
          title: S.editPredefinedTask,
          nameController: nameController,
          categoryId: catId,
          durationMinutes: duration,
          difficulty: difficulty,
          formKey: formKey,
          customCategories: _customCategories,
          onCategoryChanged: (v) => setSheetState(() => catId = v),
          onDurationChanged: (v) => setSheetState(() => duration = v),
          onDifficultyChanged: (v) => setSheetState(() => difficulty = v),
          submitLabel: S.save,
          onSubmit: () {
            if (!formKey.currentState!.validate()) return;
            final updated = PredefinedTask(
              id: task.id,
              nameFr: nameController.text.trim(),
              nameEn: nameController.text.trim(),
              categoryId: catId,
              defaultDurationMinutes: duration,
              defaultDifficulty: difficulty,
            );
            setState(() {
              final idx = _tasks.indexWhere((t) => t.id == task.id);
              if (idx != -1) _tasks[idx] = updated;
            });
            Navigator.of(ctx).pop();
          },
        ),
      ),
    );
  }

  Future<void> _confirmDeleteTask(PredefinedTask task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(S.deleteTask),
        content: Text(S.deleteTaskConfirmation),
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

    if (confirmed == true) {
      setState(() {
        _tasks.removeWhere((t) => t.id == task.id);
        _quickTaskIds.remove(task.id);
      });
    }
  }

  // ---------------------------------------------------------------------------
  // Category CRUD (local state)
  // ---------------------------------------------------------------------------

  void _showAddCategorySheet(BuildContext context) {
    final totalCategories =
        builtInCategories.length + _customCategories.length;
    if (totalCategories >= 9) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.maxCategoriesReached)),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => AddCategorySheet(
        onCategoryCreated: (category) {
          setState(() => _customCategories.add(category));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(S.categoryAdded)),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(S.createHousehold),
        leading: _currentStep == 1
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _goBackToStep1,
              )
            : null,
      ),
      body: _currentStep == 0 ? _buildStep1(theme) : _buildStep2(theme),
    );
  }

  // ---------------------------------------------------------------------------
  // Step 1 — Household name
  // ---------------------------------------------------------------------------

  Widget _buildStep1(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              Icons.home_outlined,
              size: 80,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              S.createNewHousehold,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              S.createHouseholdDescription,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: S.householdName,
                hintText: S.householdNameHint,
                prefixIcon: const Icon(Icons.home),
                border: const OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
              enabled: !_isLoading,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return S.householdNameRequired;
                }
                if (value.trim().length < 2) {
                  return S.householdNameTooShort;
                }
                if (value.trim().length > 50) {
                  return S.householdNameTooLong;
                }
                return null;
              },
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _isLoading ? null : _goToStep2,
              child: Text(S.nextStep),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _isLoading ? null : () => context.pop(),
              child: Text(S.cancel),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Step 2 — Task customisation
  // ---------------------------------------------------------------------------

  Widget _buildStep2(ThemeData theme) {
    // Group tasks by category
    final grouped = <String, List<PredefinedTask>>{};
    for (final task in _tasks) {
      grouped.putIfAbsent(task.categoryId, () => []).add(task);
    }
    // Ensure all built-in + custom categories appear even if empty
    for (final cat in builtInCategories) {
      grouped.putIfAbsent(cat.id, () => []);
    }
    for (final cat in _customCategories) {
      grouped.putIfAbsent(cat.id, () => []);
    }

    // Sort: built-in first (in order), then custom
    final categoryIds = grouped.keys.toList()
      ..sort((a, b) {
        final aBuiltIn = builtInCategories.any((c) => c.id == a);
        final bBuiltIn = builtInCategories.any((c) => c.id == b);
        if (aBuiltIn && !bBuiltIn) return -1;
        if (!aBuiltIn && bBuiltIn) return 1;
        if (aBuiltIn && bBuiltIn) {
          final aIdx = builtInCategories.indexWhere((c) => c.id == a);
          final bIdx = builtInCategories.indexWhere((c) => c.id == b);
          return aIdx.compareTo(bIdx);
        }
        return a.compareTo(b);
      });

    return Column(
      children: [
        // Header — opaque background to clip scrolling content
        Material(
          color: theme.colorScheme.surface,
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  S.setupTasks,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  S.setupTasksDescription,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.add),
                      label: Text(S.addTask),
                      onPressed: () =>
                          _showAddTaskSheet(context, 'menage'),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      icon: const Icon(Icons.add),
                      label: Text(S.addCategory),
                      onPressed: () => _showAddCategorySheet(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 1),
        // Category accordion list
        Expanded(
          child: Stack(
            children: [
              SingleChildScrollView(
                padding: EdgeInsets.only(bottom: _isDragging ? 88 : 16),
                child: Column(
                  children: categoryIds.map((catId) {
                    final tasks = grouped[catId]!;
                    return _buildCategoryTile(theme, catId, tasks);
                  }).toList(),
                ),
              ),
              if (_isDragging) _buildTrashZone(),
            ],
          ),
        ),
        // Bottom action buttons — opaque background to clip scrolling content
        Material(
          color: theme.colorScheme.surface,
          elevation: 0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading
                            ? null
                            : () => _createHousehold(useDefaults: true),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(S.skipStep),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _isLoading ? null : () => _createHousehold(),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(S.createHouseholdAction),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryTile(
    ThemeData theme,
    String categoryId,
    List<PredefinedTask> tasks,
  ) {
    final color = getCategoryColor(categoryId, _customCategories);
    final emoji = getCategoryEmoji(categoryId, _customCategories);
    final label = getCategoryLabel(categoryId, _customCategories);
    final isCustom = !builtInCategories.any((c) => c.id == categoryId);
    final isEmpty = tasks.isEmpty;

    final expansionTile = ExpansionTile(
      leading: emoji != null
          ? Text(emoji, style: const TextStyle(fontSize: 20))
          : Icon(
              getCategoryIcon(categoryId, _customCategories),
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
              onPressed: () {
                setState(() {
                  final removedIds = _tasks
                      .where((t) => t.categoryId == categoryId)
                      .map((t) => t.id)
                      .toSet();
                  _quickTaskIds.removeWhere(removedIds.contains);
                  _customCategories.removeWhere((c) => c.id == categoryId);
                  _tasks.removeWhere((t) => t.categoryId == categoryId);
                });
              },
            )
          : null,
      children: [
        ...tasks.map((task) => _buildTaskItem(theme, task)),
        if (isEmpty)
          ListTile(
            leading: Icon(Icons.add_circle_outline, color: color),
            title: Text(
              S.addTaskToCategory,
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
            onTap: () => _showAddTaskSheet(context, categoryId,
                lockCategory: true),
          ),
      ],
    );

    return DragTarget<PredefinedTask>(
      onWillAcceptWithDetails: (details) {
        return details.data.categoryId != categoryId;
      },
      onAcceptWithDetails: (details) {
        _onTaskDroppedOnCategory(details.data, categoryId);
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

  void _onTaskDroppedOnCategory(PredefinedTask task, String newCategoryId) {
    setState(() {
      final idx = _tasks.indexWhere((t) => t.id == task.id);
      if (idx != -1) {
        _tasks[idx] = PredefinedTask(
          id: task.id,
          nameFr: task.nameFr,
          nameEn: task.nameEn,
          categoryId: newCategoryId,
          defaultDurationMinutes: task.defaultDurationMinutes,
          defaultDifficulty: task.defaultDifficulty,
        );
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(S.categoryChanged)),
    );
  }

  Widget _buildTrashZone() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: DragTarget<PredefinedTask>(
        onWillAcceptWithDetails: (_) => true,
        onAcceptWithDetails: (details) => _confirmDeleteTask(details.data),
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

  void _toggleQuickTask(String taskId) {
    setState(() {
      if (_quickTaskIds.contains(taskId)) {
        _quickTaskIds.remove(taskId);
      } else {
        if (_quickTaskIds.length >= _maxQuickTasks) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(S.maxQuickTasksReached)),
          );
          return;
        }
        _quickTaskIds.add(taskId);
      }
    });
  }

  Widget _buildTaskItem(ThemeData theme, PredefinedTask task) {
    final isQuick = _quickTaskIds.contains(task.id);
    final isExpanded = _expandedTaskIds.contains(task.id);
    final categoryColor = getCategoryColor(task.categoryId, _customCategories);

    final tile = ListTile(
      leading: Icon(
        Icons.drag_handle,
        color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
        size: 20,
      ),
      title: Text(task.nameFr),
      subtitle: isExpanded
          ? Row(
              children: [
                Text('${task.defaultDurationMinutes} min'),
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
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(
              isQuick ? Icons.favorite : Icons.favorite_border,
              size: 20,
              color: isQuick ? Colors.pinkAccent : Colors.grey,
            ),
            tooltip: S.quickTask,
            onPressed: () => _toggleQuickTask(task.id),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            tooltip: S.editPredefinedTask,
            onPressed: () => _showEditTaskSheet(context, task),
          ),
          IconButton(
            icon: Icon(Icons.delete_outline,
                size: 20, color: theme.colorScheme.error),
            tooltip: S.delete,
            onPressed: () => _confirmDeleteTask(task),
          ),
        ],
      ),
    );

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
}
