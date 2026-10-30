import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/storage/preferences.dart';
import '../domain/iptv_account.dart';

final accountStorageProvider = Provider<AccountStorage>((ref) => AccountStorage(ref.watch(sharedPreferencesProvider)));

/// Persiste le compte connecté pour le restaurer au prochain lancement.
class AccountStorage {
  AccountStorage(this._prefs);

  static const _key = 'iptv_account';

  final SharedPreferences _prefs;

  IptvAccount? read() {
    final raw = _prefs.getString(_key);
    if (raw == null) return null;
    try {
      return IptvAccount.fromJson(jsonDecode(raw) as Map<String, Object?>);
    } catch (_) {
      return null;
    }
  }

  Future<void> write(IptvAccount account) => _prefs.setString(_key, jsonEncode(account.toJson()));

  Future<void> clear() => _prefs.remove(_key);
}
