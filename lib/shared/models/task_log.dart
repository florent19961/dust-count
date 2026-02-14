import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dust_count/core/constants/app_constants.dart';
import 'package:dust_count/shared/utils/category_helpers.dart';

/// Task log entry model
class TaskLog {
  /// Unique task log identifier
  final String id;

  /// Task name (current locale or custom name)
  final String taskName;

  /// Task name in French (for predefined tasks)
  final String? taskNameFr;

  /// Task name in English (for predefined tasks)
  final String? taskNameEn;

  /// Task category ID (e.g. 'cuisine', 'menage', or a custom UUID)
  final String categoryId;

  /// User ID of the person who performed the task
  final String performedBy;

  /// Display name of the person who performed the task
  final String performedByName;

  /// Date when the task was performed
  final DateTime date;

  /// Duration in minutes
  final int durationMinutes;

  /// Task difficulty level
  final TaskDifficulty difficulty;

  /// Optional comment about the task
  final String? comment;

  /// Log entry creation timestamp
  final DateTime createdAt;

  const TaskLog({
    required this.id,
    required this.taskName,
    this.taskNameFr,
    this.taskNameEn,
    required this.categoryId,
    required this.performedBy,
    required this.performedByName,
    required this.date,
    required this.durationMinutes,
    required this.difficulty,
    this.comment,
    required this.createdAt,
  });

  /// Create TaskLog from Firestore document
  factory TaskLog.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return TaskLog(
      id: doc.id,
      taskName: data['taskName'] as String,
      taskNameFr: data['taskNameFr'] as String?,
      taskNameEn: data['taskNameEn'] as String?,
      categoryId: migrateCategory(data['category'] as String),
      performedBy: data['performedBy'] as String,
      performedByName: data['performedByName'] as String,
      date: (data['date'] as Timestamp).toDate(),
      durationMinutes: data['durationMinutes'] as int,
      difficulty: TaskDifficulty.values.firstWhere(
        (e) => e.name == data['difficulty'] as String,
      ),
      comment: data['comment'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  /// Convert TaskLog to Firestore document data
  Map<String, dynamic> toFirestore() {
    return {
      'taskName': taskName,
      'taskNameFr': taskNameFr,
      'taskNameEn': taskNameEn,
      'category': categoryId,
      'performedBy': performedBy,
      'performedByName': performedByName,
      'date': Timestamp.fromDate(date),
      'durationMinutes': durationMinutes,
      'difficulty': difficulty.name,
      'comment': comment,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Create a copy of this TaskLog with updated fields
  TaskLog copyWith({
    String? id,
    String? taskName,
    String? taskNameFr,
    String? taskNameEn,
    String? categoryId,
    String? performedBy,
    String? performedByName,
    DateTime? date,
    int? durationMinutes,
    TaskDifficulty? difficulty,
    String? comment,
    DateTime? createdAt,
  }) {
    return TaskLog(
      id: id ?? this.id,
      taskName: taskName ?? this.taskName,
      taskNameFr: taskNameFr ?? this.taskNameFr,
      taskNameEn: taskNameEn ?? this.taskNameEn,
      categoryId: categoryId ?? this.categoryId,
      performedBy: performedBy ?? this.performedBy,
      performedByName: performedByName ?? this.performedByName,
      date: date ?? this.date,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      difficulty: difficulty ?? this.difficulty,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskLog && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'TaskLog{id: $id, taskName: $taskName, performedBy: $performedByName, date: $date}';
  }
}
