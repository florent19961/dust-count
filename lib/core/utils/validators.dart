/// Input validation utilities
abstract class Validators {
  /// Email validation regex pattern
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  /// Validate email format
  /// Returns null if valid, error key string if invalid
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'error.email.required';
    }
    if (!_emailRegex.hasMatch(value.trim())) {
      return 'error.email.invalid';
    }
    return null;
  }

  /// Validate password (minimum 6 characters)
  /// Returns null if valid, error key string if invalid
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'error.password.required';
    }
    if (value.length < 6) {
      return 'error.password.tooShort';
    }
    return null;
  }

  /// Validate display name (2-30 characters)
  /// Returns null if valid, error key string if invalid
  static String? displayName(String? value) {
    if (value == null || value.isEmpty) {
      return 'error.displayName.required';
    }
    final trimmed = value.trim();
    if (trimmed.length < 2) {
      return 'error.displayName.tooShort';
    }
    if (trimmed.length > 30) {
      return 'error.displayName.tooLong';
    }
    return null;
  }

  /// Validate household name (2-50 characters)
  /// Returns null if valid, error key string if invalid
  static String? householdName(String? value) {
    if (value == null || value.isEmpty) {
      return 'error.householdName.required';
    }
    final trimmed = value.trim();
    if (trimmed.length < 2) {
      return 'error.householdName.tooShort';
    }
    if (trimmed.length > 50) {
      return 'error.householdName.tooLong';
    }
    return null;
  }
}
