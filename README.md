# DustCount

Application collaborative de suivi des taches menageres — le Tricount du menage.

## Concept

DustCount permet aux membres d'un foyer de declarer les taches menageres qu'ils effectuent. L'application fournit des visualisations graphiques de la repartition du travail pour encourager un partage equitable.

- **Multi-foyers** : appartenir a plusieurs foyers simultanement
- **Declaratif** : chaque membre declare ce qu'il a fait (categorie, difficulte, duree)
- **Timer integre** : chronometrer ses taches en temps reel
- **Visualisations** : graphiques de repartition, courbes d'evolution, leaderboard
- **Notifications** : rappels via Firebase Cloud Messaging

## Stack technique

| Couche | Technologie |
|--------|-------------|
| Framework | Flutter (Dart 3.5+) |
| Backend | Firebase (Auth, Firestore, FCM) |
| State management | Riverpod |
| Navigation | GoRouter |
| Graphiques | fl_chart |

## Prerequis

- Flutter SDK >= 3.24.0
- Dart SDK >= 3.5.0
- Un projet Firebase configure (plan Spark/gratuit suffit)
- Android Studio ou Xcode pour l'emulateur

## Installation

### 1. Cloner le projet

```bash
git clone https://github.com/florent19961/dust-count.git
cd dust-count
```

### 2. Installer les dependances

```bash
flutter pub get
```

### 3. Configurer Firebase

#### Android
1. Creer un projet Firebase sur [console.firebase.google.com](https://console.firebase.google.com)
2. Ajouter une application Android avec le package `com.dustcount.dust_count`
3. Telecharger `google-services.json`
4. Le placer dans `android/app/google-services.json` (remplacer le placeholder)

#### iOS
1. Ajouter une application iOS avec le bundle ID `com.dustcount.dustCount`
2. Telecharger `GoogleService-Info.plist`
3. Le placer dans `ios/Runner/GoogleService-Info.plist` (remplacer le placeholder)

#### Services Firebase a activer
- **Authentication** : activer le fournisseur "Email/Password"
- **Cloud Firestore** : creer la base de donnees, copier les regles depuis `firestore.rules`
- **Cloud Messaging** : active par defaut

### 4. Generer le code Riverpod

```bash
dart run build_runner build
```

### 5. Lancer l'application

```bash
flutter run
```

## Structure du projet

```
lib/
  app/              # Configuration app, theme, routes
  core/             # Constantes, extensions, utilitaires
  shared/           # Modeles, widgets et strings partages
  features/
    auth/           # Authentification et profil
    household/      # Gestion des foyers
    tasks/          # Enregistrement et historique des taches
    dashboard/      # Statistiques et graphiques
```

Chaque feature suit le pattern **data/** (repositories Firebase) — **domain/** (providers Riverpod) — **presentation/** (ecrans et widgets).

## Commandes utiles

| Commande | Description |
|---|---|
| `flutter run` | Lancer l'app |
| `flutter test` | Lancer les tests |
| `flutter analyze` | Analyse statique du code |
| `flutter pub get` | Installer les dependances |
| `dart run build_runner build` | Generer le code (providers Riverpod) |

## Regles Firestore

Les regles de securite Firestore sont definies dans `firestore.rules`. Les deployer via :

```bash
firebase deploy --only firestore:rules
```

## Licence

Projet personnel — non licencie pour le moment.
