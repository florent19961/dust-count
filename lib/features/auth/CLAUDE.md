# Feature : Auth

## Responsabilité
Authentification Firebase (email + mot de passe), gestion du profil utilisateur Firestore.

## Structure
- data/auth_repository.dart — Wrapper FirebaseAuth (signUp, signIn, signOut, resetPassword)
- data/user_repository.dart — CRUD utilisateur Firestore (collection `users`)
- domain/auth_providers.dart — Providers Riverpod (authState, currentUser, authController)
- presentation/ — LoginScreen, RegisterScreen, ForgotPasswordScreen, SplashScreen, OnboardingScreen, ProfileScreen

## Modèle
AppUser (shared/models/) : userId, email, displayName, createdAt, householdIds, locale

## Flux
1. SplashScreen → vérifie auth state → Login ou HouseholdList
2. Inscription → crée Firebase user + doc Firestore users/{uid}
3. Connexion → charge AppUser depuis Firestore
4. Onboarding → affiché une seule fois (SharedPreferences flag)
