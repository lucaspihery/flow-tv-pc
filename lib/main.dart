import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'core/storage/preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  // Les logos des chaînes sont nombreux mais petits (décodés en 128 px) : on en garde davantage en
  // mémoire que les 1000 images par défaut, pour ne pas les recharger en revenant dans une catégorie.
  PaintingBinding.instance.imageCache
    ..maximumSize = 3000
    ..maximumSizeBytes = 200 << 20;
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      // Pas de nouvelle tentative automatique : les erreurs sont affichées avec un bouton « Réessayer ».
      retry: (_, _) => null,
      child: const FlowTvApp(),
    ),
  );
}
