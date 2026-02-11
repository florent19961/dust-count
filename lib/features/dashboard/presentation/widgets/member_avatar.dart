import 'package:flutter/material.dart';

/// Reusable member avatar widget showing initials in a colored circle
class MemberAvatar extends StatelessWidget {
  final String displayName;
  final String userId;
  final double size;

  const MemberAvatar({
    super.key,
    required this.displayName,
    required this.userId,
    this.size = 40.0,
  });

  @override
  Widget build(BuildContext context) {
    final initials = _getInitials(displayName);
    final backgroundColor = _getColorForUser(userId);
    final textColor = _getContrastingColor(backgroundColor);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: textColor,
            fontSize: size * 0.4,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  /// Extract initials from display name
  String _getInitials(String name) {
    final parts = name.trim().split(' ');

    if (parts.isEmpty) {
      return '??';
    }

    if (parts.length == 1) {
      // Single word: take first two characters
      final word = parts[0];
      return word.length >= 2
          ? word.substring(0, 2).toUpperCase()
          : word.toUpperCase();
    }

    // Multiple words: take first letter of first and last word
    final firstInitial = parts.first.isNotEmpty ? parts.first[0] : '';
    final lastInitial = parts.last.isNotEmpty ? parts.last[0] : '';
    return (firstInitial + lastInitial).toUpperCase();
  }

  /// Get deterministic color based on userId hash
  Color _getColorForUser(String userId) {
    final hash = userId.hashCode;
    final colors = [
      const Color(0xFF6366F1), // Indigo
      const Color(0xFFEC4899), // Pink
      const Color(0xFF10B981), // Emerald
      const Color(0xFFF59E0B), // Amber
      const Color(0xFF8B5CF6), // Violet
      const Color(0xFF06B6D4), // Cyan
      const Color(0xFFEF4444), // Red
      const Color(0xFF14B8A6), // Teal
      const Color(0xFFF97316), // Orange
      const Color(0xFF3B82F6), // Blue
    ];

    return colors[hash.abs() % colors.length];
  }

  /// Get contrasting text color (white or black) based on background luminance
  Color _getContrastingColor(Color backgroundColor) {
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? Colors.black87 : Colors.white;
  }
}
