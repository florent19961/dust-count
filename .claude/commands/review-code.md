# Mission : Audit exhaustif de refactorisation et d'organisation du code

## Contexte
Le projet doit être passé au crible pour améliorer sa lisibilité, sa maintenabilité, sa cohérence et sa capacité à évoluer. L'objectif est un codebase propre, ergonomique et facile à réutiliser.

## Ta mission
Balaye l'ensemble du codebase de manière exhaustive pour identifier toutes les opportunités de refactorisation, simplification et réorganisation.

## Axes d'analyse

Analyse systématiquement chaque axe :

### 1. Duplication et redondance
- Blocs de code dupliqués ou quasi-identiques (même logique avec des variations mineures)
- Fonctions qui font la même chose avec des signatures différentes
- Logique métier répétée dans plusieurs endroits au lieu d'être centralisée
- Patterns copier-coller détectables

### 2. Complexité excessive
- Fonctions ou méthodes trop longues (candidates au découpage)
- Fonctions avec trop de responsabilités (violation du Single Responsibility Principle)
- Niveaux d'imbrication excessifs (if/else/for imbriqués sur 3+ niveaux)
- Conditions complexes qui mériteraient d'être extraites dans des fonctions nommées explicitement
- Logique qui pourrait être simplifiée (early returns, guard clauses, suppression de branches inutiles)

### 3. Nommage et lisibilité
- Variables, fonctions, classes dont le nom est ambigu, trop court, trompeur ou incohérent avec leur rôle réel
- Incohérences de conventions de nommage au sein du projet (camelCase vs snake_case mélangés, abréviations inconsistantes)
- Commentaires qui compensent un mauvais nommage (signe que le code devrait parler de lui-même)
- Magic numbers / magic strings qui devraient être des constantes nommées

### 4. Architecture et organisation des fichiers
- Fichiers trop longs ou fourre-tout qui mélangent des responsabilités distinctes
- Modules qui devraient être découpés ou au contraire fusionnés
- Dépendances circulaires ou couplage excessif entre modules
- Code mal placé dans l'arborescence (ex: utilitaire métier dans un dossier infra, ou inversement)
- Manque de séparation des couches (ex: logique métier mélangée avec de l'I/O ou du formatage)

### 5. Cohérence des patterns
- Patterns différents utilisés pour résoudre le même type de problème à différents endroits
- Gestion d'erreurs incohérente (try/catch ici, codes retour là, exceptions custom ailleurs)
- Styles d'API internes incohérents (ex: certaines fonctions retournent null, d'autres throw, d'autres retournent un Result)
- Incohérence dans l'utilisation des abstractions (ex: accès direct à la DB à certains endroits, repository pattern à d'autres)

### 6. Abstractions et extensibilité
- Code trop concret qui bénéficierait d'une abstraction (interface, classe abstraite, pattern strategy)
- À l'inverse : sur-abstraction inutile qui ajoute de la complexité sans bénéfice réel
- Opportunités de généralisation (fonction spécifique à un cas qui pourrait être rendue générique facilement)
- Paramètres hardcodés qui devraient être configurables

### 7. Gestion des types et contrats
- Typages manquants, trop permissifs (any, Object) ou incohérents
- Fonctions dont la signature ne reflète pas le comportement réel (ex: retourne undefined sans que le type le dise)
- Validations dupliquées ou absentes aux frontières du système

## Méthodologie attendue

- Commence par explorer la structure du projet pour comprendre l'architecture globale et les conventions en place
- Identifie d'abord les patterns dominants du projet (ce sont eux la référence de cohérence)
- Pour chaque finding, vérifie l'ampleur : est-ce un cas isolé ou un problème systémique ?
- Priorise les refactorisations à fort impact (celles qui touchent beaucoup de fichiers ou simplifient significativement la compréhension)

## Format du rapport

Pour chaque opportunité identifiée :
- **Fichier(s) + ligne(s)** concernés
- **Catégorie** (duplication / complexité / nommage / architecture / cohérence / abstraction / typage)
- **Problème constaté** : description factuelle et concise
- **Impact** : pourquoi c'est un problème (lisibilité ? maintenabilité ? risque de bug ? dette technique ?)
- **Refactorisation proposée** : description concrète de la transformation suggérée, avec si possible un aperçu du code cible
- **Priorité** : 🔴 Haute (dette technique active, risque de bug) / 🟡 Moyenne (amélioration significative de lisibilité/maintenabilité) / 🟢 Basse (nice-to-have, polish)
- **Effort estimé** : Faible / Moyen / Important

## Livrables

1. **Rapport détaillé** structuré par catégorie, avec tous les findings
2. **Synthèse des patterns systémiques** : les problèmes récurrents qui relèvent d'une décision d'architecture plutôt que d'un fix ponctuel
3. **Plan de refactorisation priorisé** : liste ordonnée des actions par ratio impact/effort (quick wins en premier)

## Consignes importantes

- Sois exhaustif : passe en revue chaque fichier, pas seulement les plus gros
- Reste pragmatique : ne propose pas de refactorisation théoriquement élégante mais disproportionnée par rapport au gain réel
- Respecte l'esprit du projet : tes propositions doivent s'aligner sur les conventions dominantes déjà en place, pas imposer un nouveau style
- Si une refactorisation a des implications sur l'API publique ou les tests, signale-le explicitement
- Pose-moi des questions si tu as besoin de contexte métier pour juger si une abstraction est pertinente
