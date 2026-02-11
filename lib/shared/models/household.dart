import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dust_count/shared/models/household_category.dart';
import '../../core/constants/app_constants.dart';

/// Household member information
class HouseholdMember {
  /// User ID of the member
  final String userId;

  /// Display name of the member
  final String displayName;

  /// Stable color index persisted in Firestore
  final int colorIndex;

  const HouseholdMember({
    required this.userId,
    required this.displayName,
    required this.colorIndex,
  });

  /// Create HouseholdMember from map
  factory HouseholdMember.fromMap(Map<String, dynamic> map) {
    return HouseholdMember(
      userId: map['userId'] as String,
      displayName: map['displayName'] as String,
      colorIndex: map['colorIndex'] as int,
    );
  }

  /// Convert HouseholdMember to map
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'displayName': displayName,
      'colorIndex': colorIndex,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HouseholdMember &&
          runtimeType == other.runtimeType &&
          userId == other.userId;

  @override
  int get hashCode => userId.hashCode;
}

/// Predefined task template for a household
class PredefinedTask {
  /// Unique task identifier
  final String id;

  /// Task name in French
  final String nameFr;

  /// Task name in English
  final String nameEn;

  /// Task category ID (e.g. 'cuisine', 'menage', or a custom UUID)
  final String categoryId;

  /// Default duration in minutes
  final int defaultDurationMinutes;

  /// Default difficulty level
  final TaskDifficulty defaultDifficulty;

  const PredefinedTask({
    required this.id,
    required this.nameFr,
    required this.nameEn,
    required this.categoryId,
    required this.defaultDurationMinutes,
    required this.defaultDifficulty,
  });

  /// Migrate legacy category names to current values
  static String _migrateCategory(String categoryName) {
    switch (categoryName) {
      case 'exterieur':
      case 'administratif':
        return 'divers';
      default:
        return categoryName;
    }
  }

  /// Create PredefinedTask from map
  factory PredefinedTask.fromMap(Map<String, dynamic> map) {
    final nameFr = map['nameFr'] as String;
    return PredefinedTask(
      id: map['id'] as String,
      nameFr: nameFr,
      nameEn: map['nameEn'] as String,
      categoryId: _migrateCategory(map['category'] as String),
      defaultDurationMinutes: map['defaultDurationMinutes'] as int,
      defaultDifficulty: TaskDifficulty.values.firstWhere(
        (e) => e.name == map['defaultDifficulty'] as String,
      ),
    );
  }

  /// Convert PredefinedTask to map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nameFr': nameFr,
      'nameEn': nameEn,
      'category': categoryId,
      'defaultDurationMinutes': defaultDurationMinutes,
      'defaultDifficulty': defaultDifficulty.name,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PredefinedTask &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Household model
class Household {
  /// Unique household identifier
  final String id;

  /// Household name
  final String name;

  /// User ID of the household creator
  final String createdBy;

  /// List of member user IDs
  final List<String> memberIds;

  /// List of household members with details
  final List<HouseholdMember> members;

  /// Invite code for joining the household
  final String inviteCode;

  /// Household creation timestamp
  final DateTime createdAt;

  /// List of predefined task templates
  final List<PredefinedTask> predefinedTasks;

  /// Custom categories created by household members
  final List<HouseholdCategory> customCategories;

  const Household({
    required this.id,
    required this.name,
    required this.createdBy,
    required this.memberIds,
    required this.members,
    required this.inviteCode,
    required this.createdAt,
    required this.predefinedTasks,
    this.customCategories = const [],
  });

  /// Create Household from Firestore document
  factory Household.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return Household(
      id: doc.id,
      name: data['name'] as String,
      createdBy: data['createdBy'] as String,
      memberIds: List<String>.from(data['memberIds'] as List<dynamic>),
      members: (data['members'] as List<dynamic>)
          .map((m) => HouseholdMember.fromMap(m as Map<String, dynamic>))
          .toList(),
      inviteCode: data['inviteCode'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      predefinedTasks: (data['predefinedTasks'] as List<dynamic>)
          .map((t) => PredefinedTask.fromMap(t as Map<String, dynamic>))
          .toList(),
      customCategories: (data['customCategories'] as List<dynamic>?)
              ?.map(
                  (c) => HouseholdCategory.fromMap(c as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  /// Convert Household to Firestore document data
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'createdBy': createdBy,
      'memberIds': memberIds,
      'members': members.map((m) => m.toMap()).toList(),
      'inviteCode': inviteCode,
      'createdAt': Timestamp.fromDate(createdAt),
      'predefinedTasks': predefinedTasks.map((t) => t.toMap()).toList(),
      'customCategories': customCategories.map((c) => c.toMap()).toList(),
    };
  }

  /// Create a copy of this Household with updated fields
  Household copyWith({
    String? id,
    String? name,
    String? createdBy,
    List<String>? memberIds,
    List<HouseholdMember>? members,
    String? inviteCode,
    DateTime? createdAt,
    List<PredefinedTask>? predefinedTasks,
    List<HouseholdCategory>? customCategories,
  }) {
    return Household(
      id: id ?? this.id,
      name: name ?? this.name,
      createdBy: createdBy ?? this.createdBy,
      memberIds: memberIds ?? this.memberIds,
      members: members ?? this.members,
      inviteCode: inviteCode ?? this.inviteCode,
      createdAt: createdAt ?? this.createdAt,
      predefinedTasks: predefinedTasks ?? this.predefinedTasks,
      customCategories: customCategories ?? this.customCategories,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Household && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Household{id: $id, name: $name, members: ${members.length}}';
  }
}

/// Member-specific preferences within a household
class MemberPreferences {
  /// User ID of the member
  final String userId;

  /// Ordered list of predefined task IDs for quick access (max 12)
  final List<String> quickTaskIds;

  const MemberPreferences({
    required this.userId,
    required this.quickTaskIds,
  });

  /// Create MemberPreferences from Firestore document
  factory MemberPreferences.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return MemberPreferences(
      userId: doc.id,
      quickTaskIds: List<String>.from(data['quickTaskIds'] as List<dynamic>),
    );
  }

  /// Convert MemberPreferences to Firestore document data
  Map<String, dynamic> toFirestore() {
    return {
      'quickTaskIds': quickTaskIds,
    };
  }
}
