/// Application-wide constants and enums
library;

/// Task difficulty levels
enum TaskDifficulty {
  plaisir,
  reloo,
  infernal,
}

/// Application constants
abstract class AppConstants {
  /// Application name
  static const String appName = 'DustCount';

  /// Predefined tasks with FR/EN names, category, duration, and difficulty
  ///
  /// The first 8 are "quick tasks" shown as chips in the task form.
  static const List<Map<String, dynamic>> predefinedTasks = [
    // --- 8 quick tasks (shown as chips) ---
    {
      'nameFr': 'Aspirateur',
      'nameEn': 'Vacuum',
      'category': 'menage',
      'durationMinutes': 20,
      'difficulty': TaskDifficulty.reloo,
    },
    {
      'nameFr': 'Vaisselle',
      'nameEn': 'Dishes',
      'category': 'cuisine',
      'durationMinutes': 15,
      'difficulty': TaskDifficulty.reloo,
    },
    {
      'nameFr': 'Serpillère',
      'nameEn': 'Mop',
      'category': 'menage',
      'durationMinutes': 20,
      'difficulty': TaskDifficulty.reloo,
    },
    {
      'nameFr': 'Lave-vaisselle',
      'nameEn': 'Dishwasher',
      'category': 'cuisine',
      'durationMinutes': 10,
      'difficulty': TaskDifficulty.plaisir,
    },
    {
      'nameFr': 'Cuisiner',
      'nameEn': 'Cook',
      'category': 'cuisine',
      'durationMinutes': 45,
      'difficulty': TaskDifficulty.plaisir,
    },
    {
      'nameFr': 'Courses',
      'nameEn': 'Groceries',
      'category': 'courses',
      'durationMinutes': 60,
      'difficulty': TaskDifficulty.reloo,
    },
    {
      'nameFr': 'Machine à laver',
      'nameEn': 'Laundry',
      'category': 'linge',
      'durationMinutes': 10,
      'difficulty': TaskDifficulty.plaisir,
    },
    {
      'nameFr': 'Poubelles',
      'nameEn': 'Trash',
      'category': 'divers',
      'durationMinutes': 5,
      'difficulty': TaskDifficulty.plaisir,
    },
    // --- 14 other tasks (shown in dropdown) ---
    {
      'nameFr': 'Salle de bain',
      'nameEn': 'Bathroom',
      'category': 'menage',
      'durationMinutes': 25,
      'difficulty': TaskDifficulty.infernal,
    },
    {
      'nameFr': 'Toilettes',
      'nameEn': 'Toilet',
      'category': 'menage',
      'durationMinutes': 10,
      'difficulty': TaskDifficulty.infernal,
    },
    {
      'nameFr': 'Dépoussiérer',
      'nameEn': 'Dust',
      'category': 'menage',
      'durationMinutes': 15,
      'difficulty': TaskDifficulty.reloo,
    },
    {
      'nameFr': 'Plan de travail',
      'nameEn': 'Countertops',
      'category': 'cuisine',
      'durationMinutes': 10,
      'difficulty': TaskDifficulty.plaisir,
    },
    {
      'nameFr': 'Étendre linge',
      'nameEn': 'Hang laundry',
      'category': 'linge',
      'durationMinutes': 15,
      'difficulty': TaskDifficulty.reloo,
    },
    {
      'nameFr': 'Repassage',
      'nameEn': 'Iron',
      'category': 'linge',
      'durationMinutes': 30,
      'difficulty': TaskDifficulty.infernal,
    },
    {
      'nameFr': 'Ranger le linge',
      'nameEn': 'Fold & put away',
      'category': 'linge',
      'durationMinutes': 20,
      'difficulty': TaskDifficulty.reloo,
    },
    {
      'nameFr': 'Balcon/terrasse',
      'nameEn': 'Balcony/patio',
      'category': 'divers',
      'durationMinutes': 20,
      'difficulty': TaskDifficulty.reloo,
    },
    {
      'nameFr': 'Arroser plantes',
      'nameEn': 'Water plants',
      'category': 'divers',
      'durationMinutes': 10,
      'difficulty': TaskDifficulty.plaisir,
    },
    {
      'nameFr': 'Trier courrier',
      'nameEn': 'Sort mail',
      'category': 'divers',
      'durationMinutes': 15,
      'difficulty': TaskDifficulty.reloo,
    },
    {
      'nameFr': 'Gérer factures',
      'nameEn': 'Manage bills',
      'category': 'divers',
      'durationMinutes': 20,
      'difficulty': TaskDifficulty.infernal,
    },
    {
      'nameFr': 'Bricolage',
      'nameEn': 'DIY / Repairs',
      'category': 'divers',
      'durationMinutes': 30,
      'difficulty': TaskDifficulty.reloo,
    },
    {
      'nameFr': 'Organisation vacances',
      'nameEn': 'Plan vacation',
      'category': 'divers',
      'durationMinutes': 30,
      'difficulty': TaskDifficulty.reloo,
    },
    {
      'nameFr': 'Décoration',
      'nameEn': 'Decoration',
      'category': 'divers',
      'durationMinutes': 20,
      'difficulty': TaskDifficulty.plaisir,
    },
  ];

  /// Number of quick tasks shown as chips (first N in predefinedTasks)
  static const int quickTaskCount = 8;
}
