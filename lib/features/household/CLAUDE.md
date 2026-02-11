# Feature : Household

## Responsabilité
Gestion des foyers : création, invitation, adhésion, départ, navigation multi-foyers.

## Structure
- data/household_repository.dart — CRUD Firestore (collection `households`)
- domain/household_providers.dart — Providers (currentHousehold, userHouseholds, controller)
- presentation/ — HouseholdListScreen, CreateScreen, JoinScreen, HomeScreen, SettingsScreen, ManagePredefinedTasksScreen
- presentation/widgets/household_card.dart — Carte réutilisable

## Modèle
Household (shared/models/) : id, name, createdBy, memberIds, members, inviteCode, predefinedTasks, customCategories

## Logique d'invitation
- Code unique (UUID v4 tronqué 8 chars) généré à la création
- Rejoindre via code saisi manuellement ou deep link /households/join/:code
- Partage via share_plus (share sheet natif)

## Navigation
HouseholdHomeScreen : 3 onglets (Historique, Dashboard, Paramètres) + FAB Ajouter en bottom sheet
