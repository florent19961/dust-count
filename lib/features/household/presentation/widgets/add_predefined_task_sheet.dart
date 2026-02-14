import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:dust_count/shared/strings.dart';
import 'package:dust_count/shared/models/household.dart';
import 'package:dust_count/shared/models/household_category.dart';
import 'package:dust_count/features/household/domain/household_providers.dart';
import 'package:dust_count/features/household/presentation/widgets/task_form_sheet.dart';
import 'package:dust_count/core/constants/app_constants.dart';

/// Bottom sheet for adding a new predefined task to a household.
class AddPredefinedTaskSheet extends ConsumerStatefulWidget {
  final String householdId;
  final String? initialCategoryId;
  final bool categoryLocked;

  const AddPredefinedTaskSheet({
    super.key,
    required this.householdId,
    this.initialCategoryId,
    this.categoryLocked = false,
  });

  @override
  ConsumerState<AddPredefinedTaskSheet> createState() =>
      _AddPredefinedTaskSheetState();
}

class _AddPredefinedTaskSheetState
    extends ConsumerState<AddPredefinedTaskSheet> {
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

    await ref
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
    final householdAsync = ref.watch(currentHouseholdProvider);
    final customCategories =
        householdAsync.value?.customCategories ?? const [];

    return TaskFormSheet(
      title: S.addPredefinedTask,
      nameController: _nameController,
      categoryId: _categoryId,
      durationMinutes: _durationMinutes,
      difficulty: _difficulty,
      formKey: _formKey,
      customCategories: customCategories,
      categoryLocked: widget.categoryLocked,
      onCategoryChanged: (v) => setState(() => _categoryId = v),
      onDurationChanged: (v) => setState(() => _durationMinutes = v),
      onDifficultyChanged: (v) => setState(() => _difficulty = v),
      submitLabel: S.addPredefinedTask,
      onSubmit: _submit,
    );
  }
}
