import '../../domain/channel.dart';

/// Parseur de playlists M3U / M3U8 « étendues » (format IPTV classique).
///
/// Exemple de bloc reconnu :
/// ```
/// #EXTINF:-1 tvg-id="tf1.fr" tvg-logo="https://…/tf1.png" group-title="France",TF1
/// http://exemple.com/tf1.m3u8
/// ```
class M3uParser {
  const M3uParser._();

  static final _attribute = RegExp(r'([\w-]+)="([^"]*)"');

  static List<Channel> parse(String content) {
    final channels = <Channel>[];
    final lines = content.replaceFirst('﻿', '').split(RegExp(r'\r?\n'));

    Map<String, String>? attributes;
    String? name;
    String? extGroup;

    for (final raw in lines) {
      final line = raw.trim();
      if (line.isEmpty) continue;

      if (line.startsWith('#EXTINF')) {
        attributes = {for (final m in _attribute.allMatches(line)) m.group(1)!.toLowerCase(): m.group(2)!.trim()};
        name = _extractName(line);
        extGroup = null;
      } else if (line.startsWith('#EXTGRP:')) {
        extGroup = line.substring('#EXTGRP:'.length).trim();
      } else if (line.startsWith('#')) {
        // #EXTM3U, #EXTVLCOPT, etc. : ignorés.
        continue;
      } else if (attributes != null) {
        channels.add(
          Channel(
            id: _firstNonEmpty([attributes['tvg-id']]) ?? line,
            name: _firstNonEmpty([name, attributes['tvg-name']]) ?? line,
            streamUrl: line,
            logoUrl: _firstNonEmpty([attributes['tvg-logo']]),
            group: _firstNonEmpty([attributes['group-title'], extGroup]) ?? Channel.defaultGroup,
          ),
        );
        attributes = null;
        name = null;
        extGroup = null;
      }
    }
    return channels;
  }

  /// Le nom de la chaîne est le texte après la première virgule située hors guillemets
  /// (les attributs la précèdent, le nom peut lui-même contenir des virgules).
  static String? _extractName(String line) {
    var inQuotes = false;
    for (var i = 0; i < line.length; i++) {
      final c = line[i];
      if (c == '"') {
        inQuotes = !inQuotes;
      } else if (c == ',' && !inQuotes) {
        final name = line.substring(i + 1).trim();
        return name.isEmpty ? null : name;
      }
    }
    return null;
  }

  static String? _firstNonEmpty(List<String?> values) {
    for (final v in values) {
      if (v != null && v.isNotEmpty) return v;
    }
    return null;
  }
}
