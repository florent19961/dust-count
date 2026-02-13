import 'package:flutter/material.dart';
import 'package:dust_count/shared/strings.dart';
import 'package:dust_count/shared/models/household_category.dart';
import 'package:dust_count/shared/utils/category_helpers.dart';
import 'package:dust_count/shared/widgets/difficulty_badge.dart';
import 'package:dust_count/core/constants/app_constants.dart';

/// Shared form sheet for adding/editing a predefined task.
class TaskFormSheet extends StatefulWidget {
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
  final bool categoryLocked;

  const TaskFormSheet({
    super.key,
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
    this.categoryLocked = false,
  });

  @override
  State<TaskFormSheet> createState() => _TaskFormSheetState();
}

class _TaskFormSheetState extends State<TaskFormSheet> {
  late final TextEditingController _durationController;

  @override
  void initState() {
    super.initState();
    _durationController =
        TextEditingController(text: widget.durationMinutes.toString());
  }

  @override
  void didUpdateWidget(TaskFormSheet oldWidget) {
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
                          Text(cat.emoji!,
                              style: const TextStyle(fontSize: 18))
                        else
                          Icon(cat.icon, size: 18, color: cat.color),
                        const SizedBox(width: 8),
                        Text(getCategoryLabel(
                            cat.id, widget.customCategories)),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: widget.categoryLocked
                    ? null
                    : (value) {
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
