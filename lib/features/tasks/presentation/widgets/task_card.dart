import 'package:flutter/material.dart';
import 'package:dust_count/shared/models/task_log.dart';
import 'package:dust_count/shared/models/household.dart';
import 'package:dust_count/shared/widgets/difficulty_badge.dart';
import 'package:dust_count/app/theme/app_colors.dart';
import 'package:dust_count/shared/strings.dart';
import 'package:dust_count/core/constants/app_constants.dart';
import 'package:dust_count/shared/utils/string_helpers.dart';
import 'package:dust_count/shared/utils/member_helpers.dart' as member_helpers;

/// Reusable card widget for displaying task log in a list
class TaskCard extends StatelessWidget {
  /// Task log to display
  final TaskLog taskLog;

  /// Optional household for member color coding
  final Household? household;

  /// Callback when card is tapped
  final VoidCallback? onTap;

  const TaskCard({
    required this.taskLog,
    this.household,
    this.onTap,
    super.key,
  });

  /// Get color for member based on stable colorIndex
  Color _getMemberColor() {
    if (household == null) {
      return AppColors.memberColors[0];
    }
    return member_helpers.getMemberColor(household!, taskLog.performedBy);
  }

  /// Category color map for left border (hardcoded dark colors for built-in categories)
  static const _categoryColorMap = <String, Color>{
    'cuisine': Color(0xFFC62828), // Dark red
    'menage': Color(0xFF1565C0), // Dark blue
    'linge': Color(0xFF6A1B9A), // Dark purple
    'courses': Color(0xFFF57F17), // Dark yellow
    'divers': Color(0xFF00695C), // Teal dark
    AppConstants.archivedCategoryId: Color(0xFF938F99), // Gray
  };

  /// Get category color for left border
  Color get _categoryColor {
    return _categoryColorMap[taskLog.categoryId] ?? const Color(0xFF938F99);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: _categoryColor,
                width: 4,
              ),
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Member avatar with initials
                CircleAvatar(
                  radius: 20,
                  backgroundColor: _getMemberColor(),
                  child: Text(
                    getInitials(taskLog.performedByName),
                    style: TextStyle(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Task info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Task name
                      Text(
                        taskLog.taskName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      // Performer, time, and personal badge
                      Row(
                        children: [
                          Text(
                            taskLog.performedByName,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            ' • ${S.formatTime(taskLog.date)}',
                            style: TextStyle(
                              fontSize: 13,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          if (taskLog.isPersonal) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                S.personalTaskBadge,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Duration and difficulty
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Duration badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${taskLog.durationMinutes}min',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Difficulty badge
                    DifficultyBadge(
                      difficulty: taskLog.difficulty,
                      compact: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
