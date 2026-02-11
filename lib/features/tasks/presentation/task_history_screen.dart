import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dust_count/shared/strings.dart';
import 'package:go_router/go_router.dart';
import 'package:dust_count/shared/models/task_log.dart';
import 'package:dust_count/shared/models/household.dart';
import 'package:dust_count/features/tasks/domain/task_providers.dart';
import 'package:dust_count/features/tasks/presentation/widgets/task_card.dart';
import 'package:dust_count/features/tasks/presentation/widgets/period_filter.dart';
import 'package:dust_count/core/extensions/date_extensions.dart';

/// Screen displaying chronological list of task logs
class TaskHistoryScreen extends ConsumerWidget {
  /// Current household
  final Household household;

  /// When true, renders without Scaffold/AppBar/FAB (for embedding in tabs)
  final bool embedded;

  const TaskHistoryScreen({
    required this.household,
    this.embedded = false,
    super.key,
  });

  /// Group tasks by date
  Map<DateTime, List<TaskLog>> _groupTasksByDate(List<TaskLog> tasks) {
    final grouped = <DateTime, List<TaskLog>>{};

    for (final task in tasks) {
      final dateKey = task.date.startOfDay;
      grouped.putIfAbsent(dateKey, () => []).add(task);
    }

    return grouped;
  }

  /// Format date header
  String _formatDateHeader(DateTime date, BuildContext context) {
    final now = DateTime.now();

    if (date.isSameDay(now)) {
      return S.today;
    } else if (date.isSameDay(now.subtract(const Duration(days: 1)))) {
      return S.yesterday;
    } else {
      return S.formatDateLong(date);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taskLogsAsync = ref.watch(filteredTaskLogsProvider);

    final filterSliver = SliverToBoxAdapter(
      child: PeriodFilter(
        members: household.members,
        customCategories: household.customCategories,
        predefinedTasks: household.predefinedTasks,
        showTaskFilter: true,
      ),
    );

    final content = taskLogsAsync.when(
      data: (tasks) {
        if (tasks.isEmpty) {
          return CustomScrollView(
            slivers: [
              filterSliver,
              SliverFillRemaining(
                child: _buildEmptyState(context),
              ),
            ],
          );
        }

        final groupedTasks = _groupTasksByDate(tasks);
        final sortedDates = groupedTasks.keys.toList()
          ..sort((a, b) => b.compareTo(a));

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(filteredTaskLogsProvider);
            await Future.delayed(const Duration(milliseconds: 500));
          },
          child: CustomScrollView(
            slivers: [
              filterSliver,
              SliverPadding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final date = sortedDates[index];
                      final tasksForDate = groupedTasks[date]!;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding:
                                const EdgeInsets.fromLTRB(16, 16, 16, 8),
                            child: Text(
                              _formatDateHeader(date, context),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface,
                              ),
                            ),
                          ),
                          ...tasksForDate.map((task) {
                            return TaskCard(
                              taskLog: task,
                              household: household,
                              onTap: () {
                                context.push(
                                  '/household/${household.id}/task/${task.id}',
                                  extra: {
                                    'task': task,
                                    'household': household,
                                  },
                                );
                              },
                            );
                          }),
                        ],
                      );
                    },
                    childCount: sortedDates.length,
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => CustomScrollView(
        slivers: [
          filterSliver,
          const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          ),
        ],
      ),
      error: (error, stack) => CustomScrollView(
        slivers: [
          filterSliver,
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    S.errorLoadingTasks,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error.toString(),
                    style: TextStyle(
                      fontSize: 14,
                      color:
                          Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () {
                      ref.invalidate(filteredTaskLogsProvider);
                    },
                    icon: const Icon(Icons.refresh),
                    label: Text(S.retry),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    if (embedded) {
      return content;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(S.taskHistory),
      ),
      body: content,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.push('/tasks/add', extra: household);
        },
        icon: const Icon(Icons.add),
        label: Text(S.addTask),
      ),
    );
  }

  /// Build empty state widget
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.task_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            S.noTasksYet,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            S.addFirstTask,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
