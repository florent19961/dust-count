/// Application-wide constants and enums
library;

/// Task difficulty levels
enum TaskDifficulty {
  plaisir,
  reloo,
  infernal,
}

/// Template for a predefined task (no id — ids are generated at household creation).
class PredefinedTaskTemplate {
  final String nameFr;
  final String nameEn;
  final String category;
  final int durationMinutes;
  final TaskDifficulty difficulty;

  const PredefinedTaskTemplate({
    required this.nameFr,
    required this.nameEn,
    required this.category,
    required this.durationMinutes,
    required this.difficulty,
  });
}

/// Application constants
abstract class AppConstants {
  /// Application name
  static const String appName = 'DustCount';

  /// Predefined tasks with FR/EN names, category, duration, and difficulty.
  ///
  /// The first 8 are "quick tasks" shown as chips in the task form.
  static const List<PredefinedTaskTemplate> predefinedTasks = [
    // --- 8 quick tasks (shown as chips) ---
    PredefinedTaskTemplate(
      nameFr: 'Aspirateur',
      nameEn: 'Vacuum',
      category: 'menage',
      durationMinutes: 15,
      difficulty: TaskDifficulty.plaisir,
    ),
    PredefinedTaskTemplate(
      nameFr: 'Serpillère',
      nameEn: 'Mop',
      category: 'menage',
      durationMinutes: 15,
      difficulty: TaskDifficulty.reloo,
    ),
    PredefinedTaskTemplate(
      nameFr: 'Sortir les poubelles',
      nameEn: 'Take out trash',
      category: 'menage',
      durationMinutes: 5,
      difficulty: TaskDifficulty.plaisir,
    ),
    PredefinedTaskTemplate(
      nameFr: 'Faire la vaisselle',
      nameEn: 'Do the dishes',
      category: 'cuisine',
      durationMinutes: 10,
      difficulty: TaskDifficulty.reloo,
    ),
    PredefinedTaskTemplate(
      nameFr: 'Étendre le linge',
      nameEn: 'Hang laundry',
      category: 'linge',
      durationMinutes: 10,
      difficulty: TaskDifficulty.plaisir,
    ),
    PredefinedTaskTemplate(
      nameFr: 'Plier et ranger le linge',
      nameEn: 'Fold and put away laundry',
      category: 'linge',
      durationMinutes: 10,
      difficulty: TaskDifficulty.plaisir,
    ),
    PredefinedTaskTemplate(
      nameFr: 'Faire les courses',
      nameEn: 'Grocery shopping',
      category: 'courses',
      durationMinutes: 30,
      difficulty: TaskDifficulty.reloo,
    ),
    PredefinedTaskTemplate(
      nameFr: 'Cuisiner',
      nameEn: 'Cook',
      category: 'courses',
      durationMinutes: 30,
      difficulty: TaskDifficulty.plaisir,
    ),
    // --- 13 other tasks (shown in dropdown) ---
    PredefinedTaskTemplate(
      nameFr: 'Dépoussiérer',
      nameEn: 'Dust surfaces',
      category: 'menage',
      durationMinutes: 10,
      difficulty: TaskDifficulty.reloo,
    ),
    PredefinedTaskTemplate(
      nameFr: 'Vitres',
      nameEn: 'Clean windows',
      category: 'menage',
      durationMinutes: 30,
      difficulty: TaskDifficulty.infernal,
    ),
    PredefinedTaskTemplate(
      nameFr: 'Nettoyer toilettes',
      nameEn: 'Clean toilet',
      category: 'menage',
      durationMinutes: 5,
      difficulty: TaskDifficulty.infernal,
    ),
    PredefinedTaskTemplate(
      nameFr: 'Nettoyer salle de bain',
      nameEn: 'Clean bathroom',
      category: 'menage',
      durationMinutes: 20,
      difficulty: TaskDifficulty.infernal,
    ),
    PredefinedTaskTemplate(
      nameFr: 'Vider/remplir lave-vaisselle',
      nameEn: 'Load/unload dishwasher',
      category: 'cuisine',
      durationMinutes: 5,
      difficulty: TaskDifficulty.plaisir,
    ),
    PredefinedTaskTemplate(
      nameFr: 'Nettoyer plan de travail',
      nameEn: 'Clean countertop',
      category: 'cuisine',
      durationMinutes: 5,
      difficulty: TaskDifficulty.plaisir,
    ),
    PredefinedTaskTemplate(
      nameFr: 'Nettoyer four/micro-ondes',
      nameEn: 'Clean oven/microwave',
      category: 'cuisine',
      durationMinutes: 10,
      difficulty: TaskDifficulty.reloo,
    ),
    PredefinedTaskTemplate(
      nameFr: 'Nettoyer frigo',
      nameEn: 'Clean fridge',
      category: 'cuisine',
      durationMinutes: 25,
      difficulty: TaskDifficulty.infernal,
    ),
    PredefinedTaskTemplate(
      nameFr: 'Lancer machine à laver',
      nameEn: 'Start washing machine',
      category: 'linge',
      durationMinutes: 1,
      difficulty: TaskDifficulty.plaisir,
    ),
    PredefinedTaskTemplate(
      nameFr: 'Arroser les plantes',
      nameEn: 'Water plants',
      category: 'divers',
      durationMinutes: 5,
      difficulty: TaskDifficulty.plaisir,
    ),
    PredefinedTaskTemplate(
      nameFr: 'Bricolage/réparations',
      nameEn: 'DIY / Repairs',
      category: 'divers',
      durationMinutes: 10,
      difficulty: TaskDifficulty.infernal,
    ),
    PredefinedTaskTemplate(
      nameFr: 'Gestion administratif',
      nameEn: 'Admin tasks',
      category: 'divers',
      durationMinutes: 5,
      difficulty: TaskDifficulty.reloo,
    ),
    PredefinedTaskTemplate(
      nameFr: 'Préparation vacances',
      nameEn: 'Vacation planning',
      category: 'divers',
      durationMinutes: 20,
      difficulty: TaskDifficulty.plaisir,
    ),
  ];

  /// Number of quick tasks shown as chips (first N in predefinedTasks)
  static const int quickTaskCount = 8;

  /// Maximum number of favorite quick tasks a member can select
  static const int maxQuickTasks = 12;

  /// Category ID for archived/deleted tasks
  static const String archivedCategoryId = 'archivees';
}
