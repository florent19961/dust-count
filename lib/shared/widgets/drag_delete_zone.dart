import 'package:flutter/material.dart';
import 'package:dust_count/shared/models/household.dart';
import 'package:dust_count/shared/strings.dart';

/// A drag target zone that appears at the bottom of the screen during drag
/// operations. When a [PredefinedTask] is dropped on it, [onDelete] is called.
class DragDeleteZone extends StatelessWidget {
  final ValueChanged<PredefinedTask> onDelete;

  const DragDeleteZone({super.key, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: DragTarget<PredefinedTask>(
        onWillAcceptWithDetails: (_) => true,
        onAcceptWithDetails: (details) => onDelete(details.data),
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
}
