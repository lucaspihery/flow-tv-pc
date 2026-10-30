import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

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

  Future<String> getText(Uri uri) async {
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
    return utf8.decode(response.bodyBytes, allowMalformed: true);
  }

  Future<Object?> getJson(Uri uri) async {
    final body = await getText(uri);
    try {
      return jsonDecode(body);
    } on FormatException {
      throw const ParseException('Réponse inattendue du serveur.');
    }
  }
}
