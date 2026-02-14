import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dust_count/shared/strings.dart';
import 'package:dust_count/shared/models/household.dart';
import 'package:dust_count/shared/models/household_category.dart';
import 'package:dust_count/features/household/domain/household_providers.dart';
import 'package:dust_count/features/household/presentation/widgets/task_form_sheet.dart';
import 'package:dust_count/features/tasks/data/task_repository.dart';
import 'package:dust_count/core/constants/app_constants.dart';

/// Bottom sheet for editing an existing predefined task.
class EditPredefinedTaskSheet extends ConsumerStatefulWidget {
  final String householdId;
  final Household household;
  final PredefinedTask task;

  const EditPredefinedTaskSheet({
    super.key,
    required this.householdId,
    required this.household,
    required this.task,
  });

  @override
  ConsumerState<EditPredefinedTaskSheet> createState() =>
      _EditPredefinedTaskSheetState();
}

class _EditPredefinedTaskSheetState
    extends ConsumerState<EditPredefinedTaskSheet> {
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

    await ref
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
    final taskRepo = ref.read(taskRepositoryProvider);
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
      await ref
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

    return TaskFormSheet(
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
