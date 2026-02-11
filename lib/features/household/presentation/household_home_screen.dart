import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dust_count/shared/strings.dart';
import 'package:dust_count/shared/models/household.dart';
import 'package:dust_count/features/tasks/presentation/task_history_screen.dart';
import 'package:dust_count/features/tasks/presentation/task_form_screen.dart';
import 'package:dust_count/features/dashboard/presentation/dashboard_screen.dart';
import 'package:dust_count/features/dashboard/domain/dashboard_providers.dart';
import 'package:dust_count/features/household/domain/household_providers.dart';
import 'package:dust_count/features/household/presentation/household_settings_screen.dart';

/// Main household view with bottom navigation
///
/// 3 tabs (Historique, Dashboard, Paramètres) + FAB for adding tasks via bottom sheet.
class HouseholdHomeScreen extends ConsumerStatefulWidget {
  final String householdId;

  const HouseholdHomeScreen({
    super.key,
    required this.householdId,
  });

  @override
  ConsumerState<HouseholdHomeScreen> createState() =>
      _HouseholdHomeScreenState();
}

class _HouseholdHomeScreenState extends ConsumerState<HouseholdHomeScreen> {
  @override
  void initState() {
    super.initState();
    // Set as current household
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(currentHouseholdIdProvider.notifier).state = widget.householdId;
    });
  }

  void _showAddTaskSheet(Household household) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.85,
          child: TaskFormScreen(
            household: household,
            embedded: true,
            onTaskAdded: () => Navigator.pop(context),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(householdTabIndexProvider);
    final householdAsync = ref.watch(currentHouseholdProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/households'),
          tooltip: S.backToHouseholds,
        ),
        title: householdAsync.when(
          data: (household) => Text(household?.name ?? S.household),
          loading: () => const Text('...'),
          error: (_, __) => Text(S.household),
        ),
      ),
      body: householdAsync.when(
        data: (household) {
          if (household == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64),
                  const SizedBox(height: 16),
                  Text(S.householdNotFound),
                ],
              ),
            );
          }

          return IndexedStack(
            index: currentIndex,
            children: [
              TaskHistoryScreen(household: household, embedded: true),
              DashboardScreen(household: household, embedded: true),
              HouseholdSettingsScreen(
                householdId: widget.householdId,
                embedded: true,
              ),
            ],
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
                S.errorLoadingHousehold,
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
      floatingActionButton: currentIndex < 2
          ? householdAsync.whenOrNull(
              data: (household) {
                if (household == null) return null;
                return FloatingActionButton(
                  onPressed: () => _showAddTaskSheet(household),
                  child: const Icon(Icons.add),
                );
              },
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          ref.read(householdTabIndexProvider.notifier).state = index;
          if (index == 1) {
            ref.invalidate(minutesPerMemberProvider);
            ref.invalidate(dailyCumulativeProvider);
            ref.invalidate(leaderboardProvider);
          }
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.history),
            selectedIcon: const Icon(Icons.history),
            label: S.history,
          ),
          NavigationDestination(
            icon: const Icon(Icons.dashboard_outlined),
            selectedIcon: const Icon(Icons.dashboard),
            label: S.dashboard,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: S.settings,
          ),
        ],
      ),
    );
  }
}
