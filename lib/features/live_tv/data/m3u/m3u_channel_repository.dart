import 'dart:convert';
import 'dart:io';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/network/http_service.dart';
import '../../../auth/domain/iptv_account.dart';
import '../../domain/channel.dart';
import '../../domain/channel_repository.dart';
import 'm3u_parser.dart';

class M3uChannelRepository implements ChannelRepository {
  M3uChannelRepository(this._http, this._account);

  final HttpService _http;
  final M3uAccount _account;

  @override
  Future<List<Channel>> fetchChannels() async {
    final content = _account.isLocalFile ? await _readFile(_account.location) : await _download(_account.location);
    final channels = M3uParser.parse(content);
    if (channels.isEmpty) {
      throw const ParseException('Aucune chaîne trouvée dans cette playlist.');
    }
    return channels;
  }

  Future<String> _download(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) throw const ParseException('URL de playlist invalide.');
    return _http.getText(uri);
  }

  Future<String> _readFile(String path) async {
    try {
      return utf8.decode(await File(path).readAsBytes(), allowMalformed: true);
    } on FileSystemException {
      throw ParseException('Impossible de lire le fichier $path.');
    }
  }
}
