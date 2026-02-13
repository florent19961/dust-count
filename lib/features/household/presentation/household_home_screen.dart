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

  void _showHouseholdSwitcher() {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) {
        return Consumer(
          builder: (context, sheetRef, _) {
            final householdsAsync = sheetRef.watch(userHouseholdsProvider);

            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  Container(
                    width: 32,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        S.myHouseholds,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  householdsAsync.when(
                    data: (households) => Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final h in households)
                          ListTile(
                            leading: Icon(
                              Icons.home,
                              color: h.id == widget.householdId
                                  ? Theme.of(context).colorScheme.primary
                                  : null,
                            ),
                            title: Text(
                              h.name,
                              style: h.id == widget.householdId
                                  ? TextStyle(
                                      color: Theme.of(context).colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    )
                                  : null,
                            ),
                            subtitle: Text(S.memberCount(h.memberIds.length)),
                            trailing: h.id == widget.householdId
                                ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                                : null,
                            onTap: () {
                              Navigator.pop(sheetContext);
                              if (h.id != widget.householdId) {
                                ref.read(currentHouseholdIdProvider.notifier).state = h.id;
                                context.go('/household/${h.id}');
                              }
                            },
                          ),
                      ],
                    ),
                    loading: () => const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (_, __) => Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(S.errorLoadingHouseholds),
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.add),
                    title: Text(S.createHousehold),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      context.push('/households/create');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.group_add),
                    title: Text(S.joinHousehold),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      context.push('/households/join');
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAddTaskSheet(Household household) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: S.close,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          )),
          child: child,
        );
      },
      pageBuilder: (context, animation, secondaryAnimation) {
        final bottomPadding = MediaQuery.of(context).padding.bottom;
        return Align(
          alignment: Alignment.bottomCenter,
          child: Material(
            elevation: 8,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(16),
            ),
            clipBehavior: Clip.antiAlias,
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.85,
              width: double.infinity,
              child: Padding(
                padding: EdgeInsets.only(bottom: bottomPadding),
                child: TaskFormScreen(
                  household: household,
                  embedded: true,
                  onTaskAdded: () => Navigator.pop(context),
                ),
              ),
            ),
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
        automaticallyImplyLeading: false,
        title: GestureDetector(
          onTap: _showHouseholdSwitcher,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: householdAsync.when(
                  data: (household) => Text(
                    household?.name ?? S.household,
                    overflow: TextOverflow.ellipsis,
                  ),
                  loading: () => const Text('...'),
                  error: (_, __) => Text(S.household),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.expand_more),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.push('/profile'),
            tooltip: S.profile,
          ),
        ],
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
