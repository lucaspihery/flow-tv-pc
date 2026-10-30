# Flow TV

Application IPTV pour Windows, écrite en Flutter, avec lecteur vidéo intégré.

## Fonctionnalités

- **Deux modes de connexion** :
  - **Xtream Codes** : URL du serveur, nom d'utilisateur et mot de passe (vérifiés auprès du serveur)
  - **Playlist M3U** : par URL ou en ouvrant un fichier local
- Le compte est mémorisé : l'application s'ouvre directement sur les chaînes au lancement suivant, avec un bouton de déconnexion
- **Favoris** : étoile sur chaque chaîne (au survol) et dans le lecteur, section « Favoris » dans la barre latérale, enregistrés par compte
- Catégories dans la barre latérale, grille des chaînes avec logos et **recherche** instantanée
- **Lecteur intégré** basé sur [media_kit](https://pub.dev/packages/media_kit) (libmpv) : HLS, MPEG-TS, etc., avec contrôles, plein écran et bouton « Réessayer » en cas d'erreur
- Interface sombre moderne

## Prérequis

1. **Windows 10 ou 11** (64 bits).
2. **Git** : <https://git-scm.com/download/win>
3. **Flutter SDK** (canal stable) :
   - Télécharger le zip depuis <https://docs.flutter.dev/get-started/install/windows/desktop>
   - L'extraire par exemple dans `C:\src\flutter` (évitez `C:\Program Files`)
   - Ajouter `C:\src\flutter\bin` à la variable d'environnement `Path`
4. **Visual Studio 2022** (Community suffit, ce n'est **pas** VS Code) : <https://visualstudio.microsoft.com/fr/downloads/>
   - Pendant l'installation, cocher la charge de travail **« Développement Desktop en C++ »** (Desktop development with C++), avec les composants par défaut.

Vérifiez ensuite l'installation dans un terminal :

```powershell
flutter doctor
```

Les lignes **Flutter**, **Windows Version** et **Visual Studio - develop Windows apps** doivent être cochées en vert (les avertissements Android/Chrome peuvent être ignorés).

## Lancer l'application

```powershell
git clone https://github.com/lucaspihery/flow-tv-pc.git
cd flow-tv-pc
flutter pub get
flutter run -d windows
```

Le premier lancement est un peu long (compilation C++ et téléchargement de libmpv par media_kit).

## Créer l'exécutable

```powershell
flutter build windows --release
```

Le résultat se trouve dans `build\windows\x64\runner\Release\`. Il faut distribuer **tout le dossier** (le `.exe` seul ne suffit pas, il a besoin des DLL à côté).

Chaque push sur `main` lance aussi un build Windows sur GitHub Actions : le dossier prêt à l'emploi est téléchargeable dans l'onglet **Actions** du dépôt (artefact `flow-tv-windows`).

## Architecture

Le code est organisé **par fonctionnalité** (feature-first), chaque fonctionnalité séparant ses couches :

- `domain` : modèles et contrats métier, sans dépendance à Flutter
- `data` : accès aux sources (API Xtream, fichiers/URL M3U) et implémentations des dépôts
- `presentation` : écrans, widgets et état (Riverpod)

```
lib/
  main.dart                         Point d'entrée : media_kit, préférences, ProviderScope
  app/
    app.dart                        MaterialApp, choix connexion / chaînes selon le compte
    theme/app_theme.dart            Thème sombre et couleurs du logo
    widgets/brand.dart              Logos (BrandMark, BrandBanner) et texte en dégradé
  core/
    errors/app_exception.dart       Erreurs métier affichables (réseau, auth, format)
    network/http_service.dart       Client HTTP (user-agent, délai, erreurs lisibles)
    storage/preferences.dart        Accès à SharedPreferences
  features/
    auth/                           Connexion
      domain/iptv_account.dart      Compte : XtreamAccount | M3uAccount
      data/account_storage.dart     Mémorisation du compte
      presentation/                 AuthController, LoginScreen, formulaires Xtream et M3U
    live_tv/                        TV en direct
      domain/                       Channel, ChannelRepository (interface)
      data/m3u/                     Parseur M3U + dépôt M3U
      data/xtream/                  Client API Xtream, modèles, dépôt Xtream
      presentation/                 Providers (filtres, chaîne en cours), écran, widgets
    favorites/                      Favoris
      data/favorites_storage.dart   Enregistrement par compte
      presentation/                 FavoritesController, bouton étoile
    player/
      presentation/player_panel.dart  Lecteur vidéo media_kit
assets/images/                      Logos : carré, horizontal (bannière) et sans fond
test/                               Tests unitaires et widget, même arborescence que lib/
```

**Gestion d'état** : [Riverpod](https://riverpod.dev). `authControllerProvider` contient le compte connecté ; `channelRepositoryProvider` choisit automatiquement l'implémentation Xtream ou M3U ; l'écran ne connaît que l'interface `ChannelRepository`. Pour ajouter une source (VOD, séries, EPG…), il suffit d'ajouter une fonctionnalité ou une implémentation sans toucher aux écrans existants.

> Le mot de passe Xtream est stocké localement dans les préférences de l'application (non chiffré).

## Tests

```powershell
flutter analyze
flutter test
```
