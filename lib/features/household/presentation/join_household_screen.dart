import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dust_count/app/router.dart';
import 'package:dust_count/shared/strings.dart';
import 'package:dust_count/features/auth/domain/auth_providers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dust_count/features/household/data/household_repository.dart';
import 'package:dust_count/features/household/domain/household_providers.dart';
import 'package:dust_count/features/tasks/data/task_repository.dart';

/// Screen for joining a household using an invite code
class JoinHouseholdScreen extends ConsumerStatefulWidget {
  final String? inviteCode;

  const JoinHouseholdScreen({
    super.key,
    this.inviteCode,
  });

  @override
  ConsumerState<JoinHouseholdScreen> createState() =>
      _JoinHouseholdScreenState();
}

class _JoinHouseholdScreenState extends ConsumerState<JoinHouseholdScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _codeController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController(text: widget.inviteCode ?? '');
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _joinHousehold() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final inviteCode = _codeController.text.trim();
      final controller = ref.read(householdControllerProvider.notifier);
      final result = await controller.analyzeJoin(inviteCode);

      if (!mounted) return;

      switch (result) {
        case JoinReady():
          await _doJoin(inviteCode, null);
        case JoinNameConflict(:final conflictingName):
          await _showNameConflictDialog(inviteCode, conflictingName);
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${S.errorJoiningHousehold}: ${e.toString()}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Perform the actual join and navigate
  Future<void> _doJoin(String inviteCode, String? displayName) async {
    final controller = ref.read(householdControllerProvider.notifier);

    final String? householdId;
    if (displayName != null) {
      householdId = await controller.confirmJoin(inviteCode, displayName);
    } else {
      // Use the user's current displayName
      final user = ref.read(currentUserProvider).value;
      if (user == null) throw Exception('User not authenticated');
      householdId = await controller.confirmJoin(inviteCode, user.displayName);
    }

    if (!mounted) return;

    if (householdId == null) {
      context.go(AppRoutes.households);
      return;
    }

    // Post-join: check if returning member with a different name
    try {
      final previousName = await controller.checkReturningMember(householdId);
      if (!mounted) return;

      if (previousName != null) {
        await _showReturningMemberDialog(householdId, previousName);
      }
    } catch (_) {
      // Non-blocking — index might not be deployed yet
    }

    if (!mounted) return;

    // Attendre que Firestore ait propagé le memberIds avant de naviguer,
    // sinon les listeners déclenchés par currentHouseholdIdProvider
    // peuvent recevoir permission-denied.
    final householdRepo = ref.read(householdRepositoryProvider);
    final user = ref.read(currentUserProvider).value;
    if (user != null) {
      await _waitForMembership(householdRepo, householdId, user.userId);
    }

    if (!mounted) return;

    ref.read(currentHouseholdIdProvider.notifier).state = householdId;
    context.go(AppRoutes.household(householdId));
  }

  /// Post-join dialog for returning members — propose renaming back
  Future<void> _showReturningMemberDialog(
    String householdId,
    String previousName,
  ) async {
    final renameController = TextEditingController();
    final chosenName = await showDialog<String?>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(S.welcomeBackMemberTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(S.welcomeBackMemberMessage(previousName)),
              const SizedBox(height: 16),
              TextField(
                controller: renameController,
                decoration: InputDecoration(
                  labelText: S.newDisplayNameLabel,
                  hintText: previousName,
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => dialogContext.pop(previousName),
              child: Text(S.welcomeBackMemberKeep),
            ),
            FilledButton(
              onPressed: () {
                final newName = renameController.text.trim();
                dialogContext.pop(newName.isEmpty ? previousName : newName);
              },
              child: Text(S.confirm),
            ),
          ],
        );
      },
    );

    renameController.dispose();

    if (!mounted || chosenName == null) return;

    // Rename the member if the chosen name differs from the current display name
    final user = ref.read(currentUserProvider).value;
    if (user != null && chosenName != user.displayName) {
      final householdRepo = ref.read(householdRepositoryProvider);
      await householdRepo.updateMemberDisplayName(
        householdId,
        user.userId,
        chosenName,
      );
    }
  }

  /// Dialog for name conflicts — force choosing a different name
  Future<void> _showNameConflictDialog(
    String inviteCode,
    String conflictingName,
  ) async {
    final renameController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<String?>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(S.nameConflictTitle),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(S.nameConflictMessage),
                const SizedBox(height: 16),
                TextFormField(
                  controller: renameController,
                  decoration: InputDecoration(
                    labelText: S.newDisplayNameLabel,
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return S.newDisplayNameRequired;
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => dialogContext.pop(null),
              child: Text(S.cancel),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  dialogContext.pop(renameController.text.trim());
                }
              },
              child: Text(S.confirm),
            ),
          ],
        );
      },
    );

    renameController.dispose();

    if (!mounted || result == null) return;
    await _doJoinWithNameCheck(inviteCode, result);
  }

  /// Join with re-verification of name uniqueness
  Future<void> _doJoinWithNameCheck(String inviteCode, String displayName) async {
    try {
      // Re-fetch household to check the chosen name against current members
      final householdRepo = ref.read(householdRepositoryProvider);
      final household = await householdRepo.findByInviteCode(inviteCode);

      if (household == null) {
        throw Exception('Household not found');
      }

      final hasConflict = household.members
          .any((m) => m.displayName == displayName);

      if (hasConflict && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.nameStillConflict),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        // Re-show conflict dialog
        await _showNameConflictDialog(inviteCode, displayName);
        return;
      }

      await _doJoin(inviteCode, displayName);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${S.errorJoiningHousehold}: ${e.toString()}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  /// Polls Firestore until subcollection access is granted (max ~5s)
  Future<void> _waitForMembership(
    HouseholdRepository repo,
    String householdId,
    String userId,
  ) async {
    final taskRepo = ref.read(taskRepositoryProvider);
    for (int i = 0; i < 10; i++) {
      try {
        await taskRepo.verifyTaskLogsAccess(householdId);
        return; // Access granted — security rules see the updated memberIds
      } on FirebaseException catch (e) {
        if (e.code != 'permission-denied') return; // Other Firebase error — proceed
        await Future.delayed(const Duration(milliseconds: 500));
      } catch (_) {
        return; // Non-Firebase error — proceed
      }
    }
    // Timeout after ~5s — proceed anyway, stream retry logic will take over
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(S.joinHousehold),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Icon
              Icon(
                Icons.group_add,
                size: 80,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 24),

              // Title
              Text(
                S.joinExistingHousehold,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // Description
              Text(
                S.joinHouseholdDescription,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Invite code field
              TextFormField(
                controller: _codeController,
                decoration: InputDecoration(
                  labelText: S.inviteCode,
                  hintText: S.inviteCodeHint,
                  prefixIcon: const Icon(Icons.vpn_key),
                  border: const OutlineInputBorder(),
                  helperText: S.inviteCodeHelper,
                ),
                textCapitalization: TextCapitalization.characters,
                enabled: !_isLoading,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return S.inviteCodeRequired;
                  }
                  if (value.trim().length != 8) {
                    return S.inviteCodeInvalid;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Join button
              FilledButton(
                onPressed: _isLoading ? null : _joinHousehold,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : Text(S.join),
              ),
              const SizedBox(height: 12),

              // Cancel button
              OutlinedButton(
                onPressed: _isLoading ? null : () => context.pop(),
                child: Text(S.cancel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
