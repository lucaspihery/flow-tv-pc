# Flow TV

Application IPTV pour Windows, écrite en Flutter, avec lecteur vidéo intégré.

## Fonctionnalités

- Chargement d'une playlist M3U / M3U8 depuis une **URL** ou un **fichier local**
- Lecture des infos de chaque chaîne : nom, logo (`tvg-logo`), catégorie (`group-title` ou `#EXTGRP`)
- Grille des chaînes avec **catégories** dans la barre latérale et **recherche** instantanée
- **Lecteur intégré** basé sur [media_kit](https://pub.dev/packages/media_kit) (libmpv) : HLS, MPEG-TS, etc., avec contrôles, plein écran et bouton « Réessayer » en cas d'erreur
- La dernière playlist est mémorisée et rechargée au démarrage
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

## Structure du code

```
lib/
  main.dart                     Point d'entrée (initialise media_kit)
  theme.dart                    Thème sombre et couleurs
  models/channel.dart           Modèle d'une chaîne
  services/m3u_parser.dart      Parseur M3U
  services/playlist_service.dart  Chargement URL/fichier + mémorisation
  services/channel_controller.dart  État : groupes, recherche, chaîne en cours
  screens/home_screen.dart      Écran principal
  widgets/                      Barre latérale, tuiles, lecteur, dialogue de playlist
test/m3u_parser_test.dart       Tests du parseur
```

## Tests

```powershell
flutter analyze
flutter test
```
