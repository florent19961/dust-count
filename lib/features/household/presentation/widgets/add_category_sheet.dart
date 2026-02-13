import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:dust_count/shared/strings.dart';
import 'package:dust_count/shared/models/household_category.dart';

/// Shared bottom sheet for creating a custom category.
///
/// Calls [onCategoryCreated] with the new [HouseholdCategory] on submit.
class AddCategorySheet extends StatefulWidget {
  final ValueChanged<HouseholdCategory> onCategoryCreated;

  const AddCategorySheet({
    super.key,
    required this.onCategoryCreated,
  });

  @override
  State<AddCategorySheet> createState() => _AddCategorySheetState();
}

class _AddCategorySheetState extends State<AddCategorySheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emojiController = TextEditingController();
  String? _selectedEmoji;
  int? _selectedColorValue;

  static const List<Color> availableColors = [
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

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedEmoji == null || _selectedColorValue == null) return;

    final category = HouseholdCategory(
      id: const Uuid().v4(),
      labelFr: _nameController.text.trim(),
      iconCodePoint: 0xe88a, // fallback Icons.home codepoint
      colorValue: _selectedColorValue!,
      emoji: _selectedEmoji,
    );

    widget.onCategoryCreated(category);
    Navigator.of(context).pop();
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
                        if (value.isNotEmpty) {
                          final chars = value.characters.first;
                          setState(() => _selectedEmoji = chars);
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
                children: availableColors.map((color) {
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
                onPressed:
                    _selectedEmoji != null && _selectedColorValue != null
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
