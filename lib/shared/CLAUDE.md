# Shared

## Responsabilité
Modèles de données et widgets réutilisables à travers toutes les features.

## Models (shared/models/)
- AppUser — Utilisateur Firebase/Firestore
- Household — Foyer avec membres, tâches prédéfinies, catégories custom
- HouseholdMember, PredefinedTask, MemberPreferences — sous-modèles dans household.dart
- TaskLog — Entrée de tâche réalisée
- HouseholdCategory — Catégorie de tâche (built-in ou custom)
- FilterPeriod — Enum (thisWeek, thisMonth, custom)

Tous incluent fromFirestore/toFirestore. L'enum TaskDifficulty est dans core/constants/.

## Utils (shared/utils/)
- category_helpers.dart — builtInCategories, getAllCategories, getCategoryLabel/Icon/Color, findCategory

## Widgets (shared/widgets/)
- LoadingWidget — Indicateur de chargement centré
- AppErrorWidget — Message d'erreur + bouton retry
- DifficultyBadge — Chip emoji+label par niveau de pénibilité
- CategoryChip — Chip icône+label par catégorie de tâche
