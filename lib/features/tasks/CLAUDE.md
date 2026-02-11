# Feature : Tasks

## Responsabilité
Déclaration et historique des tâches ménagères au sein d'un foyer.

## Structure
- data/task_repository.dart — CRUD subcollection `households/{id}/taskLogs`
- domain/task_providers.dart — Providers (filteredTaskLogs, taskFilter, taskController)
- presentation/ — TaskFormScreen, TaskHistoryScreen, TaskDetailScreen, TaskEditScreen, TaskTimerScreen
- presentation/widgets/ — TaskCard, PeriodFilter, PredefinedTaskSelector

## Modèle
TaskLog (shared/models/) : taskName, taskNameFr/En, category, performedBy, date, durationMinutes, difficulty, comment (existe en base mais plus exposé en UI)

## Catégories
Built-in : cuisine | menage | linge | courses | divers
+ catégories custom (HouseholdCategory, stockées dans household.customCategories)
Catégorie spéciale "archivees" pour les tâches supprimées.

## Pénibilité
plaisir (😊) | reloo (😐) | infernal (😩)

## UX clé
- Ajout via FAB → bottom sheet avec dropdown unifié (favoris + catégories groupées)
- Pas de mode "tâche personnalisée" — uniquement tâches prédéfinies
- Pas de champ commentaire dans le formulaire
- Timer pleine largeur sous la durée
- Difficulté en ChoiceChips compacts
- Retour automatique à l'onglet Historique après soumission
- Édition : performer modifiable, dropdown avec avatars colorés

## Filtres (PeriodFilter)
Période (semaine/mois/custom) + Catégorie + Membre + Tâche spécifique (section avancée dépliable, opt-in via `showTaskFilter`).
Partagés avec le feature tasks via FilterPeriod enum et TaskFilter.
