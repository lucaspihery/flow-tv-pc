import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/channel.dart';
import 'm3u_parser.dart';

/// Origine d'une playlist : une URL distante ou un fichier local.
enum PlaylistSourceType { url, file }

class PlaylistSource {
  const PlaylistSource(this.type, this.location);

  final PlaylistSourceType type;
  final String location;
}

/// Charge les playlists et mémorise la dernière source utilisée.
class PlaylistService {
  static const _typeKey = 'last_source_type';
  static const _locationKey = 'last_source_location';

  Future<List<Channel>> load(PlaylistSource source) async {
    final content = switch (source.type) {
      PlaylistSourceType.url => await _download(source.location),
      PlaylistSourceType.file => utf8.decode(await File(source.location).readAsBytes(), allowMalformed: true),
    };
    final channels = M3uParser.parse(content);
    if (channels.isEmpty) {
      throw const FormatException('Aucune chaîne trouvée dans cette playlist.');
    }
    return channels;
  }

  Future<String> _download(String url) async {
    final response = await http
        .get(Uri.parse(url), headers: {'User-Agent': 'FlowTV/1.0'})
        .timeout(const Duration(seconds: 30));
    if (response.statusCode != 200) {
      throw HttpException('Erreur HTTP ${response.statusCode}', uri: Uri.parse(url));
    }
    return utf8.decode(response.bodyBytes, allowMalformed: true);
  }

  Future<void> saveLastSource(PlaylistSource source) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_typeKey, source.type.name);
    await prefs.setString(_locationKey, source.location);
  }

  Future<PlaylistSource?> lastSource() async {
    final prefs = await SharedPreferences.getInstance();
    final type = prefs.getString(_typeKey);
    final location = prefs.getString(_locationKey);
    if (type == null || location == null) return null;
    return PlaylistSource(PlaylistSourceType.values.byName(type), location);
  }
}
