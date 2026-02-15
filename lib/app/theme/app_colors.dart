import 'package:flutter/material.dart';
import 'package:dust_count/core/constants/app_constants.dart';

/// Color palette for DustCount app
/// Provides a comprehensive color system for light and dark themes
class AppColors {
  // Private constructor to prevent instantiation
  AppColors._();

  // Primary Colors
  static const Color primary = Color(0xFF7C9A6E); // Sage green
  static const Color secondary = Color(0xFFD4C5A9); // Warm beige
  static const Color accent = Color(0xFF5B9B8A); // Soft teal

  // Background Colors - Light
  static const Color backgroundLight = Color(0xFFFAF8F5); // Off-white
  static const Color surfaceLight = Color(0xFFFFFFFF); // White

  // Background Colors - Dark
  static const Color backgroundDark = Color(0xFF1A1A2E); // Dark charcoal
  static const Color surfaceDark = Color(0xFF2D2D44);

  // Text Colors - Light
  static const Color textPrimaryLight = Color(0xFF2C2C2C);
  static const Color textSecondary = Color(0xFF8E8E93);

  // Text Colors - Dark
  static const Color textPrimaryDark = Color(0xFFF0EDE8);

  // Status Colors
  static const Color error = Color(0xFFD4726A); // Soft red
  static const Color success = Color(0xFF6BBF7A);
  static const Color warning = Color(0xFFF0A648);

  // Difficulty Colors
  static const Color difficultyPlaisir = Color(0xFF6BBF7A); // Easy - Green
  static const Color difficultyRelou = Color(0xFFF0A648); // Medium - Orange
  static const Color difficultyInfernal = Color(0xFFD4726A); // Hard - Red

  /// Get difficulty color by difficulty level
  static Color getDifficultyColor(TaskDifficulty difficulty) {
    switch (difficulty) {
      case TaskDifficulty.plaisir:
        return difficultyPlaisir;
      case TaskDifficulty.reloo:
        return difficultyRelou;
      case TaskDifficulty.infernal:
        return difficultyInfernal;
    }
  }

  // Category Colors
  static const Color categoryCuisine = Color(0xFFE8A87C); // Kitchen - Orange
  static const Color categoryMenage = Color(0xFF7CB5D4); // Cleaning - Blue
  static const Color categoryLinge = Color(0xFFB088D4); // Laundry - Purple
  static const Color categoryCourses = Color(0xFF6BBF7A); // Shopping - Green
  static const Color categoryDivers = Color(0xFF5B9B8A); // Divers - Teal
  static const Color categoryArchivees = Color(0xFF938F99); // Archived - Gray

  /// Get category color by category name
  static Color getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'cuisine':
        return categoryCuisine;
      case 'menage':
        return categoryMenage;
      case 'linge':
        return categoryLinge;
      case 'courses':
        return categoryCourses;
      case 'divers':
        return categoryDivers;
      case 'archivees':
        return categoryArchivees;
      default:
        return textSecondary;
    }
  }

  // Member Chart Colors (8 distinct colors for household members)
  static const List<Color> memberColors = [
    Color(0xFF7C9A6E), // Sage green
    Color(0xFF5B9B8A), // Soft teal
    Color(0xFF7CB5D4), // Blue
    Color(0xFFB088D4), // Purple
    Color(0xFFE8A87C), // Orange
    Color(0xFFD4C55A), // Yellow
    Color(0xFF6BBF7A), // Light green
    Color(0xFFD4726A), // Soft red
  ];

  /// Get member color by index (cycles through memberColors)
  static Color getMemberColor(int index) {
    return memberColors[index % memberColors.length];
  }

  // Color Schemes
  static const ColorScheme darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFFB3D0A5),
    onPrimary: Color(0xFF1A3A11),
    primaryContainer: Color(0xFF2F5024),
    onPrimaryContainer: Color(0xFFCFECC1),
    secondary: Color(0xFFE8DCC9),
    onSecondary: Color(0xFF3A3730),
    secondaryContainer: Color(0xFF524D45),
    onSecondaryContainer: Color(0xFFFFF8F0),
    tertiary: Color(0xFFA3C9C0),
    onTertiary: Color(0xFF143A32),
    tertiaryContainer: Color(0xFF2F5048),
    onTertiaryContainer: Color(0xFFBFE5DC),
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    errorContainer: Color(0xFF93000A),
    onErrorContainer: Color(0xFFFFDAD6),
    surface: surfaceDark,
    onSurface: textPrimaryDark,
    surfaceContainerHighest: backgroundDark,
    onSurfaceVariant: Color(0xFFCAC4D0),
    outline: Color(0xFF938F99),
    outlineVariant: Color(0xFF49454F),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: textPrimaryDark,
    onInverseSurface: surfaceDark,
    inversePrimary: primary,
  );

  // Data-visualization chart colors (10 distinct vibrant colors)
  static const List<Color> chartColors = [
    Color(0xFF6366F1), // Indigo
    Color(0xFFEC4899), // Pink
    Color(0xFF10B981), // Emerald
    Color(0xFFF59E0B), // Amber
    Color(0xFF8B5CF6), // Violet
    Color(0xFF06B6D4), // Cyan
    Color(0xFFEF4444), // Red
    Color(0xFF14B8A6), // Teal
    Color(0xFFF97316), // Orange
    Color(0xFF3B82F6), // Blue
  ];

  // Gradient definitions
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, accent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradientDark = LinearGradient(
    colors: [surfaceDark, backgroundDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
