import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/storage/preferences.dart';

final favoritesStorageProvider = Provider<FavoritesStorage>(
  (ref) => FavoritesStorage(ref.watch(sharedPreferencesProvider)),
);

/// Identifiants des chaînes favorites, enregistrés séparément pour chaque compte.
class FavoritesStorage {
  FavoritesStorage(this._prefs);

  final SharedPreferences _prefs;

  static String _key(String accountKey) => 'favorites:$accountKey';

  List<String> read(String accountKey) => _prefs.getStringList(_key(accountKey)) ?? const [];

  Future<void> write(String accountKey, Iterable<String> channelIds) =>
      _prefs.setStringList(_key(accountKey), channelIds.toList());
}
