import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dust_count/shared/strings.dart';
import 'package:dust_count/features/dashboard/data/dashboard_repository.dart';
import 'package:dust_count/features/dashboard/presentation/widgets/member_avatar.dart';
import 'package:dust_count/core/constants/app_constants.dart';

/// Leaderboard widget showing ranked household members
class LeaderboardWidget extends ConsumerWidget {
  final List<LeaderboardEntry> entries;

  const LeaderboardWidget({
    super.key,
    required this.entries,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    if (entries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.leaderboard,
                size: 64,
                color: theme.colorScheme.onSurface.withOpacity(0.3),
              ),
              const SizedBox(height: 16),
              Text(
                S.noDataAvailable,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: entries.asMap().entries.map((entry) {
        final rank = entry.key + 1;
        final leaderboardEntry = entry.value;
        return _LeaderboardRow(
          rank: rank,
          entry: leaderboardEntry,
        );
      }).toList(),
    );
  }
}

/// Individual leaderboard row
class _LeaderboardRow extends StatelessWidget {
  final int rank;
  final LeaderboardEntry entry;

  const _LeaderboardRow({
    required this.rank,
    required this.entry,
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
              userId: entry.userId,
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
                  _formatMinutes(entry.totalMinutes),
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
        if (breakdown[TaskDifficulty.plaisir] != null &&
            breakdown[TaskDifficulty.plaisir]! > 0)
          _buildDifficultyChip(
            '😊',
            breakdown[TaskDifficulty.plaisir]!,
            theme,
          ),
        if (breakdown[TaskDifficulty.reloo] != null &&
            breakdown[TaskDifficulty.reloo]! > 0)
          _buildDifficultyChip(
            '😐',
            breakdown[TaskDifficulty.reloo]!,
            theme,
          ),
        if (breakdown[TaskDifficulty.infernal] != null &&
            breakdown[TaskDifficulty.infernal]! > 0)
          _buildDifficultyChip(
            '😩',
            breakdown[TaskDifficulty.infernal]!,
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

  /// Format minutes as "Xh Ym" or "Ym"
  String _formatMinutes(int minutes) {
    if (minutes >= 60) {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      if (remainingMinutes > 0) {
        return '${hours}h ${remainingMinutes}m';
      }
      return '${hours}h';
    }
    return '${minutes}m';
  }
}
