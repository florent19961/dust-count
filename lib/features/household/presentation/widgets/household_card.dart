import 'package:flutter/material.dart';
import 'package:dust_count/shared/models/household.dart';
import 'package:dust_count/shared/utils/string_helpers.dart';

/// Reusable card widget for displaying household information
class HouseholdCard extends StatelessWidget {
  final Household household;
  final VoidCallback onTap;

  const HouseholdCard({
    super.key,
    required this.household,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final memberCount = household.members.length;

    return Card(
      elevation: 2,
      shadowColor: Theme.of(context).shadowColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Household name
              Text(
                household.name,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              // Member count
              Row(
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 20,
                    color: theme.colorScheme.secondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$memberCount ${memberCount == 1 ? 'member' : 'members'}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Member avatars
              _buildMemberAvatars(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMemberAvatars(ThemeData theme) {
    const int maxVisibleAvatars = 5;
    final visibleMembers = household.members.take(maxVisibleAvatars).toList();
    final overflowCount = household.members.length - maxVisibleAvatars;

    return SizedBox(
      height: 36,
      child: Stack(
        children: [
          // Display visible member avatars
          ...List.generate(
            visibleMembers.length,
            (index) => Positioned(
              left: index * 28.0,
              child: _buildAvatar(
                visibleMembers[index].displayName,
                theme,
              ),
            ),
          ),

          // Display overflow count
          if (overflowCount > 0)
            Positioned(
              left: visibleMembers.length * 28.0,
              child: _buildOverflowAvatar(overflowCount, theme),
            ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String displayName, ThemeData theme) {
    final initials = getInitials(displayName);

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        shape: BoxShape.circle,
        border: Border.all(
          color: theme.colorScheme.surface,
          width: 2,
        ),
      ),
      child: Center(
        child: Text(
          initials,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildOverflowAvatar(int count, ThemeData theme) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        shape: BoxShape.circle,
        border: Border.all(
          color: theme.colorScheme.surface,
          width: 2,
        ),
      ),
      child: Center(
        child: Text(
          '+$count',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSecondaryContainer,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

}
