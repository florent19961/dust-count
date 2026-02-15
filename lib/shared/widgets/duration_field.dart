import 'package:flutter/material.dart';
import 'package:dust_count/shared/strings.dart';

/// Reusable duration input with -5 / +5 buttons and validation.
class DurationField extends StatelessWidget {
  final TextEditingController controller;
  final int durationMinutes;
  final ValueChanged<int> onChanged;

  const DurationField({
    super.key,
    required this.controller,
    required this.durationMinutes,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () {
            final current =
                int.tryParse(controller.text) ?? durationMinutes;
            if (current > 5) {
              final newValue = current - 5;
              onChanged(newValue);
              controller.text = newValue.toString();
            }
          },
          icon: const Icon(Icons.remove_circle_outline),
        ),
        Expanded(
          child: TextFormField(
            controller: controller,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            decoration: const InputDecoration(
              suffixText: 'min',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              final parsed = int.tryParse(value);
              if (parsed != null && parsed > 0) {
                onChanged(parsed);
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
                int.tryParse(controller.text) ?? durationMinutes;
            final newValue = current + 5;
            onChanged(newValue);
            controller.text = newValue.toString();
          },
          icon: const Icon(Icons.add_circle_outline),
        ),
      ],
    );
  }
}
