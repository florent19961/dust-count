/// Extracts initials from a display name.
///
/// - Multiple words: first letter of first + last word ("Jean Dupont" → "JD")
/// - Single word ≥ 2 chars: first two characters ("Admin" → "AD")
/// - Single char: returns that char uppercased
/// - Empty: returns "?"
String getInitials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));

  if (parts.isEmpty || parts[0].isEmpty) {
    return '?';
  }

  if (parts.length == 1) {
    final word = parts[0];
    return word.length >= 2
        ? word.substring(0, 2).toUpperCase()
        : word.toUpperCase();
  }

  final firstInitial = parts.first[0];
  final lastInitial = parts.last[0];
  return (firstInitial + lastInitial).toUpperCase();
}
