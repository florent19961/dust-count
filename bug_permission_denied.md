# Bugs permission-denied — Suivi et diagnostic

## Bug 1 — Permission denied apres switch d'utilisateurs (corrige)

**Scenario** :
- Utilisateur B est membre de 2 foyers (H_B + H_A)
- B connecte sur H_A → se deconnecte → A se connecte sur H_A → A se deconnecte → B se reconnecte et va sur H_A → permission-denied
- Workaround : B passe de H_A → H_B → H_A → l'erreur disparait

**Cause** : `currentHouseholdIdProvider` (StateProvider) ne se reinitialisait pas au changement d'utilisateur. La valeur restait `H_A` entre les sessions. Quand B revenait sur H_A, la valeur n'avait pas change → Riverpod ne reevaluait pas les providers → erreur permission-denied du logout de A restait en cache.

**Correction** : Ajout de `ref.watch(authStateProvider.select((state) => state.value?.uid))` dans les create functions de `currentHouseholdIdProvider` et `householdTabIndexProvider` pour forcer leur reinitialisation au changement d'utilisateur.

**Fichier modifie** : `lib/features/household/domain/household_providers.dart`

---

## Bug 2 — Permission denied apres join d'un foyer par invite code (corrige)

**Scenario** :
- Foyer H_A avec 2 membres existants (A et B)
- Nouvel utilisateur C (premier foyer) rejoint H_A via code d'invitation
- Apres le join, C arrive sur H_A → permission-denied sur l'historique des taches
- Workaround : C cree un foyer H_C, y navigue, puis revient sur H_A → l'erreur disparait

**Cause** : Apres `confirmJoin`, `_waitForMembership` poll le document du foyer (readable par tout utilisateur authentifie via `isAuth()`), pas l'acces aux sous-collections (`taskLogs`) qui requiert `isHouseholdMember()`. Le polling reussit immediatement sans verifier que les security rules pour les sous-collections sont effectives. Les providers stream demarrent trop tot, recoivent permission-denied, et l'erreur est mise en cache.

**Correction** :
- Reecriture de `_waitForMembership` pour verifier l'acces reel aux sous-collections via `verifyTaskLogsAccess` (limit(1).get() sur taskLogs). Poll 10 fois avec 500ms de delai (max ~5s).
- Ajout de `verifyTaskLogsAccess` dans `TaskRepository` — fait un `limit(1).get()` sur la sous-collection taskLogs sans wrapper l'exception (expose le `FirebaseException` brut).
- Ajout d'un bouton "Reessayer" sur l'ecran d'erreur de `HouseholdHomeScreen` (invalidate `currentHouseholdProvider`).

**Fichiers modifies** : `task_repository.dart`, `join_household_screen.dart`, `household_home_screen.dart`
