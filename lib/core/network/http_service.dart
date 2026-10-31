import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../concurrency/background.dart';
import '../errors/app_exception.dart';

final httpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

final httpServiceProvider = Provider<HttpService>((ref) => HttpService(ref.watch(httpClientProvider)));

/// Petite surcouche de `http` : user-agent, délai, décodage et erreurs lisibles.
class HttpService {
  HttpService(this._client, {this.timeout = const Duration(seconds: 30)});

  static const userAgent = 'FlowTV/1.0';

  final http.Client _client;
  final Duration timeout;

  /// Corps brut de la réponse, à décoder par l'appelant (éventuellement dans un isolate).
  Future<Uint8List> getBytes(Uri uri) async {
    final http.Response response;
    try {
      response = await _client.get(uri, headers: {'User-Agent': userAgent}).timeout(timeout);
    } on TimeoutException {
      throw const NetworkException('Le serveur met trop de temps à répondre.');
    } on SocketException {
      throw NetworkException('Impossible de joindre ${uri.host}.');
    } on http.ClientException catch (e) {
      throw NetworkException('Erreur réseau : ${e.message}');
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw const AuthException('Accès refusé par le serveur (identifiants invalides ?).');
    }
    if (response.statusCode != 200) {
      throw NetworkException('Le serveur a répondu avec une erreur HTTP ${response.statusCode}.');
    }
    return response.bodyBytes;
  }

  /// Télécharge du JSON et le convertit avec [convert].
  ///
  /// Pour une grosse réponse (liste des chaînes Xtream), décodage et conversion se font dans un
  /// isolate : [convert] doit alors être une fonction statique ou de haut niveau.
  Future<T> getJson<T>(Uri uri, T Function(Object? json) convert) async {
    final bytes = await getBytes(uri);
    return runInBackground(() => decodeJson(bytes, convert), heavy: bytes.length > backgroundThresholdBytes);
  }

  static T decodeJson<T>(Uint8List bytes, T Function(Object? json) convert) {
    final Object? json;
    try {
      json = jsonDecode(utf8.decode(bytes, allowMalformed: true));
    } on FormatException {
      throw const ParseException('Réponse inattendue du serveur.');
    }
    return convert(json);
  }
}
