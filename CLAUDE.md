# DustCount

Application Flutter/Firebase de suivi collaboratif des tâches ménagères.

## Stack
Flutter + Dart | Firebase (Auth, Firestore, FCM) | Riverpod | fl_chart | GoRouter

## Architecture
Feature-first : lib/features/{auth,household,tasks,dashboard}/ chacune avec data/domain/presentation.
- data/ — Repositories (accès Firebase)
- domain/ — Providers Riverpod, modèles métier
- presentation/ — Écrans et widgets

## Conventions de code
- Types stricts, pas de `dynamic`
- Nommage explicite (pas d'abréviations)
- Commentaires uniquement sur la logique métier, pas sur le code évident
- Imports avec package:dust_count/ (pas de chemins relatifs)

## Règles impératives — Zéro code legacy, zéro redondance

**Avant toute modification ou ajout de code :**
1. **Chercher l'existant** : vérifier si une fonction, widget, helper similaire existe déjà
2. **Réutiliser avant de créer** : étendre l'existant plutôt que dupliquer
3. **Aller au bout** : supprimer code obsolète, imports inutilisés, fichiers orphelins
4. **Pas de code mort** : aucun fichier/classe/fonction inutilisé(e)
5. **Pas de duplication** : factoriser immédiatement

## Commandes
- `flutter run` — lancer l'app
- `flutter test` — lancer les tests
- `flutter analyze` — vérifier le code
- `flutter pub get` — installer les dépendances
- `dart run build_runner build` — générer le code (Riverpod, l10n)

## i18n
FR uniquement. Toutes les strings UI sont dans la classe statique `S` dans `lib/shared/strings.dart`. Pas de système l10n/ARB. Les packages `intl` et `flutter_localizations` ne sont pas utilisés ; le formatage de dates se fait via `S.formatDateLong`, `S.formatTime` et `S.formatDateShort`.

## Firebase
Config placeholders dans android/app/google-services.json et ios/Runner/GoogleService-Info.plist.
Règles Firestore dans firestore.rules à la racine.
