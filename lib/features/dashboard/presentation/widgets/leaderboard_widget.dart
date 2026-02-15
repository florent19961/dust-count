import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dust_count/shared/strings.dart';
import 'package:dust_count/shared/models/household.dart';
import 'package:dust_count/features/dashboard/data/dashboard_repository.dart';
import 'package:dust_count/features/dashboard/presentation/widgets/member_avatar.dart';
import 'package:dust_count/core/constants/app_constants.dart';
import 'package:dust_count/shared/widgets/chart_empty_state.dart';

/// Leaderboard widget showing ranked household members
class LeaderboardWidget extends ConsumerWidget {
  final List<LeaderboardEntry> entries;
  final List<HouseholdMember> members;

  const LeaderboardWidget({
    super.key,
    required this.entries,
    required this.members,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (entries.isEmpty) {
      return const ChartEmptyState(icon: Icons.leaderboard);
    }

    return Column(
      children: entries.asMap().entries.map((entry) {
        final rank = entry.key + 1;
        final leaderboardEntry = entry.value;
        return _LeaderboardRow(
          rank: rank,
          entry: leaderboardEntry,
          members: members,
        );
      }).toList(),
    );
  }
}

/// Individual leaderboard row
class _LeaderboardRow extends StatelessWidget {
  final int rank;
  final LeaderboardEntry entry;
  final List<HouseholdMember> members;

  const _LeaderboardRow({
    required this.rank,
    required this.entry,
    required this.members,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTopThree = rank <= 3;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isTopThree ? 2 : 0,
      color: isTopThree
          ? theme.colorScheme.primaryContainer.withOpacity(0.3)
          : theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Rank with medal emoji for top 3
            SizedBox(
              width: 40,
              child: Text(
                _getRankDisplay(rank),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isTopThree
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withOpacity(0.6),
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: 12),

            // Member avatar
            MemberAvatar(
              displayName: entry.displayName,
              colorIndex: members
                  .where((m) => m.userId == entry.userId)
                  .firstOrNull
                  ?.colorIndex ?? 0,
              size: 48,
            ),
            const SizedBox(width: 16),

            // Member info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Display name
                  Text(
                    entry.displayName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Task count
                  Text(
                    '${entry.taskCount} ${entry.taskCount == 1 ? 'task' : 'tasks'}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Difficulty breakdown
                  _buildDifficultyBreakdown(theme),
                ],
              ),
            ),

            // Total minutes (prominent)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  S.formatMinutes(entry.totalMinutes),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                Text(
                  'total',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Get rank display with medal emoji for top 3
  String _getRankDisplay(int rank) {
    switch (rank) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return '$rank';
    }
  }

  /// Build difficulty breakdown row
  Widget _buildDifficultyBreakdown(ThemeData theme) {
    final breakdown = entry.difficultyBreakdown;

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        for (final d in TaskDifficulty.values)
          if ((breakdown[d] ?? 0) > 0)
            _buildDifficultyChip(
              AppConstants.difficultyEmojis[d]!,
              breakdown[d]!,
              theme,
            ),
      ],
    );
  }

  /// Build individual difficulty chip
  Widget _buildDifficultyChip(
    String emoji,
    int count,
    ThemeData theme,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(width: 4),
          Text(
            '×$count',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

}
