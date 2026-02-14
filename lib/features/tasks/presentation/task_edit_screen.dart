import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dust_count/shared/strings.dart';
import 'package:go_router/go_router.dart';
import 'package:dust_count/shared/models/household.dart';
import 'package:dust_count/shared/models/task_log.dart';
import 'package:dust_count/core/constants/app_constants.dart';
import 'package:dust_count/shared/utils/category_helpers.dart';
import 'package:dust_count/features/tasks/domain/task_providers.dart';
import 'package:dust_count/features/tasks/presentation/widgets/predefined_task_selector.dart';
import 'package:dust_count/shared/widgets/difficulty_badge.dart';
import 'package:dust_count/app/theme/app_colors.dart';

/// Screen for editing an existing task log.
///
/// Pre-fills all fields from the given [taskLog]. For predefined tasks the user
/// can switch to another predefined task; custom task names are read-only.
class TaskEditScreen extends ConsumerStatefulWidget {
  final TaskLog taskLog;
  final Household household;

  const TaskEditScreen({
    required this.taskLog,
    required this.household,
    super.key,
  });

  @override
  ConsumerState<TaskEditScreen> createState() => _TaskEditScreenState();
}

class _TaskEditScreenState extends ConsumerState<TaskEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _durationController = TextEditingController();

  late String _selectedCategory;
  late DateTime _selectedDate;
  late int _durationMinutes;
  late TaskDifficulty _difficulty;

  // Performer selection
  late String _performedBy;
  late String _performedByName;

  // Predefined task selection (null if custom)
  PredefinedTask? _selectedPredefinedTask;
  late bool _isCustomTask;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.taskLog.categoryId;
    _selectedDate = widget.taskLog.date;
    _durationMinutes = widget.taskLog.durationMinutes;
    _difficulty = widget.taskLog.difficulty;
    _durationController.text = _durationMinutes.toString();
    _performedBy = widget.taskLog.performedBy;
    _performedByName = widget.taskLog.performedByName;

    // Try to match the task log to a predefined task
    final match = widget.household.predefinedTasks.where(
      (t) => t.nameFr == widget.taskLog.taskName ||
             t.nameEn == widget.taskLog.taskName,
    );
    if (match.isNotEmpty) {
      _selectedPredefinedTask = match.first;
      _isCustomTask = false;
    } else {
      _selectedPredefinedTask = null;
      _isCustomTask = true;
    }
  }

  @override
  void dispose() {
    _durationController.dispose();
    super.dispose();
  }

  void _onPredefinedTaskSelected(PredefinedTask? task) {
    if (task == null) {
      setState(() {
        _selectedPredefinedTask = null;
      });
    } else {
      setState(() {
        _selectedPredefinedTask = task;
        _selectedCategory = task.categoryId;
      });
    }
  }

  Future<void> _showDatePicker() async {
    await showModalBottomSheet(
      context: context,
      builder: (context) {
        return SizedBox(
          height: 250,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => context.pop(),
                    child: Text(S.cancel),
                  ),
                  TextButton(
                    onPressed: () => context.pop(),
                    child: Text(S.done),
                  ),
                ],
              ),
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

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    String taskName;
    String? taskNameFr;
    String? taskNameEn;

    if (_isCustomTask) {
      // Custom task: keep original name
      taskName = widget.taskLog.taskName;
      taskNameFr = widget.taskLog.taskNameFr;
      taskNameEn = widget.taskLog.taskNameEn;
    } else if (_selectedPredefinedTask != null) {
      taskName = _selectedPredefinedTask!.nameFr;
      taskNameFr = _selectedPredefinedTask!.nameFr;
      taskNameEn = _selectedPredefinedTask!.nameEn;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.pleaseSelectTask)),
      );
      return;
    }

    final updatedLog = widget.taskLog.copyWith(
      taskName: taskName,
      taskNameFr: taskNameFr,
      taskNameEn: taskNameEn,
      categoryId: _selectedCategory,
      durationMinutes: _durationMinutes,
      difficulty: _difficulty,
      date: _selectedDate,
      performedBy: _performedBy,
      performedByName: _performedByName,
    );

    final controller = ref.read(taskControllerProvider.notifier);
    await controller.updateTask(
      householdId: widget.household.id,
      updatedLog: updatedLog,
    );

    final state = ref.read(taskControllerProvider);
    state.when(
      data: (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(S.taskUpdatedSuccess),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          );
          context.pop(updatedLog);
        }
      },
      loading: () {},
      error: (error, _) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(S.taskUpdatedError(error.toString())),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(taskControllerProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(S.editTask)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Task selection: predefined selector or read-only custom name
            if (_isCustomTask) ...[
              // Custom task: display name as read-only
              TextFormField(
                initialValue: widget.taskLog.taskName,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: S.taskName,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.task),
                ),
              ),
              const SizedBox(height: 16),
              // Category dropdown (editable even for custom)
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: InputDecoration(
                  labelText: S.category,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.category),
                ),
                items: getAllCategories(widget.household.customCategories).map((cat) {
                  return DropdownMenuItem<String>(
                    value: cat.id,
                    child: Text(cat.labelFr),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedCategory = value;
                    });
                  }
                },
              ),
            ] else ...[
              PredefinedTaskSelector(
                tasks: widget.household.predefinedTasks,
                onTaskSelected: _onPredefinedTaskSelected,
                initialTask: _selectedPredefinedTask,
                customCategories: widget.household.customCategories,
              ),
            ],

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),

            // Performer dropdown
            if (widget.household.members.length > 1) ...[
              DropdownButtonFormField<HouseholdMember>(
                value: widget.household.members
                    .where((m) => m.userId == _performedBy)
                    .firstOrNull,
                decoration: InputDecoration(
                  labelText: S.performedBy,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.person),
                ),
                isExpanded: true,
                items: widget.household.members.map((member) {
                  final memberColor = AppColors.getMemberColor(member.colorIndex);
                  return DropdownMenuItem<HouseholdMember>(
                    value: member,
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: memberColor,
                          child: Text(
                            member.displayName.substring(0, 1).toUpperCase(),
                            style: TextStyle(
                              color: colorScheme.onPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(member.displayName),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (member) {
                  if (member != null) {
                    setState(() {
                      _performedBy = member.userId;
                      _performedByName = member.displayName;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
            ],

            // Date
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

            // Duration
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
            const SizedBox(height: 16),

            // Difficulty
            Text(
              S.difficulty,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
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

            // Submit
            FilledButton(
              onPressed: state.isLoading ? null : _submitForm,
              child: state.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(S.saveChanges),
            ),
          ],
        ),
      ),
    );
  }
}
