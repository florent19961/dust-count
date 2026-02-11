import 'package:flutter/material.dart';

/// Represents a task category (built-in or custom).
///
/// Built-in categories (cuisine, menage, linge, courses, divers, archivees)
/// have [isBuiltIn] = true and fixed IDs. Custom categories are created by
/// users and stored in the Household document.
class HouseholdCategory {
  final String id;
  final String labelFr;
  final int iconCodePoint;
  final int colorValue;
  final bool isBuiltIn;

  const HouseholdCategory({
    required this.id,
    required this.labelFr,
    required this.iconCodePoint,
    required this.colorValue,
    this.isBuiltIn = false,
  });

  IconData get icon => IconData(iconCodePoint, fontFamily: 'MaterialIcons');
  Color get color => Color(colorValue);

  factory HouseholdCategory.fromMap(Map<String, dynamic> map) {
    return HouseholdCategory(
      id: map['id'] as String,
      labelFr: map['labelFr'] as String,
      iconCodePoint: map['iconCodePoint'] as int,
      colorValue: map['colorValue'] as int,
      isBuiltIn: map['isBuiltIn'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'labelFr': labelFr,
      'iconCodePoint': iconCodePoint,
      'colorValue': colorValue,
      'isBuiltIn': isBuiltIn,
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
