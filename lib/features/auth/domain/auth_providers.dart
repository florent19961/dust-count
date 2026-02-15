import 'package:dust_count/features/auth/data/auth_repository.dart';
import 'package:dust_count/features/auth/data/user_repository.dart';
import 'package:dust_count/features/household/data/household_repository.dart';
import 'package:dust_count/features/tasks/data/task_repository.dart';
import 'package:dust_count/shared/exceptions/name_conflict_exception.dart';
import 'package:dust_count/shared/models/app_user.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authStateProvider = StreamProvider<User?>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return authRepository.authStateChanges();
});

final currentUserProvider = StreamProvider<AppUser?>((ref) {
  final authState = ref.watch(authStateProvider);
  final userRepository = ref.watch(userRepositoryProvider);

  return authState.when(
    data: (firebaseUser) {
      if (firebaseUser == null) {
        return Stream.value(null);
      }
      return userRepository.watchUser(firebaseUser.uid);
    },
    loading: () => Stream.value(null),
    error: (_, __) => Stream.value(null),
  );
});

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
  return AuthController(ref);
});

class AuthController extends StateNotifier<AsyncValue<void>> {
  AuthController(this.ref) : super(const AsyncValue.data(null));

  final Ref ref;

  Future<void> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final authRepository = ref.read(authRepositoryProvider);
      final userRepository = ref.read(userRepositoryProvider);

      final userCredential = await authRepository.signUp(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        throw Exception('Échec de la création du compte');
      }

      await authRepository.updateDisplayName(displayName);

      final appUser = AppUser(
        userId: userCredential.user!.uid,
        email: email,
        displayName: displayName,
        householdIds: [],
        createdAt: DateTime.now(),
        locale: 'en',
      );

      await userRepository.createUser(appUser);
    });
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final authRepository = ref.read(authRepositoryProvider);
      await authRepository.signIn(email: email, password: password);
    });
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final authRepository = ref.read(authRepositoryProvider);
      await authRepository.signOut();
    });
  }

  /// Updates the display name across Firebase Auth, Firestore user doc,
  /// and all household member entries.
  Future<void> updateDisplayName(String newName) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final authRepository = ref.read(authRepositoryProvider);
      final userRepository = ref.read(userRepositoryProvider);
      final householdRepository = ref.read(householdRepositoryProvider);

      final currentUserAsync = ref.read(currentUserProvider);
      final user = currentUserAsync.value;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // 0. Check name uniqueness across all households
      for (final householdId in user.householdIds) {
        final household = await householdRepository.getHousehold(householdId);
        if (household == null) continue;
        final conflict = household.members.any(
          (m) => m.userId != user.userId && m.displayName == newName,
        );
        if (conflict) {
          throw NameConflictException(household.name);
        }
      }

      // 1. Firebase Auth
      await authRepository.updateDisplayName(newName);

      // 2. Firestore users/{uid}
      await userRepository.updateDisplayName(user.userId, newName);

      // 3. Firestore households.members for each household
      for (final householdId in user.householdIds) {
        await householdRepository.updateMemberDisplayName(
          householdId,
          user.userId,
          newName,
        );
      }

      // 4. Update performedByName in task logs for each household
      final taskRepository = ref.read(taskRepositoryProvider);
      for (final householdId in user.householdIds) {
        await taskRepository.updatePerformedByName(
          householdId,
          user.userId,
          newName,
        );
      }
    });
  }

  Future<void> deleteAccount(String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final authRepository = ref.read(authRepositoryProvider);
      final userRepository = ref.read(userRepositoryProvider);
      final householdRepository = ref.read(householdRepositoryProvider);
      final taskRepository = ref.read(taskRepositoryProvider);

      final currentUserAsync = ref.read(currentUserProvider);
      final user = currentUserAsync.value;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // 1. Reauthenticate
      await authRepository.reauthenticate(password);

      // 2. For each household: anonymize logs, delete prefs, remove member
      for (final householdId in user.householdIds) {
        await taskRepository.anonymizeUserTaskLogs(householdId, user.userId);
        await householdRepository.deleteMemberPreferences(householdId, user.userId);
        await householdRepository.removeMember(householdId, user.userId);
      }

      // 3. Delete Firestore user document
      await userRepository.deleteUser(user.userId);

      // 4. Delete Firebase Auth user (last — irreversible)
      await authRepository.deleteAuthUser();
    });
  }

  Future<void> resetPassword({required String email}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final authRepository = ref.read(authRepositoryProvider);
      await authRepository.resetPassword(email: email);
    });
  }
}
