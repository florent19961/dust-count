import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dust_count/shared/strings.dart';
import '../domain/household_providers.dart';
import 'widgets/household_card.dart';

/// Main screen showing all households the user belongs to
class HouseholdListScreen extends ConsumerWidget {
  const HouseholdListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userHouseholdsAsync = ref.watch(userHouseholdsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(S.myHouseholds),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.push('/profile'),
            tooltip: S.profile,
          ),
        ],
      ),
      body: userHouseholdsAsync.when(
        data: (households) {
          if (households.isEmpty) {
            return _buildEmptyState(context);
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(userHouseholdsProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: households.length,
              itemBuilder: (context, index) {
                final household = households[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: HouseholdCard(
                    household: household,
                    onTap: () {
                      // Set as current household and navigate
                      ref.read(currentHouseholdIdProvider.notifier).state =
                          household.id;
                      context.push('/household/${household.id}');
                    },
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => Center(
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
                S.errorLoadingHouseholds,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: userHouseholdsAsync.whenOrNull(
        data: (households) {
          if (households.isEmpty) return null;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton.extended(
                heroTag: 'create',
                onPressed: () => context.push('/households/create'),
                icon: const Icon(Icons.add),
                label: Text(S.createHousehold),
              ),
              const SizedBox(height: 12),
              FloatingActionButton.extended(
                heroTag: 'join',
                onPressed: () => context.push('/households/join'),
                icon: const Icon(Icons.group_add),
                label: Text(S.joinHousehold),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.home_outlined,
              size: 120,
              color: theme.colorScheme.primary.withOpacity(0.3),
            ),
            const SizedBox(height: 24),
            Text(
              S.noHouseholds,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              S.noHouseholdsDescription,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => context.push('/households/create'),
              icon: const Icon(Icons.add),
              label: Text(S.createYourFirstHousehold),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => context.push('/households/join'),
              icon: const Icon(Icons.group_add),
              label: Text(S.orJoinExisting),
            ),
          ],
        ),
      ),
    );
  }
}
