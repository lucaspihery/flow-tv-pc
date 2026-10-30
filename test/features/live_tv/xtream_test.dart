import 'dart:convert';

import 'package:flow_tv/core/errors/app_exception.dart';
import 'package:flow_tv/core/network/http_service.dart';
import 'package:flow_tv/features/auth/domain/iptv_account.dart';
import 'package:flow_tv/features/live_tv/data/xtream/xtream_api_client.dart';
import 'package:flow_tv/features/live_tv/data/xtream/xtream_channel_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _account = XtreamAccount(serverUrl: 'http://exemple.com:8080', username: 'lucas', password: 'p@ss');

XtreamApiClient _client(Object? Function(String? action) respond) {
  final mock = MockClient((request) async {
    expect(request.url.path, '/player_api.php');
    expect(request.url.queryParameters['username'], 'lucas');
    return http.Response(jsonEncode(respond(request.url.queryParameters['action'])), 200);
  });
  return XtreamApiClient(HttpService(mock), _account);
}

void main() {
  test('authenticate accepte un compte actif', () async {
    final api = _client(
      (_) => {
        'user_info': {'auth': 1, 'status': 'Active', 'exp_date': '1893456000', 'max_connections': '2'},
      },
    );
    final info = await api.authenticate();
    expect(info.authenticated, isTrue);
    expect(info.maxConnections, 2);
    expect(info.expiresAt!.toUtc().year, 2030);
  });

  test('authenticate refuse de mauvais identifiants', () async {
    final api = _client(
      (_) => {
        'user_info': {'auth': 0},
      },
    );
    expect(api.authenticate(), throwsA(isA<AuthException>()));
  });

  test('le dépôt Xtream construit les chaînes triées par catégorie', () async {
    final api = _client(
      (action) => switch (action) {
        'get_live_categories' => [
          {'category_id': '2', 'category_name': 'Sport'},
          {'category_id': 1, 'category_name': 'France'},
        ],
        'get_live_streams' => [
          {'num': 1, 'name': 'TF1', 'stream_id': 10, 'stream_icon': 'http://logo/tf1.png', 'category_id': '1'},
          {'num': 2, 'name': 'Sport 1', 'stream_id': '20', 'stream_icon': '', 'category_id': '2'},
          {'num': 3, 'name': 'Inconnue', 'stream_id': 30, 'category_id': null},
        ],
        _ => null,
      },
    );

    final channels = await XtreamChannelRepository(api).fetchChannels();

    expect(channels.map((c) => c.name), ['Sport 1', 'TF1', 'Inconnue']);
    expect(channels[1].group, 'France');
    expect(channels[1].logoUrl, 'http://logo/tf1.png');
    expect(channels[0].logoUrl, isNull);
    expect(channels[2].group, 'Sans catégorie');
    expect(channels[1].streamUrl, 'http://exemple.com:8080/live/lucas/p%40ss/10.ts');
  });
}
