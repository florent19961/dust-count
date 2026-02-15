# Publication Android — DustCount

## 1. Configuration Firebase Android
| Tache | Statut |
|---|---|
| Telecharger `google-services.json` depuis la console Firebase | Fait |
| Le placer dans `android/app/` | Fait |
| Verifier `applicationId` dans `android/app/build.gradle` (`com.dustcount.dust_count`) | Fait |

## 2. Signing (Keystore)
| Tache | Statut |
|---|---|
| Generer un keystore de production (`upload-keystore.jks`) | Fait |
| Creer `android/key.properties` avec `storePassword`, `keyPassword`, `keyAlias`, `storeFile` | Fait |
| Ajouter `key.properties` au `.gitignore` | Fait |
| Configurer le signing dans `android/app/build.gradle` (signingConfigs + buildTypes release) | Fait |

## 3. Configuration build.gradle
| Tache | Statut |
|---|---|
| Verifier `minSdkVersion` (21 via `flutter.minSdkVersion`, Flutter 3.24.5) | Fait |
| Verifier `targetSdkVersion` (`targetSdk = 35`) | Fait |
| Verifier `versionCode` et `versionName` dans `pubspec.yaml` (`1.0.0+1`) | Fait |
| Activer le shrinking/obfuscation (`minifyEnabled true`, `shrinkResources true`) dans le build release | Fait |
| Ajouter les regles ProGuard (`proguard-rules.pro` avec regles Flutter + Firebase) | Fait |

## 4. Splash Screen & Icone
| Tache | Statut |
|---|---|
| Lancer `dart run flutter_native_splash:create` (sur Windows) | Fait |
| Verifier le rendu du splash screen sur emulateur/device | Fait |
| Verifier les icones adaptives (`mipmap-anydpi-v26/ic_launcher.xml` + 5 densites) | Fait |

## 5. Build Release
| Tache | Statut |
|---|---|
| `flutter clean` | A faire |
| `flutter pub get` | A faire |
| `flutter build appbundle --release` (genere un `.aab`) | A faire |
| Tester le bundle localement avec `bundletool` ou sur un device | A faire |

## 6. Google Play Console — Fiche de l'app
| Tache | Statut |
|---|---|
| Creer l'application dans Google Play Console | Fait |
| Nom de l'app : DustCount | Fait |
| Description courte (80 caracteres max) | Fait |
| Description longue (4000 caracteres max) | Fait |
| Icone de l'app (512x512 PNG) → `asset/play_store_icon_512.png` | Fait |
| Image de fonctionnalite (1024x500 PNG) → `asset/feature_graphic_1024x500.png` | Fait |
| Categorie : Maison et interieur · Tags : Maison et interieur, Productivite, Agenda, Entraide | Fait |
| Coordonnees de contact (email obligatoire) | Fait |

## 7. Politique de confidentialite & Conformite
| Tache | Statut |
|---|---|
| URL de la politique de confidentialite | Fait |
| Questionnaire securite des donnees (Data Safety) | A faire |
| Classification du contenu (questionnaire IARC) | A faire |
| Public cible et contenu (confirmer 13+ / pas pour enfants) | A faire |
| Publicites (confirmer absence de pubs) | A faire |

## 8. Screenshots
| Tache | Statut |
|---|---|
| Captures telephone (min 2, recommande 4-8, ratio 16:9 ou 9:16) | A faire |
| Captures tablette 7" (optionnel) | A faire |
| Captures tablette 10" (optionnel) | A faire |
| Resolution minimum 320px, maximum 3840px par cote | A faire |

## 9. Tests internes / Closed Testing (recommande avant production)
| Tache | Statut |
|---|---|
| Configurer une piste de test interne | A faire |
| Uploader le `.aab` sur la piste de test | A faire |
| Ajouter des testeurs (emails) | A faire |
| Tester l'installation via le lien de test | A faire |
| Verifier les crashs dans la Play Console (Android Vitals) | A faire |

## 10. Soumission en production
| Tache | Statut |
|---|---|
| Promouvoir le build de test vers la production (ou uploader directement) | A faire |
| Choisir le type de deploiement (staged rollout recommande) | A faire |
| Soumettre pour review Google | A faire |
| Attendre l'approbation (quelques heures a quelques jours) | A faire |

---

## Deja fait dans le code
- `google-services.json` present dans `android/app/`
- `applicationId = com.dustcount.dust_count`
- Permissions Android configurees (INTERNET)
- Signing configure : keystore (`upload-keystore.jks`) + `key.properties` + `build.gradle`
- `key.properties`, `*.jks`, `*.keystore` exclus du `.gitignore`
- `targetSdk = 35`
- `minifyEnabled = true` + `shrinkResources = true` en release
- ProGuard configure (`proguard-rules.pro` avec regles Flutter + Firebase)
- Icones adaptives generees (5 densites + `adaptive-icon` + `colors.xml` background #1A1A2E)
- `minSdk = 21` (via `flutter.minSdkVersion`, Flutter 3.24.5)
- `version: 1.0.0+1` dans pubspec.yaml (versionCode=1, versionName=1.0.0)
- `flutter_native_splash` configure dans `pubspec.yaml`
- Splash screen genere et verifie
- Icone configuree via `flutter_launcher_icons` (Android + iOS + Web regeneres depuis `dust_count_icon_1024.png`)
- Icone Play Store 512x512 : `asset/play_store_icon_512.png`
- Image de fonctionnalite Play Store : `asset/feature_graphic_1024x500.png`
- Politique de confidentialite deployee (GitHub Pages)
- Suppression `firebase_messaging` + permission `POST_NOTIFICATIONS`
