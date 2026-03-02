import 'package:flutter/material.dart';
import 'package:dust_count/shared/strings.dart';
import 'package:dust_count/shared/models/household.dart';
import 'package:dust_count/app/theme/app_colors.dart';
import 'package:dust_count/features/dashboard/data/dashboard_repository.dart';

/// Matrix table showing total duration per task per member
class TaskMemberMatrix extends StatefulWidget {
  final List<TaskMemberMatrixEntry> entries;
  final List<HouseholdMember> members;

  const TaskMemberMatrix({
    super.key,
    required this.entries,
    required this.members,
  });

  @override
  State<TaskMemberMatrix> createState() => _TaskMemberMatrixState();
}

class _TaskMemberMatrixState extends State<TaskMemberMatrix> {
  int _topCount = 10;

  static const List<int> _topOptions = [5, 10, 15, 20, 30];

  @override
  Widget build(BuildContext context) {
    if (widget.entries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            S.noDataForPeriod,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    final theme = Theme.of(context);
    final displayEntries = widget.entries.take(_topCount).toList();

    // Collect all member IDs present in the displayed data
    final memberIdsInData = <String>{};
    for (final entry in displayEntries) {
      memberIdsInData.addAll(entry.minutesPerMember.keys);
    }

    // Only show members who have data, ordered by household member list
    final visibleMembers = widget.members
        .where((m) => memberIdsInData.contains(m.userId))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top selector
        Row(
          children: [
            Text(
              S.topTasks,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 8),
            DropdownButton<int>(
              value: _topCount,
              isDense: true,
              underline: const SizedBox.shrink(),
              items: _topOptions.map((n) {
                return DropdownMenuItem<int>(
                  value: n,
                  child: Text('$n'),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _topCount = value);
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Scrollable table
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columnSpacing: 16,
            horizontalMargin: 8,
            headingRowHeight: 48,
            dataRowMinHeight: 40,
            dataRowMaxHeight: 40,
            columns: [
              DataColumn(
                label: Text(
                  S.taskColumn,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              ...visibleMembers.map((member) {
                final memberColor =
                    AppColors.getMemberColor(member.colorIndex);
                return DataColumn(
                  label: Text(
                    member.displayName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: memberColor,
                    ),
                  ),
                );
              }),
            ],
            rows: displayEntries.map((entry) {
              return DataRow(
                cells: [
                  DataCell(
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 160),
                      child: Text(
                        entry.taskName,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  ...visibleMembers.map((member) {
                    final minutes =
                        entry.minutesPerMember[member.userId] ?? 0;
                    return DataCell(
                      Text(
                        S.formatDurationHHmm(minutes),
                        style: TextStyle(
                          color: minutes > 0
                              ? theme.colorScheme.onSurface
                              : theme.colorScheme.onSurfaceVariant
                                  .withOpacity(0.4),
                        ),
                      ),
                    );
                  }),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
