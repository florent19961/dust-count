import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dust_count/shared/strings.dart';
import 'package:dust_count/shared/models/household.dart';
import 'package:dust_count/features/household/domain/household_providers.dart';

/// Settings screen for managing a household
class HouseholdSettingsScreen extends ConsumerWidget {
  final String householdId;

  /// When true, renders without Scaffold/AppBar (for embedding in tabs)
  final bool embedded;

  const HouseholdSettingsScreen({
    super.key,
    required this.householdId,
    this.embedded = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final householdAsync = ref.watch(currentHouseholdProvider);

    Widget body = householdAsync.when(
      data: (household) {
        if (household == null) {
          return Center(
            child: Text(S.householdNotFound),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildPredefinedTasksSection(context, household),
              const SizedBox(height: 24),
              _buildHouseholdNameSection(context, ref, household),
              const SizedBox(height: 24),
              _buildMembersSection(context, household),
              const SizedBox(height: 24),
              _buildInviteSection(context, ref, household),
              const SizedBox(height: 32),
              _buildLeaveButton(context, ref),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (error, stack) => Center(
        child: Text('${S.error}: ${error.toString()}'),
      ),
    );

    if (embedded) {
      return body;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(S.householdSettings),
      ),
      body: body,
    );
  }

  Widget _buildHouseholdNameSection(
    BuildContext context,
    WidgetRef ref,
    Household household,
  ) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.home_outlined, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    S.householdName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  tooltip: S.editHouseholdName,
                  onPressed: () => _showEditHouseholdNameDialog(
                    context,
                    ref,
                    household,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              household.name,
              style: theme.textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditHouseholdNameDialog(
    BuildContext context,
    WidgetRef ref,
    Household household,
  ) async {
    final controller = TextEditingController(text: household.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(S.editHouseholdName),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: S.householdName,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(S.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: Text(S.save),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty && newName != household.name) {
      try {
        await ref
            .read(householdControllerProvider.notifier)
            .updateHouseholdName(household.id, newName);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(S.householdNameUpdated)),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(S.errorUpdatingHouseholdName),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  Widget _buildMembersSection(
    BuildContext context,
    Household household,
  ) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.people,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  S.members,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...household.members.map((member) => _buildMemberItem(
                  context,
                  member,
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberItem(BuildContext context, HouseholdMember member) {
    final theme = Theme.of(context);
    final initials = _getInitials(member.displayName);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Text(
              initials,
              style: TextStyle(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              member.displayName,
              style: theme.textTheme.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInviteSection(
    BuildContext context,
    WidgetRef ref,
    Household household,
  ) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.link,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  S.inviteLink,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      household.inviteCode,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(
                        ClipboardData(text: household.inviteCode),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(S.inviteCodeCopied)),
                      );
                    },
                    icon: const Icon(Icons.copy),
                    label: Text(S.copy),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () async {
                      await ref
                          .read(householdControllerProvider.notifier)
                          .shareInviteLink(household.id);
                    },
                    icon: const Icon(Icons.share),
                    label: Text(S.share),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPredefinedTasksSection(
    BuildContext context,
    Household household,
  ) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/household/${household.id}/settings/tasks'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.task_alt,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      S.predefinedTasks,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            const SizedBox(height: 8),
            Text(
              S.predefinedTasksDescription,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              S.tasksAvailable(household.predefinedTasks.length),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: household.predefinedTasks
                  .take(5)
                  .map((task) => _buildTaskChip(context, task))
                  .toList(),
            ),
            if (household.predefinedTasks.length > 5) ...[
              const SizedBox(height: 8),
              Text(
                S.andMore(household.predefinedTasks.length - 5),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildTaskChip(
    BuildContext context,
    PredefinedTask task,
  ) {
    final theme = Theme.of(context);
    final taskName = _getLocalizedTaskName(task);
    return Chip(
      label: Text(taskName),
      labelStyle: theme.textTheme.bodySmall,
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildLeaveButton(
    BuildContext context,
    WidgetRef ref,
  ) {
    return FilledButton.tonalIcon(
      onPressed: () => _showLeaveConfirmation(context, ref),
      icon: const Icon(Icons.exit_to_app),
      label: Text(S.leaveHousehold),
      style: FilledButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.errorContainer,
        foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
      ),
    );
  }

  Future<void> _showLeaveConfirmation(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(S.leaveHousehold),
        content: Text(S.leaveHouseholdConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(S.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: Text(S.leave),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await ref
            .read(householdControllerProvider.notifier)
            .leaveHousehold(householdId);

        if (context.mounted) {
          context.go('/households');
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${S.errorLeavingHousehold}: ${e.toString()}'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  String _getInitials(String displayName) {
    final parts = displayName.trim().split(' ');
    if (parts.isEmpty) return '?';

    if (parts.length == 1) {
      return parts[0].substring(0, 1).toUpperCase();
    }

    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  String _getLocalizedTaskName(PredefinedTask task) {
    return task.nameFr;
  }

}
