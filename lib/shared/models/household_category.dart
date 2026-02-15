import 'package:flutter/material.dart';

/// Represents a task category (built-in or custom).
///
/// Built-in categories (cuisine, menage, linge, courses, divers, archivees)
/// have [isBuiltIn] = true and fixed IDs. Custom categories are created by
/// users and stored in the Household document.
///
/// Custom categories may use a native [emoji] instead of a Material icon.
/// When [emoji] is non-null, it takes precedence over [iconCodePoint].
class HouseholdCategory {
  final String id;
  final String labelFr;
  final int iconCodePoint;
  final int colorValue;
  final bool isBuiltIn;
  final String? emoji;

  const HouseholdCategory({
    required this.id,
    required this.labelFr,
    required this.iconCodePoint,
    required this.colorValue,
    this.isBuiltIn = false,
    this.emoji,
  });

  /// All known icon code points mapped to their const Icons.* values.
  /// Keeps Flutter's icon tree-shaker working in release builds.
  static const Map<int, IconData> _knownIcons = {
    0xf0ff: Icons.cleaning_services,
    0xe56c: Icons.restaurant,
    0xe52c: Icons.local_laundry_service,
    0xe8cc: Icons.shopping_cart,
    0xe8ba: Icons.handyman,
    0xe149: Icons.archive,
    0xe88a: Icons.home,
  };

  IconData get icon => _knownIcons[iconCodePoint] ?? Icons.home;
  Color get color => Color(colorValue);
  bool get hasEmoji => emoji != null && emoji!.isNotEmpty;

  factory HouseholdCategory.fromMap(Map<String, dynamic> map) {
    return HouseholdCategory(
      id: map['id'] as String,
      labelFr: map['labelFr'] as String,
      iconCodePoint: map['iconCodePoint'] as int,
      colorValue: map['colorValue'] as int,
      isBuiltIn: map['isBuiltIn'] as bool? ?? false,
      emoji: map['emoji'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'labelFr': labelFr,
      'iconCodePoint': iconCodePoint,
      'colorValue': colorValue,
      'isBuiltIn': isBuiltIn,
      if (emoji != null) 'emoji': emoji,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HouseholdCategory &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
