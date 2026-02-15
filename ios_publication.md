# Publication iOS — DustCount

## 1. Configuration Firebase iOS
| Tache | Statut |
|---|---|
| Telecharger `GoogleService-Info.plist` depuis la console Firebase | Fait |
| Le placer dans `ios/Runner/` | Fait |

## 2. Configuration Xcode & Signing
| Tache | Statut |
|---|---|
| Ouvrir `ios/Runner.xcworkspace` dans Xcode | A faire |
| Ajouter `GoogleService-Info.plist` au projet Xcode (clic droit Runner > Add Files to "Runner" > cocher "Copy items if needed") | A faire |
| Configurer le Team ID (Signing & Capabilities) | A faire |
| Creer l'App ID sur Apple Developer Portal | A faire |
| Verifier que le signing automatique fonctionne (pas d'erreur rouge) | A faire |

## 3. Splash Screen
| Tache | Statut |
|---|---|
| Lancer `dart run flutter_native_splash:create` (sur Windows) | A faire |
| Verifier le rendu du splash screen | A faire |

## 4. Build & Upload
| Tache | Statut |
|---|---|
| `flutter pub get` | A faire |
| `cd ios && pod install` | A faire |
| `flutter build ipa` | A faire |
| Upload via Xcode (Product > Archive > Distribute) | A faire |

## 5. App Store Connect — Fiche de l'app
| Tache | Statut |
|---|---|
| App creee dans App Store Connect | Fait |
| Texte promotionnel + description + mots-cles | Fait |
| Copyright | Fait |
| URL d'assistance (GitHub Pages) | Fait |
| Politique de confidentialite (URL) | Fait |
| Questionnaire confidentialite (App Privacy) | Fait |
| Chiffrement (ITSAppUsesNonExemptEncryption) | Fait |
| Age Rating | Fait |
| Categorie + prix (gratuit) | Fait |

## 6. Screenshots
| Tache | Statut |
|---|---|
| Captures 6.7" (iPhone 15 Pro Max / 16 Pro Max) | A faire |
| Captures 6.5" (iPhone 11 Pro Max) | A faire |
| Minimum 3 captures par taille | A faire |

## 7. Compte de test pour Apple Review
| Tache | Statut |
|---|---|
| Creer un compte test dans l'app | Fait |
| Pre-remplir le foyer avec des donnees | Fait |
| Renseigner les identifiants dans App Store Connect | Fait |
| Ecrire les remarques pour le reviewer | Fait |

## 8. TestFlight (recommande avant soumission)
| Tache | Statut |
|---|---|
| Tester le build via TestFlight | A faire |
| Verifier que tout fonctionne sur iPhone reel | A faire |

---

## Deja fait dans le code
- Deployment target → iOS 16.0
- Device family → iPhone only
- Suppression orientations iPad dans Info.plist
- LaunchScreen.storyboard → fond #1A1A2E
- flutter_native_splash active pour iOS
- Podfile cree (platform iOS 16.0)
- Suppression firebase_messaging + permission POST_NOTIFICATIONS + string inutilisee
- `ITSAppUsesNonExemptEncryption = false` dans Info.plist
