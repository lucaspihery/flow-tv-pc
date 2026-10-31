import 'dart:isolate';

/// Au-delà de cette taille, le décodage d'une réponse part dans un isolate séparé.
///
/// En dessous, lancer un isolate coûte plus cher que le travail lui-même.
const backgroundThresholdBytes = 256 * 1024;

/// Exécute [computation] hors du thread de l'interface si [heavy] est vrai, sinon directement.
///
/// Sert au décodage des grosses playlists M3U et réponses Xtream (plusieurs Mo, des dizaines de
/// milliers de chaînes), qui figeraient sinon l'interface pendant le chargement.
Future<R> runInBackground<R>(R Function() computation, {required bool heavy}) async =>
    heavy ? Isolate.run(computation) : computation();
