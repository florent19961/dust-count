import 'package:flutter/material.dart';
import 'package:dust_count/shared/models/household.dart';
import 'package:dust_count/shared/models/household_category.dart';
import 'package:dust_count/shared/strings.dart';
import 'package:dust_count/app/theme/app_colors.dart';
import 'package:dust_count/core/constants/app_constants.dart';

/// Migrate legacy category names to current values.
///
/// Old categories 'exterieur' and 'administratif' are mapped to 'divers'.
String migrateCategory(String categoryName) {
  switch (categoryName) {
    case 'exterieur':
    case 'administratif':
      return 'divers';
    default:
      return categoryName;
  }
}

/// Built-in categories available in every household.
const List<HouseholdCategory> builtInCategories = [
  HouseholdCategory(
    id: 'menage',
    labelFr: 'Ménage',
    iconCodePoint: 0xf0ff, // Icons.cleaning_services
    colorValue: 0xFF7CB5D4,
    isBuiltIn: true,
    emoji: '🧹',
  ),
  HouseholdCategory(
    id: 'cuisine',
    labelFr: 'Cuisine',
    iconCodePoint: 0xe56c, // Icons.restaurant
    colorValue: 0xFFE8A87C,
    isBuiltIn: true,
    emoji: '🍳',
  ),
  HouseholdCategory(
    id: 'linge',
    labelFr: 'Linge',
    iconCodePoint: 0xe52c, // Icons.local_laundry_service
    colorValue: 0xFFB088D4,
    isBuiltIn: true,
    emoji: '👕',
  ),
  HouseholdCategory(
    id: 'courses',
    labelFr: 'Courses & repas',
    iconCodePoint: 0xe8cc, // Icons.shopping_cart
    colorValue: 0xFF6BBF7A,
    isBuiltIn: true,
    emoji: '🛒',
  ),
  HouseholdCategory(
    id: 'divers',
    labelFr: 'Divers',
    iconCodePoint: 0xe8ba, // Icons.handyman
    colorValue: 0xFF5B9B8A,
    isBuiltIn: true,
    emoji: '📦',
  ),
];

/// Special category for archived/deleted tasks.
const HouseholdCategory archiveesCategory = HouseholdCategory(
  id: AppConstants.archivedCategoryId,
  labelFr: 'Archivées',
  iconCodePoint: 0xe149, // Icons.archive
  colorValue: 0xFF938F99,
  isBuiltIn: true,
  emoji: '📂',
);

/// Returns all categories: built-in + custom (excluding archivees).
List<HouseholdCategory> getAllCategories(List<HouseholdCategory> custom) {
  return [...builtInCategories, ...custom];
}

/// Returns all categories including archivees.
List<HouseholdCategory> getAllCategoriesWithArchivees(
  List<HouseholdCategory> custom,
) {
  return [...builtInCategories, ...custom, archiveesCategory];
}

/// Returns categories for filter UI: only categories that contain at least
/// one predefined task. Includes [archiveesCategory] only when at least one
/// predefined task has `categoryId == 'archivees'`.
List<HouseholdCategory> getFilterCategories(
  List<HouseholdCategory> custom,
  List<PredefinedTask> predefinedTasks,
) {
  final usedCategoryIds = predefinedTasks.map((t) => t.categoryId).toSet();
  final result = <HouseholdCategory>[];
  for (final cat in [...builtInCategories, ...custom]) {
    if (usedCategoryIds.contains(cat.id)) {
      result.add(cat);
    }
  }
  if (usedCategoryIds.contains(AppConstants.archivedCategoryId)) {
    result.add(archiveesCategory);
  }
  return result;
}

/// Finds a category by ID among built-in + custom + archivees.
HouseholdCategory? findCategory(
  String id,
  List<HouseholdCategory> custom,
) {
  if (id == AppConstants.archivedCategoryId) return archiveesCategory;
  for (final cat in builtInCategories) {
    if (cat.id == id) return cat;
  }
  for (final cat in custom) {
    if (cat.id == id) return cat;
  }
  return null;
}

/// Gets the icon for a category ID. Falls back to [Icons.help_outline].
IconData getCategoryIcon(String id, List<HouseholdCategory> custom) {
  return findCategory(id, custom)?.icon ?? Icons.help_outline;
}

/// Gets the French label for a category ID.
///
/// For built-in categories, uses the `S` string constants.
/// Falls back to the category's [labelFr] or the raw ID.
String getCategoryLabel(String id, List<HouseholdCategory> custom) {
  switch (id) {
    case 'cuisine':
      return S.categoryCuisine;
    case 'menage':
      return S.categoryMenage;
    case 'linge':
      return S.categoryLinge;
    case 'courses':
      return S.categoryCourses;
    case 'divers':
      return S.categoryDivers;
    case AppConstants.archivedCategoryId:
      return S.categoryArchivees;
    default:
      return findCategory(id, custom)?.labelFr ?? id;
  }
}

/// Gets the emoji for a category ID, or null if none.
String? getCategoryEmoji(String id, List<HouseholdCategory> custom) {
  final cat = findCategory(id, custom);
  return (cat != null && cat.hasEmoji) ? cat.emoji : null;
}

/// Sorts category IDs: built-in first (in canonical order), then custom alphabetically.
/// When [includeArchived] is true, the archived category appears last.
List<String> sortCategoryIds(Iterable<String> ids, {bool includeArchived = false}) {
  final sorted = ids.toList()
    ..sort((a, b) {
      if (!includeArchived) {
        // No special handling needed
      } else {
        if (a == AppConstants.archivedCategoryId) return 1;
        if (b == AppConstants.archivedCategoryId) return -1;
      }
      final aBuiltIn = builtInCategories.any((c) => c.id == a);
      final bBuiltIn = builtInCategories.any((c) => c.id == b);
      if (aBuiltIn && !bBuiltIn) return -1;
      if (!aBuiltIn && bBuiltIn) return 1;
      if (aBuiltIn && bBuiltIn) {
        final aIdx = builtInCategories.indexWhere((c) => c.id == a);
        final bIdx = builtInCategories.indexWhere((c) => c.id == b);
        return aIdx.compareTo(bIdx);
      }
      return a.compareTo(b);
    });
  return sorted;
}

/// Gets the color for a category ID.
Color getCategoryColor(String id, List<HouseholdCategory> custom) {
  return findCategory(id, custom)?.color ?? AppColors.textSecondary;
}
