import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dust_count/core/constants/app_constants.dart';
import 'package:dust_count/shared/models/household.dart';
import 'package:dust_count/shared/models/household_category.dart';
import 'package:dust_count/shared/strings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

final householdRepositoryProvider = Provider<HouseholdRepository>(
  (ref) => HouseholdRepository(),
);

/// Repository for managing household data in Firestore
class HouseholdRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionPath = 'households';
  final Uuid _uuid = const Uuid();

  /// Creates a new household with a unique invite code
  ///
  /// Copies default predefined tasks from [AppConstants.defaultPredefinedTasks]
  /// and adds the creator as the first member.
  ///
  /// Returns the newly created household ID.
  Future<String> createHousehold({
    required String name,
    required String creatorId,
    required String creatorName,
    List<PredefinedTask>? predefinedTasks,
    List<HouseholdCategory>? customCategories,
  }) async {
    try {
      // Generate unique invite code (first 8 chars of UUID v4)
      final String inviteCode = _uuid.v4().substring(0, 8).toUpperCase();

      // Use provided tasks or generate from defaults
      final List<PredefinedTask> tasks = predefinedTasks ??
          AppConstants.predefinedTasks
              .map((t) => PredefinedTask(
                    id: _uuid.v4(),
                    nameFr: t.nameFr,
                    nameEn: t.nameEn,
                    categoryId: t.category,
                    defaultDurationMinutes: t.durationMinutes,
                    defaultDifficulty: t.difficulty,
                  ))
              .toList();

      // Create household member
      final HouseholdMember creator = HouseholdMember(
        userId: creatorId,
        displayName: creatorName,
        colorIndex: 0,
      );

      // Create household document
      final DocumentReference docRef =
          _firestore.collection(_collectionPath).doc();

      final Household household = Household(
        id: docRef.id,
        name: name,
        createdBy: creatorId,
        memberIds: [creatorId],
        members: [creator],
        inviteCode: inviteCode,
        createdAt: DateTime.now(),
        predefinedTasks: tasks,
        customCategories: customCategories ?? const [],
      );

      await docRef.set(household.toFirestore());

      return docRef.id;
    } catch (e) {
      throw Exception(S.errorCreateHousehold(e.toString()));
    }
  }

  /// Gets a household by ID
  Future<Household?> getHousehold(String id) async {
    try {
      final doc = await _firestore.collection(_collectionPath).doc(id).get();
      if (!doc.exists) {
        return null;
      }
      return Household.fromFirestore(doc);
    } catch (e) {
      throw Exception(S.errorGetHousehold(e.toString()));
    }
  }

  /// Watches a household by ID
  Stream<Household?> watchHousehold(String id) {
    try {
      return _firestore
          .collection(_collectionPath)
          .doc(id)
          .snapshots()
          .map((snapshot) {
        if (!snapshot.exists) {
          return null;
        }
        return Household.fromFirestore(snapshot);
      });
    } catch (e) {
      throw Exception(S.errorWatchHousehold(e.toString()));
    }
  }

  /// Watches multiple households for a user
  Stream<List<Household>> watchUserHouseholds(List<String> householdIds) {
    try {
      if (householdIds.isEmpty) {
        return Stream.value([]);
      }

      return _firestore
          .collection(_collectionPath)
          .where(FieldPath.documentId, whereIn: householdIds)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) => Household.fromFirestore(doc)).toList();
      });
    } catch (e) {
      throw Exception(S.errorWatchUserHouseholds(e.toString()));
    }
  }

  /// Finds a household by invite code
  Future<Household?> findByInviteCode(String code) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collectionPath)
          .where('inviteCode', isEqualTo: code.toUpperCase())
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      return Household.fromFirestore(querySnapshot.docs.first);
    } catch (e) {
      throw Exception(S.errorFindByInviteCode(e.toString()));
    }
  }

  /// Adds a member to a household
  ///
  /// Uses explicit arrays instead of FieldValue.arrayUnion so that
  /// request.resource.data.memberIds is fully resolved in Firestore
  /// security rules — fixes permission-denied for non-member joins.
  Future<void> addMember(
    String householdId,
    String userId,
    String displayName, {
    required List<String> currentMemberIds,
    required List<HouseholdMember> currentMembers,
  }) async {
    try {
      // Compute smallest free colorIndex
      final usedIndices = currentMembers.map((m) => m.colorIndex).toSet();
      int colorIndex = 0;
      while (usedIndices.contains(colorIndex)) {
        colorIndex++;
      }

      final HouseholdMember newMember = HouseholdMember(
        userId: userId,
        displayName: displayName,
        colorIndex: colorIndex,
      );

      await _firestore.collection(_collectionPath).doc(householdId).update({
        'memberIds': [...currentMemberIds, userId],
        'members': [...currentMembers.map((m) => m.toMap()), newMember.toMap()],
      });
    } catch (e) {
      throw Exception(S.errorAddMember(e.toString()));
    }
  }

  /// Removes a member from a household
  Future<void> removeMember(String householdId, String userId) async {
    try {
      final household = await getHousehold(householdId);
      if (household == null) {
        throw Exception(S.householdNotFound);
      }

      final updatedMembers = household.members.where((m) => m.userId != userId).toList();

      await _firestore.collection(_collectionPath).doc(householdId).update({
        'memberIds': FieldValue.arrayRemove([userId]),
        'members': updatedMembers.map((m) => m.toMap()).toList(),
      });
    } catch (e) {
      throw Exception(S.errorRemoveMember(e.toString()));
    }
  }

  /// Updates the predefined tasks for a household
  Future<void> updatePredefinedTasks(
    String householdId,
    List<PredefinedTask> tasks,
  ) async {
    try {
      await _firestore.collection(_collectionPath).doc(householdId).update({
        'predefinedTasks': tasks.map((t) => t.toMap()).toList(),
      });
    } catch (e) {
      throw Exception(S.errorUpdatePredefinedTasks(e.toString()));
    }
  }

  /// Updates the household name
  Future<void> updateHouseholdName(String householdId, String newName) async {
    try {
      await _firestore.collection(_collectionPath).doc(householdId).update({
        'name': newName,
      });
    } catch (e) {
      throw Exception(S.errorUpdateHouseholdName(e.toString()));
    }
  }

  /// Updates a member's display name in a household
  Future<void> updateMemberDisplayName(
    String householdId,
    String userId,
    String newDisplayName,
  ) async {
    try {
      final household = await getHousehold(householdId);
      if (household == null) throw Exception(S.householdNotFound);

      final updatedMembers = household.members.map((m) {
        if (m.userId == userId) {
          return HouseholdMember(
            userId: userId,
            displayName: newDisplayName,
            colorIndex: m.colorIndex,
          );
        }
        return m;
      }).toList();

      await _firestore.collection(_collectionPath).doc(householdId).update({
        'members': updatedMembers.map((m) => m.toMap()).toList(),
      });
    } catch (e) {
      throw Exception(S.errorUpdateMemberName(e.toString()));
    }
  }

  /// Deletes a household (only if no members left)
  Future<void> deleteHousehold(String id) async {
    try {
      final household = await getHousehold(id);
      if (household == null) {
        throw Exception(S.householdNotFound);
      }

      if (household.memberIds.isNotEmpty) {
        throw Exception(S.cannotDeleteHouseholdWithMembers);
      }

      await _firestore.collection(_collectionPath).doc(id).delete();
    } catch (e) {
      throw Exception(S.errorDeleteHousehold(e.toString()));
    }
  }

  /// Adds a predefined task to the household
  Future<void> addPredefinedTask(String householdId, PredefinedTask task) async {
    try {
      await _firestore.collection(_collectionPath).doc(householdId).update({
        'predefinedTasks': FieldValue.arrayUnion([task.toMap()]),
      });
    } catch (e) {
      throw Exception(S.errorAddPredefinedTask(e.toString()));
    }
  }

  /// Removes a predefined task from the household
  /// Uses fetch + filter + set instead of FieldValue.arrayRemove (needs exact map match)
  Future<void> removePredefinedTask(String householdId, PredefinedTask task) async {
    try {
      final household = await getHousehold(householdId);
      if (household == null) throw Exception(S.householdNotFound);
      final updated = household.predefinedTasks.where((t) => t.id != task.id).toList();
      await updatePredefinedTasks(householdId, updated);
    } catch (e) {
      throw Exception(S.errorRemovePredefinedTask(e.toString()));
    }
  }

  /// Updates a single predefined task in the household (matching by ID)
  Future<void> updatePredefinedTask(String householdId, PredefinedTask updatedTask) async {
    try {
      final household = await getHousehold(householdId);
      if (household == null) throw Exception(S.householdNotFound);
      final updated = household.predefinedTasks.map((t) {
        return t.id == updatedTask.id ? updatedTask : t;
      }).toList();
      await updatePredefinedTasks(householdId, updated);
    } catch (e) {
      throw Exception(S.errorUpdatePredefinedTask(e.toString()));
    }
  }

  /// Watches member preferences for quick task configuration
  Stream<MemberPreferences?> watchMemberPreferences(String householdId, String userId) {
    return _firestore
        .collection(_collectionPath)
        .doc(householdId)
        .collection('memberPreferences')
        .doc(userId)
        .snapshots()
        .map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return MemberPreferences.fromFirestore(doc);
    });
  }

  /// Updates the quick task IDs for a member
  Future<void> updateQuickTaskIds(
    String householdId,
    String userId,
    List<String> quickTaskIds,
  ) async {
    try {
      await _firestore
          .collection(_collectionPath)
          .doc(householdId)
          .collection('memberPreferences')
          .doc(userId)
          .set({'quickTaskIds': quickTaskIds}, SetOptions(merge: true));
    } catch (e) {
      throw Exception(S.errorUpdateQuickTaskIds(e.toString()));
    }
  }

  /// Deletes member preferences subcollection document
  Future<void> deleteMemberPreferences(String householdId, String userId) async {
    try {
      await _firestore
          .collection(_collectionPath)
          .doc(householdId)
          .collection('memberPreferences')
          .doc(userId)
          .delete();
    } catch (e) {
      throw Exception(S.errorDeleteMemberPreferences(e.toString()));
    }
  }

  /// Removes a custom category from a household
  Future<void> removeCustomCategory(String householdId, String categoryId) async {
    try {
      final household = await getHousehold(householdId);
      if (household == null) throw Exception(S.householdNotFound);
      final updated = household.customCategories
          .where((c) => c.id != categoryId)
          .toList();
      await _firestore.collection(_collectionPath).doc(householdId).update({
        'customCategories': updated.map((c) => c.toMap()).toList(),
      });
    } catch (e) {
      throw Exception(S.errorRemoveCustomCategory(e.toString()));
    }
  }

  /// Adds a custom category to a household
  Future<void> addCustomCategory(String householdId, HouseholdCategory category) async {
    try {
      await _firestore.collection(_collectionPath).doc(householdId).update({
        'customCategories': FieldValue.arrayUnion([category.toMap()]),
      });
    } catch (e) {
      throw Exception(S.errorAddCustomCategory(e.toString()));
    }
  }
}
