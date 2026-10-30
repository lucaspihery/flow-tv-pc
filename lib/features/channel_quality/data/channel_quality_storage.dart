import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/storage/preferences.dart';
import '../domain/channel_quality.dart';

final channelQualityStorageProvider = Provider<ChannelQualityStorage>(
  (ref) => ChannelQualityStorage(ref.watch(sharedPreferencesProvider)),
);

/// Qualités mesurées, par identifiant de chaîne, enregistrées séparément pour chaque compte
/// (comme les favoris, elles survivent aux actualisations de la liste).
class ChannelQualityStorage {
  ChannelQualityStorage(this._prefs);

  final SharedPreferences _prefs;

  static String _key(String accountKey) => 'channel_qualities:$accountKey';

  Map<String, ChannelQuality> read(String accountKey) {
    final raw = _prefs.getString(_key(accountKey));
    if (raw == null) return const {};
    try {
      final json = jsonDecode(raw) as Map<String, Object?>;
      return {for (final MapEntry(:key, :value) in json.entries) key: ?ChannelQuality.fromJson(value)};
    } catch (_) {
      return const {};
    }
  }

  Future<void> write(String accountKey, Map<String, ChannelQuality> qualities) => _prefs.setString(
    _key(accountKey),
    jsonEncode({for (final MapEntry(:key, :value) in qualities.entries) key: value.toJson()}),
  );
}
