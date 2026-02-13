import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:dust_count/features/auth/data/user_repository.dart';
import 'package:dust_count/features/auth/domain/auth_providers.dart';
import 'package:dust_count/features/tasks/data/task_repository.dart';
import 'package:dust_count/core/constants/app_constants.dart';
import 'package:dust_count/shared/models/household.dart';
import 'package:dust_count/shared/models/household_category.dart';
import 'package:dust_count/features/household/data/household_repository.dart';

/// Result of analyzing a join request before committing
sealed class JoinResult {
  const JoinResult();
}

/// Ready to join directly — no conflicts
class JoinReady extends JoinResult {
  final String householdId;
  const JoinReady(this.householdId);
}

/// Name conflict — another active member already has this displayName
class JoinNameConflict extends JoinResult {
  final String householdId;
  final String conflictingName;
  const JoinNameConflict(this.householdId, this.conflictingName);
}

/// Provider for the active tab index in HouseholdHomeScreen
final householdTabIndexProvider = StateProvider<int>((ref) => 0);

/// Provider for the currently selected household ID
final currentHouseholdIdProvider = StateProvider<String?>((ref) => null);

/// Provider that watches the current household document
final currentHouseholdProvider = StreamProvider<Household?>((ref) {
  final householdId = ref.watch(currentHouseholdIdProvider);
  if (householdId == null) {
    return Stream.value(null);
  }

  final householdRepository = ref.watch(householdRepositoryProvider);
  return householdRepository.watchHousehold(householdId);
});

/// Provider that watches all households for the current user
final userHouseholdsProvider = StreamProvider<List<Household>>((ref) {
  final currentUserAsync = ref.watch(currentUserProvider);

  return currentUserAsync.when(
    data: (user) {
      if (user == null || user.householdIds.isEmpty) {
        return Stream.value([]);
      }

      final householdRepository = ref.watch(householdRepositoryProvider);
      return householdRepository.watchUserHouseholds(user.householdIds);
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

/// Provider that watches member preferences for the current user in a household
final memberPreferencesProvider = StreamProvider.family<MemberPreferences?, String>((ref, householdId) {
  final currentUserAsync = ref.watch(currentUserProvider);
  final user = currentUserAsync.value;
  if (user == null) return Stream.value(null);
  final repo = ref.watch(householdRepositoryProvider);
  return repo.watchMemberPreferences(householdId, user.userId);
});

/// Provider that resolves quick tasks from member preferences or falls back to defaults
final quickTasksProvider = Provider.family<List<PredefinedTask>, String>((ref, householdId) {
  final householdAsync = ref.watch(currentHouseholdProvider);
  final prefsAsync = ref.watch(memberPreferencesProvider(householdId));

  final household = householdAsync.value;
  if (household == null) return [];

  final prefs = prefsAsync.value;
  if (prefs != null && prefs.quickTaskIds.isNotEmpty) {
    final taskMap = {for (final t in household.predefinedTasks) t.id: t};
    return prefs.quickTaskIds
        .where((id) => taskMap.containsKey(id))
        .map((id) => taskMap[id]!)
        .toList();
  }

  // Fallback: first 8 tasks matching AppConstants order
  final quickNames = AppConstants.predefinedTasks
      .take(AppConstants.quickTaskCount)
      .map((t) => t['nameFr'] as String)
      .toSet();
  return household.predefinedTasks
      .where((t) => quickNames.contains(t.nameFr))
      .take(8)
      .toList();
});

/// Controller for household operations
final householdControllerProvider =
    StateNotifierProvider<HouseholdController, AsyncValue<void>>((ref) {
  return HouseholdController(ref);
});

/// State notifier for managing household operations
class HouseholdController extends StateNotifier<AsyncValue<void>> {
  HouseholdController(this.ref) : super(const AsyncValue.data(null));

  final Ref ref;

  /// Creates a new household and sets it as the current household
  Future<void> createHousehold(String name) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final currentUserAsync = ref.read(currentUserProvider);
      final user = currentUserAsync.value;

      if (user == null) {
        throw Exception('User not authenticated');
      }

      final householdRepository = ref.read(householdRepositoryProvider);
      final userRepository = ref.read(userRepositoryProvider);

      // Create the household
      final householdId = await householdRepository.createHousehold(
        name: name,
        creatorId: user.userId,
        creatorName: user.displayName,
      );

      // Add household to user's household list
      await userRepository.addHouseholdToUser(user.userId, householdId);

      // Set as current household
      ref.read(currentHouseholdIdProvider.notifier).state = householdId;
    });
  }

  /// Analyzes a join request and returns the appropriate result
  ///
  /// Does NOT perform the actual join — call [confirmJoin] to commit.
  Future<JoinResult> analyzeJoin(String inviteCode) async {
    final currentUserAsync = ref.read(currentUserProvider);
    final user = currentUserAsync.value;

    if (user == null) {
      throw Exception('User not authenticated');
    }

    final householdRepository = ref.read(householdRepositoryProvider);

    // Find household by invite code
    final household = await householdRepository.findByInviteCode(inviteCode);
    if (household == null) {
      throw Exception('Household not found with this invite code');
    }

    // Check if user is already a member
    if (household.memberIds.contains(user.userId)) {
      throw Exception('You are already a member of this household');
    }

    // Check name conflict with active members
    final nameConflict = household.members
        .any((m) => m.displayName == user.displayName);

    if (nameConflict) {
      return JoinNameConflict(household.id, user.displayName);
    }

    return JoinReady(household.id);
  }

  /// Checks if the user was a previous member of this household
  ///
  /// Called AFTER join — returns the previous display name if different
  /// from the current one, or null if the user is new or kept the same name.
  Future<String?> checkReturningMember(String householdId) async {
    final user = ref.read(currentUserProvider).value;
    if (user == null) return null;

    final taskRepo = ref.read(taskRepositoryProvider);
    final (hasLogs, previousName) =
        await taskRepo.hasTasksFromUser(householdId, user.userId);

    if (hasLogs && previousName != null && previousName != user.displayName) {
      return previousName;
    }
    return null;
  }

  /// Commits the join with a chosen display name.
  ///
  /// Returns the household ID on success. The caller is responsible for
  /// setting [currentHouseholdIdProvider] — doing it here would trigger
  /// snapshot listeners before Firestore propagates the member write,
  /// causing permission-denied errors.
  Future<String?> confirmJoin(String inviteCode, String displayName) async {
    String? joinedHouseholdId;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final currentUserAsync = ref.read(currentUserProvider);
      final user = currentUserAsync.value;

      if (user == null) {
        throw Exception('User not authenticated');
      }

      final householdRepository = ref.read(householdRepositoryProvider);
      final userRepository = ref.read(userRepositoryProvider);

      // Re-fetch household for fresh data
      final household = await householdRepository.findByInviteCode(inviteCode);
      if (household == null) {
        throw Exception('Household not found with this invite code');
      }

      if (household.memberIds.contains(user.userId)) {
        throw Exception('You are already a member of this household');
      }

      // Add user as member to household
      await householdRepository.addMember(
        household.id,
        user.userId,
        displayName,
        currentMemberIds: household.memberIds,
        currentMembers: household.members,
      );

      // Add household to user's household list
      await userRepository.addHouseholdToUser(user.userId, household.id);

      joinedHouseholdId = household.id;
    });
    return joinedHouseholdId;
  }

  /// Leaves a household
  Future<void> leaveHousehold(String householdId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final currentUserAsync = ref.read(currentUserProvider);
      final user = currentUserAsync.value;

      if (user == null) {
        throw Exception('User not authenticated');
      }

      final householdRepository = ref.read(householdRepositoryProvider);
      final userRepository = ref.read(userRepositoryProvider);

      // Remove user from household
      await householdRepository.removeMember(householdId, user.userId);

      // Remove household from user's household list
      await userRepository.removeHouseholdFromUser(user.userId, householdId);

      // If this was the current household, clear it
      final currentHouseholdId = ref.read(currentHouseholdIdProvider);
      if (currentHouseholdId == householdId) {
        ref.read(currentHouseholdIdProvider.notifier).state = null;
      }

      // Check if household is now empty and delete it
      final household = await householdRepository.getHousehold(householdId);
      if (household != null && household.memberIds.isEmpty) {
        await householdRepository.deleteHousehold(householdId);
      }
    });
  }

  /// Shares the invite link for a household
  Future<void> shareInviteLink(String householdId) async {
    try {
      final householdRepository = ref.read(householdRepositoryProvider);
      final household = await householdRepository.getHousehold(householdId);

      if (household == null) {
        throw Exception('Household not found');
      }

      // Share invite code with share_plus
      await Share.share(
        'Join my household "${household.name}" on DustCount!\n\n'
        'Invite code: ${household.inviteCode}\n\n'
        'Download the app and enter this code to join.',
        subject: 'Join ${household.name} on DustCount',
      );
    } catch (e) {
      throw Exception('Failed to share invite link: ${e.toString()}');
    }
  }

  /// Updates the household name
  Future<void> updateHouseholdName(
    String householdId,
    String newName,
  ) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final householdRepository = ref.read(householdRepositoryProvider);
      await householdRepository.updateHouseholdName(householdId, newName);
    });
  }

  /// Updates predefined tasks for a household
  Future<void> updatePredefinedTasks(
    String householdId,
    List<PredefinedTask> tasks,
  ) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final householdRepository = ref.read(householdRepositoryProvider);
      await householdRepository.updatePredefinedTasks(householdId, tasks);
    });
  }

  /// Adds a predefined task to a household
  Future<void> addPredefinedTask(String householdId, PredefinedTask task) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(householdRepositoryProvider);
      await repo.addPredefinedTask(householdId, task);
    });
  }

  /// Deletes a predefined task, migrating associated logs to archivees category
  Future<void> deletePredefinedTask(String householdId, PredefinedTask task) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final taskRepo = ref.read(taskRepositoryProvider);
      await taskRepo.migrateTaskLogsCategory(householdId, task.nameFr);
      final repo = ref.read(householdRepositoryProvider);
      await repo.removePredefinedTask(householdId, task);
    });
  }

  /// Edits a predefined task, renaming task logs if the name changed
  Future<void> editPredefinedTask(
    String householdId,
    PredefinedTask oldTask,
    PredefinedTask updatedTask,
  ) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      if (oldTask.nameFr != updatedTask.nameFr) {
        final taskRepo = ref.read(taskRepositoryProvider);
        await taskRepo.renameTaskLogs(
          householdId,
          oldTask.nameFr,
          updatedTask.nameFr,
          updatedTask.nameEn,
        );
      }
      if (oldTask.categoryId != updatedTask.categoryId) {
        final taskRepo = ref.read(taskRepositoryProvider);
        await taskRepo.migrateTaskLogsCategory(
          householdId, updatedTask.nameFr,
          targetCategoryId: updatedTask.categoryId,
        );
      }
      final repo = ref.read(householdRepositoryProvider);
      await repo.updatePredefinedTask(householdId, updatedTask);
    });
  }

  /// Updates the quick task IDs for the current user
  Future<void> updateQuickTaskIds(String householdId, List<String> quickTaskIds) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final currentUserAsync = ref.read(currentUserProvider);
      final user = currentUserAsync.value;
      if (user == null) throw Exception('User not authenticated');
      final repo = ref.read(householdRepositoryProvider);
      await repo.updateQuickTaskIds(householdId, user.userId, quickTaskIds);
    });
  }

  /// Adds a custom category to a household
  Future<void> addCustomCategory(String householdId, HouseholdCategory category) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(householdRepositoryProvider);
      await repo.addCustomCategory(householdId, category);
    });
  }

  /// Deletes an empty custom category from a household
  Future<void> deleteCustomCategory(String householdId, String categoryId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(householdRepositoryProvider);
      await repo.removeCustomCategory(householdId, categoryId);
    });
  }
}
