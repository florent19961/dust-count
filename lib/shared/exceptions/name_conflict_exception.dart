/// Thrown when a display name conflicts with an existing member in a household.
class NameConflictException implements Exception {
  /// Name of the household where the conflict was detected.
  final String householdName;

  const NameConflictException(this.householdName);

  @override
  String toString() => 'NameConflictException: $householdName';
}
