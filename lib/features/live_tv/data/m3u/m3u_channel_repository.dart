import 'dart:io';
import 'dart:typed_data';

import '../../../../core/concurrency/background.dart';
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
    final bytes = _account.isLocalFile ? await _readFile(_account.location) : await _download(_account.location);
    // Une playlist peut peser plusieurs Mo : décodage et analyse se font hors du thread de l'interface.
    final channels = await runInBackground(
      () => M3uParser.parseBytes(bytes),
      heavy: bytes.length > backgroundThresholdBytes,
    );
    if (channels.isEmpty) {
      throw const ParseException('Aucune chaîne trouvée dans cette playlist.');
    }
    return channels;
  }

  Future<Uint8List> _download(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) throw const ParseException('URL de playlist invalide.');
    return _http.getBytes(uri);
  }

  Future<Uint8List> _readFile(String path) async {
    try {
      return await File(path).readAsBytes();
    } on FileSystemException {
      throw ParseException('Impossible de lire le fichier $path.');
    }
  }
}
