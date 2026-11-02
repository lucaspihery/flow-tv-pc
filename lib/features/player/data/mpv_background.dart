import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';

import 'package:media_kit/ffi/ffi.dart';
import 'package:media_kit/generated/libmpv/bindings.dart' as mpv;
import 'package:media_kit/media_kit.dart';

/// Accès aux propriétés libmpv hors du thread de l'interface.
///
/// `NativePlayer.getProperty` / `setProperty` appellent libmpv de façon synchrone : si le cœur de
/// mpv est occupé (ouverture d'un flux réseau, mise en cache, changement de filtre), l'appel attend,
/// et l'interface — vidéo comprise — se fige pendant ce temps. Lire les statistiques chaque seconde
/// de cette façon provoquait de petites saccades régulières, plus marquées en zappant. Ici chaque
/// accès part dans un isolate : l'attente éventuelle se fait sur un autre thread.
class MpvBackground {
  MpvBackground(this._player);

  final NativePlayer _player;

  /// Lit [properties] (valeur vide si indisponible) puis applique [set], dans un isolate.
  Future<Map<String, String>> run(List<String> properties, {Map<String, String> set = const {}}) {
    // Le contexte mpv n'existe qu'une fois le lecteur initialisé.
    final ctx = _player.ctx.address;
    if (ctx == 0) return Future.value(const {});
    return Isolate.run(() => _access(ctx, properties, set));
  }
}

/// Noms possibles de libmpv, dans l'ordre où media_kit les cherche. La bibliothèque est déjà
/// chargée par le lecteur : l'ouvrir ici renvoie simplement le même module.
List<String> get _libraryNames => switch (Platform.operatingSystem) {
  'windows' => const ['libmpv-2.dll', 'mpv-2.dll', 'mpv-1.dll'],
  'macos' || 'ios' => const ['Mpv.framework/Mpv'],
  _ => const ['libmpv.so', 'libmpv.so.2', 'libmpv.so.1'],
};

mpv.MPV _open() {
  for (final name in _libraryNames) {
    try {
      return mpv.MPV(DynamicLibrary.open(name));
    } on ArgumentError {
      continue;
    }
  }
  throw StateError('libmpv introuvable');
}

Map<String, String> _access(int address, List<String> properties, Map<String, String> set) {
  final lib = _open();
  final ctx = Pointer<mpv.mpv_handle>.fromAddress(address);
  final values = <String, String>{};
  for (final property in properties) {
    final name = property.toNativeUtf8();
    final value = lib.mpv_get_property_string(ctx, name.cast());
    calloc.free(name);
    if (value == nullptr) {
      values[property] = '';
    } else {
      values[property] = value.cast<Utf8>().toDartString();
      lib.mpv_free(value.cast());
    }
  }
  for (final MapEntry(:key, :value) in set.entries) {
    final name = key.toNativeUtf8();
    final data = value.toNativeUtf8();
    lib.mpv_set_property_string(ctx, name.cast(), data.cast());
    calloc.free(name);
    calloc.free(data);
  }
  return values;
}
