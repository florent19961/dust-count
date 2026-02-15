import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dust_count/core/constants/app_constants.dart';
import 'package:dust_count/shared/models/task_log.dart';
import 'package:dust_count/shared/strings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return TaskRepository();
});

/// Repository for managing task logs in Firestore
class TaskRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Gets the task logs subcollection reference for a household
  CollectionReference<Map<String, dynamic>> _taskLogsRef(String householdId) {
    return _firestore
        .collection('households')
        .doc(householdId)
        .collection('taskLogs');
  }

  /// Adds a task log to the household's taskLogs subcollection
  ///
  /// Returns the newly created log ID
  Future<String> addTaskLog(String householdId, TaskLog log) async {
    try {
      final docRef = await _taskLogsRef(householdId).add(log.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception(S.errorAddTaskLog(e.toString()));
    }
  }

  /// Updates an existing task log
  Future<void> updateTaskLog(String householdId, TaskLog log) async {
    try {
      await _taskLogsRef(householdId).doc(log.id).update(log.toFirestore());
    } catch (e) {
      throw Exception(S.errorUpdateTaskLog(e.toString()));
    }
  }

  /// Deletes a task log
  Future<void> deleteTaskLog(String householdId, String logId) async {
    try {
      await _taskLogsRef(householdId).doc(logId).delete();
    } catch (e) {
      throw Exception(S.errorDeleteTaskLog(e.toString()));
    }
  }

  /// Watches task logs with optional filters, ordered by date descending
  Stream<List<TaskLog>> watchTaskLogs(
    String householdId, {
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
    String? performedBy,
    String? taskNameFr,
    TaskDifficulty? difficulty,
  }) {
    try {
      Query<Map<String, dynamic>> query = _taskLogsRef(householdId);

      if (startDate != null) {
        query = query.where('date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }

      if (endDate != null) {
        query =
            query.where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      if (categoryId != null) {
        query = query.where('category', isEqualTo: categoryId);
      }

      if (performedBy != null) {
        query = query.where('performedBy', isEqualTo: performedBy);
      }

      if (taskNameFr != null) {
        query = query.where('taskNameFr', isEqualTo: taskNameFr);
      }

      if (difficulty != null) {
        query = query.where('difficulty', isEqualTo: difficulty.name);
      }

      query = query.orderBy('date', descending: true);

      return query.snapshots().map((snapshot) {
        return snapshot.docs
            .map((doc) => TaskLog.fromFirestore(
                doc as DocumentSnapshot<Map<String, dynamic>>))
            .toList();
      });
    } catch (e) {
      throw Exception(S.errorWatchTaskLogs(e.toString()));
    }
  }

  /// Gets task logs with optional filters (one-time fetch)
  Future<List<TaskLog>> getTaskLogs(
    String householdId, {
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
    String? performedBy,
    TaskDifficulty? difficulty,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _taskLogsRef(householdId);

      if (startDate != null) {
        query = query.where('date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }

      if (endDate != null) {
        query =
            query.where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      if (categoryId != null) {
        query = query.where('category', isEqualTo: categoryId);
      }

      if (performedBy != null) {
        query = query.where('performedBy', isEqualTo: performedBy);
      }

      if (difficulty != null) {
        query = query.where('difficulty', isEqualTo: difficulty.name);
      }

      query = query.orderBy('date', descending: true);

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => TaskLog.fromFirestore(
              doc as DocumentSnapshot<Map<String, dynamic>>))
          .toList();
    } catch (e) {
      throw Exception(S.errorGetTaskLogs(e.toString()));
    }
  }

  /// Counts task logs matching a given French task name
  Future<int> countTaskLogsByName(String householdId, String taskNameFr) async {
    try {
      final snapshot = await _taskLogsRef(householdId)
          .where('taskNameFr', isEqualTo: taskNameFr)
          .get();
      return snapshot.docs.length;
    } catch (e) {
      throw Exception(S.errorCountTaskLogs(e.toString()));
    }
  }

  /// Checks if a user has performed tasks in a household and returns their last known name
  ///
  /// Returns (hasLogs, lastPerformedByName)
  Future<(bool, String?)> hasTasksFromUser(String householdId, String userId) async {
    try {
      final snapshot = await _taskLogsRef(householdId)
          .where('performedBy', isEqualTo: userId)
          .orderBy('date', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return (false, null);
      }

      final data = snapshot.docs.first.data();
      return (true, data['performedByName'] as String?);
    } catch (e) {
      throw Exception(S.errorCheckUserTasks(e.toString()));
    }
  }

  /// Applies a batch update to all documents in a query snapshot.
  /// Processes in chunks of 500 (Firestore batch write limit).
  Future<void> _batchUpdate(
    QuerySnapshot<Map<String, dynamic>> snapshot,
    Map<String, dynamic> Function(QueryDocumentSnapshot<Map<String, dynamic>>) getUpdateData,
  ) async {
    if (snapshot.docs.isEmpty) return;

    for (var i = 0; i < snapshot.docs.length; i += 500) {
      final chunk = snapshot.docs.sublist(
        i,
        i + 500 > snapshot.docs.length ? snapshot.docs.length : i + 500,
      );
      final batch = _firestore.batch();
      for (final doc in chunk) {
        batch.update(doc.reference, getUpdateData(doc));
      }
      await batch.commit();
    }
  }

  /// Renames task logs matching a given French task name
  Future<void> renameTaskLogs(
    String householdId,
    String oldNameFr,
    String newNameFr,
    String newNameEn,
  ) async {
    try {
      final snapshot = await _taskLogsRef(householdId)
          .where('taskNameFr', isEqualTo: oldNameFr)
          .get();

      await _batchUpdate(snapshot, (_) => {
        'taskName': newNameFr,
        'taskNameFr': newNameFr,
        'taskNameEn': newNameEn,
      });
    } catch (e) {
      throw Exception(S.errorRenameTaskLogs(e.toString()));
    }
  }

  /// Updates performedByName in all task logs for a given user in a household
  Future<void> updatePerformedByName(
    String householdId,
    String userId,
    String newDisplayName,
  ) async {
    try {
      final snapshot = await _taskLogsRef(householdId)
          .where('performedBy', isEqualTo: userId)
          .get();

      await _batchUpdate(snapshot, (_) => {
        'performedByName': newDisplayName,
      });
    } catch (e) {
      throw Exception(S.errorUpdatePerformedByName(e.toString()));
    }
  }

  /// Verifies read access to a household's taskLogs subcollection.
  /// Throws [FirebaseException] if access is denied.
  Future<void> verifyTaskLogsAccess(String householdId) async {
    await _taskLogsRef(householdId).limit(1).get();
  }

  /// Migrates task logs category for a given French task name
  Future<void> migrateTaskLogsCategory(
    String householdId,
    String taskNameFr, {
    String targetCategoryId = AppConstants.archivedCategoryId,
  }) async {
    try {
      final snapshot = await _taskLogsRef(householdId)
          .where('taskNameFr', isEqualTo: taskNameFr)
          .get();

      await _batchUpdate(snapshot, (_) => {
        'category': targetCategoryId,
      });
    } catch (e) {
      throw Exception(S.errorMigrateTaskCategory(e.toString()));
    }
  }
}
