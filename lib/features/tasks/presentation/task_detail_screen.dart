import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dust_count/shared/strings.dart';
import 'package:go_router/go_router.dart';
import 'package:dust_count/app/router.dart';
import 'package:dust_count/shared/models/task_log.dart';
import 'package:dust_count/shared/models/household.dart';
import 'package:dust_count/shared/widgets/difficulty_badge.dart';
import 'package:dust_count/shared/widgets/category_chip.dart';
import 'package:dust_count/shared/utils/category_helpers.dart';
import 'package:dust_count/features/tasks/domain/task_providers.dart';
import 'package:dust_count/features/dashboard/domain/dashboard_providers.dart';
import 'package:dust_count/shared/utils/string_helpers.dart';
import 'package:dust_count/shared/utils/member_helpers.dart' as member_helpers;

/// Screen displaying full details of a single task log
class TaskDetailScreen extends ConsumerStatefulWidget {
  /// Task log to display
  final TaskLog taskLog;

  /// Household for context
  final Household household;

  const TaskDetailScreen({
    required this.taskLog,
    required this.household,
    super.key,
  });

  @override
  ConsumerState<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends ConsumerState<TaskDetailScreen> {
  late TaskLog _taskLog;

  @override
  void initState() {
    super.initState();
    _taskLog = widget.taskLog;
  }

  /// Get color for member based on stable colorIndex
  Color _getMemberColor() {
    return member_helpers.getMemberColor(widget.household, _taskLog.performedBy);
  }

  /// Show delete confirmation dialog
  Future<void> _showDeleteDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(S.deleteTask),
          content: Text(S.deleteTaskConfirmation),
          actions: [
            TextButton(
              onPressed: () => context.pop(false),
              child: Text(S.cancel),
            ),
            FilledButton(
              onPressed: () => context.pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              child: Text(S.delete),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      final controller = ref.read(taskControllerProvider.notifier);
      await controller.deleteTask(widget.household.id, _taskLog.id);

      final state = ref.read(taskControllerProvider);
      state.when(
        data: (_) {
          if (mounted) {
            invalidateDashboardProviders(ref);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(S.taskDeletedSuccess),
                backgroundColor: Theme.of(context).colorScheme.primary,
              ),
            );
            context.pop();
          }
        },
        loading: () {},
        error: (error, _) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(S.taskDeletedError(error.toString())),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        },
      );
    }
  }

  void _navigateToEdit() {
    context
        .push(
          AppRoutes.taskEdit(widget.household.id, _taskLog.id),
          extra: {'task': _taskLog, 'household': widget.household},
        )
        .then((result) {
      if (result is TaskLog) {
        setState(() {
          _taskLog = result;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.taskDetails),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: _navigateToEdit,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _showDeleteDialog,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Task name (large)
            Text(
              _taskLog.taskName,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            // Personal task badge
            if (_taskLog.isPersonal) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 16,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      S.personalTask,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Performer section
            _buildInfoCard(
              context,
              icon: Icons.person,
              label: S.performedBy,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: _getMemberColor(),
                    child: Text(
                      getInitials(_taskLog.performedByName),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _taskLog.performedByName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Date and time
            _buildInfoCard(
              context,
              icon: Icons.calendar_today,
              label: S.date,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    S.formatDateLong(_taskLog.date),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    S.formatTime(_taskLog.date),
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Duration
            _buildInfoCard(
              context,
              icon: Icons.timer,
              label: S.duration,
              child: Text(
                S.minutesCount(_taskLog.durationMinutes),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Difficulty
            _buildInfoCard(
              context,
              icon: Icons.trending_up,
              label: S.difficulty,
              child: DifficultyBadge(
                difficulty: _taskLog.difficulty,
                compact: false,
              ),
            ),

            const SizedBox(height: 16),

            // Category
            _buildInfoCard(
              context,
              icon: Icons.category,
              label: S.category,
              child: CategoryChip(
                category: findCategory(_taskLog.categoryId, widget.household.customCategories) ?? builtInCategories.last,
                compact: false,
              ),
            ),

            const SizedBox(height: 32),

            // Created at timestamp
            Center(
              child: Text(
                S.createdAt(
                  '${S.formatDateLong(_taskLog.createdAt)} ${S.formatTime(_taskLog.createdAt)}',
                ),
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build info card with icon and label
  Widget _buildInfoCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
