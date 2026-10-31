import 'dart:convert';

import 'package:flow_tv/core/concurrency/background.dart';
import 'package:flow_tv/core/network/http_service.dart';
import 'package:flow_tv/features/auth/domain/iptv_account.dart';
import 'package:flow_tv/features/live_tv/data/m3u/m3u_channel_repository.dart';
import 'package:flow_tv/features/live_tv/data/xtream/xtream_api_client.dart';
import 'package:flow_tv/features/live_tv/data/xtream/xtream_channel_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Les grosses playlists sont décodées dans un isolate : on vérifie que ce chemin fonctionne
/// (fonctions envoyables, résultat identique) avec des réponses au-delà du seuil.
void main() {
  const count = 20000;

  test('une grosse playlist M3U est analysée hors du thread de l\'interface', () async {
    final playlist = StringBuffer('#EXTM3U\n');
    for (var i = 0; i < count; i++) {
      playlist
        ..writeln('#EXTINF:-1 tvg-logo="http://logo/$i.png" group-title="Groupe ${i % 50}",Chaîne $i')
        ..writeln('http://exemple.com/$i.ts');
    }
    final body = utf8.encode(playlist.toString());
    expect(body.length, greaterThan(backgroundThresholdBytes));

    final repository = M3uChannelRepository(
      HttpService(MockClient((_) async => http.Response.bytes(body, 200))),
      const M3uAccount(location: 'http://exemple.com/tv.m3u', isLocalFile: false),
    );
    final channels = await repository.fetchChannels();

    expect(channels, hasLength(count));
    expect(channels.last.name, 'Chaîne ${count - 1}');
    expect(channels.last.group, 'Groupe ${(count - 1) % 50}');
  });

  test('une grosse liste Xtream est décodée hors du thread de l\'interface', () async {
    final streams = [
      for (var i = 0; i < count; i++)
        {'num': i, 'name': 'Chaîne $i', 'stream_id': i, 'stream_icon': 'http://logo/$i.png', 'category_id': '1'},
    ];
    final mock = MockClient((request) async {
      final body = switch (request.url.queryParameters['action']) {
        'get_live_categories' => [
          {'category_id': '1', 'category_name': 'France'},
        ],
        _ => streams,
      };
      return http.Response.bytes(utf8.encode(jsonEncode(body)), 200);
    });
    const account = XtreamAccount(serverUrl: 'http://exemple.com', username: 'lucas', password: 'x');

    final channels = await XtreamChannelRepository(XtreamApiClient(HttpService(mock), account)).fetchChannels();

    expect(jsonEncode(streams).length, greaterThan(backgroundThresholdBytes));
    expect(channels, hasLength(count));
    expect(channels.first.group, 'France');
    expect(channels.last.name, 'Chaîne ${count - 1}');
  });
}
