/// Firestore collection and document paths
abstract class FirestorePaths {
  /// Users collection path
  static const String users = 'users';

  /// Households collection path
  static const String households = 'households';

  /// Task logs subcollection name (under households)
  static const String taskLogs = 'taskLogs';

  /// Get task logs collection path for a specific household
  static String householdTaskLogs(String householdId) =>
      '$households/$householdId/$taskLogs';
}
