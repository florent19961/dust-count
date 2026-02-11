import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dust_count/shared/strings.dart';
import 'package:go_router/go_router.dart';
import 'package:dust_count/shared/models/household.dart';
import 'package:dust_count/core/constants/app_constants.dart';
import 'package:dust_count/features/tasks/domain/task_providers.dart';
import 'package:dust_count/features/tasks/presentation/widgets/predefined_task_selector.dart';
import 'package:dust_count/features/tasks/presentation/task_timer_screen.dart';
import 'package:dust_count/shared/widgets/difficulty_badge.dart';
import 'package:dust_count/features/household/domain/household_providers.dart';

/// Screen for adding a new task log
///
/// Optimized for quick entry with predefined tasks and minimal taps
class TaskFormScreen extends ConsumerStatefulWidget {
  /// Current household
  final Household household;

  /// When true, renders without Scaffold/AppBar (for embedding in tabs)
  final bool embedded;

  /// Called after a task is successfully added (e.g. to close a bottom sheet)
  final VoidCallback? onTaskAdded;

  const TaskFormScreen({
    required this.household,
    this.embedded = false,
    this.onTaskAdded,
    super.key,
  });

  @override
  ConsumerState<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends ConsumerState<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _durationController = TextEditingController();

  // Form state
  PredefinedTask? _selectedPredefinedTask;
  String? _selectedCategory;
  DateTime _selectedDate = DateTime.now();
  int _durationMinutes = 15;
  TaskDifficulty _difficulty = TaskDifficulty.reloo;

  @override
  void initState() {
    super.initState();
    _durationController.text = _durationMinutes.toString();
  }

  @override
  void dispose() {
    _durationController.dispose();
    super.dispose();
  }

  /// Reset form to initial state
  void _resetForm() {
    setState(() {
      _selectedPredefinedTask = null;
      _selectedCategory = null;
      _selectedDate = DateTime.now();
      _durationMinutes = 15;
      _difficulty = TaskDifficulty.reloo;
    });
    _durationController.text = '15';
    _formKey.currentState?.reset();
  }

  /// Handle predefined task selection (nullable for deselection)
  void _onPredefinedTaskSelected(PredefinedTask? task) {
    if (task == null) {
      setState(() {
        _selectedPredefinedTask = null;
        _selectedCategory = null;
        _durationMinutes = 15;
        _difficulty = TaskDifficulty.reloo;
      });
      _durationController.text = '15';
    } else {
      setState(() {
        _selectedPredefinedTask = task;
        _selectedCategory = task.categoryId;
        _durationMinutes = task.defaultDurationMinutes;
        _difficulty = task.defaultDifficulty;
      });
      _durationController.text = task.defaultDurationMinutes.toString();
    }
  }

  /// Launch the full-screen timer and fill duration on return
  Future<void> _startTimer() async {
    if (_selectedPredefinedTask == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.pleaseSelectTaskFirst)),
      );
      return;
    }

    final taskName = _selectedPredefinedTask!.nameFr;

    final minutes = await Navigator.push<int>(
      context,
      MaterialPageRoute(
        builder: (_) => TaskTimerScreen(taskName: taskName),
      ),
    );

    if (minutes != null && mounted) {
      setState(() {
        _durationMinutes = minutes;
      });
      _durationController.text = minutes.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.timerResult(minutes))),
      );
    }
  }

  /// Show iOS-style date picker
  Future<void> _showDatePicker() async {
    await showModalBottomSheet(
      context: context,
      builder: (context) {
        return SizedBox(
          height: 250,
          child: Column(
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => context.pop(),
                    child: Text(S.cancel),
                  ),
                  TextButton(
                    onPressed: () {
                      context.pop();
                    },
                    child: Text(S.done),
                  ),
                ],
              ),
              // Date picker
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: _selectedDate,
                  maximumDate: DateTime.now(),
                  onDateTimeChanged: (date) {
                    setState(() {
                      _selectedDate = date;
                    });
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Submit the form
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedPredefinedTask == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.pleaseSelectTask)),
      );
      return;
    }

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.pleaseSelectCategory)),
      );
      return;
    }

    final taskName = _selectedPredefinedTask!.nameFr;
    final taskNameFr = _selectedPredefinedTask!.nameFr;
    final taskNameEn = _selectedPredefinedTask!.nameEn;

    final controller = ref.read(taskControllerProvider.notifier);

    await controller.addTask(
      householdId: widget.household.id,
      taskName: taskName,
      taskNameFr: taskNameFr,
      taskNameEn: taskNameEn,
      categoryId: _selectedCategory!,
      durationMinutes: _durationMinutes,
      difficulty: _difficulty,
      date: _selectedDate,
      comment: null,
    );

    final state = ref.read(taskControllerProvider);

    state.when(
      data: (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(S.taskAddedSuccess),
              backgroundColor: Colors.green,
            ),
          );
          if (widget.onTaskAdded != null) {
            _resetForm();
            widget.onTaskAdded!();
          } else if (widget.embedded) {
            _resetForm();
            ref.read(householdTabIndexProvider.notifier).state = 0;
          } else {
            context.pop();
          }
        }
      },
      loading: () {},
      error: (error, _) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                S.taskAddedError(error.toString()),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
    );
  }

  Widget _buildFormContent(AsyncValue<void> state) {
    final colorScheme = Theme.of(context).colorScheme;
    final prefsAsync =
        ref.watch(memberPreferencesProvider(widget.household.id));
    final quickTaskIds = prefsAsync.value?.quickTaskIds;
    final visibleTasks = widget.household.predefinedTasks
        .where((t) => t.categoryId != 'archivees')
        .toList();

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Unified task dropdown
          PredefinedTaskSelector(
            tasks: visibleTasks,
            onTaskSelected: _onPredefinedTaskSelected,
            customCategories: widget.household.customCategories,
            quickTaskIds: quickTaskIds,
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.calendar_today),
            title: Text(S.date),
            subtitle: Text(S.formatDateLong(_selectedDate)),
            trailing: const Icon(Icons.edit),
            onTap: _showDatePicker,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: colorScheme.outlineVariant),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            S.duration,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              IconButton(
                onPressed: () {
                  final current =
                      int.tryParse(_durationController.text) ?? _durationMinutes;
                  if (current > 5) {
                    final newValue = current - 5;
                    setState(() {
                      _durationMinutes = newValue;
                    });
                    _durationController.text = newValue.toString();
                  }
                },
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
                      setState(() {
                        _durationMinutes = parsed;
                      });
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
                      int.tryParse(_durationController.text) ?? _durationMinutes;
                  final newValue = current + 5;
                  setState(() {
                    _durationMinutes = newValue;
                  });
                  _durationController.text = newValue.toString();
                },
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Prominent timer button
          OutlinedButton.icon(
            onPressed: _startTimer,
            icon: const Icon(Icons.timer_outlined),
            label: Text(S.startTimer),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            S.difficulty,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          // Compact difficulty chips
          Wrap(
            spacing: 8,
            children: TaskDifficulty.values.map((d) {
              return ChoiceChip(
                label: DifficultyBadge(difficulty: d, compact: true),
                selected: _difficulty == d,
                onSelected: (_) => setState(() => _difficulty = d),
                showCheckmark: false,
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: state.isLoading ? null : _submitForm,
            child: state.isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(S.addTask),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(taskControllerProvider);
    final formContent = _buildFormContent(state);

    if (widget.embedded) {
      return formContent;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(S.addTask),
      ),
      body: formContent,
    );
  }
}
