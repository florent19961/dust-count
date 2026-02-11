import 'package:cloud_firestore/cloud_firestore.dart';

/// Application user model
class AppUser {
  /// Unique user identifier (matches Firebase Auth UID)
  final String userId;

  /// User email address
  final String email;

  /// User display name
  final String displayName;

  /// Account creation timestamp
  final DateTime createdAt;

  /// List of household IDs this user belongs to
  final List<String> householdIds;

  /// User's preferred locale (e.g., 'en', 'fr')
  final String locale;

  const AppUser({
    required this.userId,
    required this.email,
    required this.displayName,
    required this.createdAt,
    required this.householdIds,
    required this.locale,
  });

  /// Create AppUser from Firestore document
  factory AppUser.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return AppUser(
      userId: doc.id,
      email: data['email'] as String,
      displayName: data['displayName'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      householdIds: List<String>.from(data['householdIds'] as List<dynamic>),
      locale: data['locale'] as String,
    );
  }

  /// Convert AppUser to Firestore document data
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'createdAt': Timestamp.fromDate(createdAt),
      'householdIds': householdIds,
      'locale': locale,
    };
  }

  /// Create a copy of this AppUser with updated fields
  AppUser copyWith({
    String? userId,
    String? email,
    String? displayName,
    DateTime? createdAt,
    List<String>? householdIds,
    String? locale,
  }) {
    return AppUser(
      userId: userId ?? this.userId,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      createdAt: createdAt ?? this.createdAt,
      householdIds: householdIds ?? this.householdIds,
      locale: locale ?? this.locale,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppUser &&
          runtimeType == other.runtimeType &&
          userId == other.userId;

  @override
  int get hashCode => userId.hashCode;

  @override
  String toString() {
    return 'AppUser{userId: $userId, email: $email, displayName: $displayName}';
  }
}
