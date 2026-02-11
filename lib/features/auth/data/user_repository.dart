import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dust_count/shared/models/app_user.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) => UserRepository());

class UserRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionPath = 'users';

  Future<void> createUser(AppUser user) async {
    try {
      await _firestore.collection(_collectionPath).doc(user.userId).set(user.toFirestore());
    } catch (e) {
      throw Exception('Failed to create user: ${e.toString()}');
    }
  }

  Future<AppUser?> getUser(String userId) async {
    try {
      final doc = await _firestore.collection(_collectionPath).doc(userId).get();
      if (!doc.exists) {
        return null;
      }
      return AppUser.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to get user: ${e.toString()}');
    }
  }

  Future<void> updateUser(AppUser user) async {
    try {
      await _firestore.collection(_collectionPath).doc(user.userId).update(user.toFirestore());
    } catch (e) {
      throw Exception('Failed to update user: ${e.toString()}');
    }
  }

  Stream<AppUser?> watchUser(String userId) {
    try {
      return _firestore
          .collection(_collectionPath)
          .doc(userId)
          .snapshots()
          .map((snapshot) {
        if (!snapshot.exists) {
          return null;
        }
        return AppUser.fromFirestore(snapshot);
      });
    } catch (e) {
      throw Exception('Failed to watch user: ${e.toString()}');
    }
  }

  Future<void> addHouseholdToUser(String userId, String householdId) async {
    try {
      await _firestore.collection(_collectionPath).doc(userId).update({
        'householdIds': FieldValue.arrayUnion([householdId]),
      });
    } catch (e) {
      throw Exception('Failed to add household to user: ${e.toString()}');
    }
  }

  Future<void> removeHouseholdFromUser(String userId, String householdId) async {
    try {
      await _firestore.collection(_collectionPath).doc(userId).update({
        'householdIds': FieldValue.arrayRemove([householdId]),
      });
    } catch (e) {
      throw Exception('Failed to remove household from user: ${e.toString()}');
    }
  }

  Future<void> updateDisplayName(String userId, String newDisplayName) async {
    try {
      await _firestore.collection(_collectionPath).doc(userId).update({
        'displayName': newDisplayName,
      });
    } catch (e) {
      throw Exception(
          'Failed to update display name: ${e.toString()}');
    }
  }

  Future<void> updateLocale(String userId, String locale) async {
    try {
      await _firestore.collection(_collectionPath).doc(userId).update({
        'locale': locale,
      });
    } catch (e) {
      throw Exception('Failed to update locale: ${e.toString()}');
    }
  }
}
