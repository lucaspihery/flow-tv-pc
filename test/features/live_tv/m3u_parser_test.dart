import 'package:flow_tv/features/live_tv/domain/channel.dart';
import 'package:flow_tv/features/live_tv/data/m3u/m3u_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parse les attributs, le nom et le groupe', () {
    const playlist =
        '﻿#EXTM3U\r\n'
        '#EXTINF:-1 tvg-id="tf1.fr" tvg-logo="https://logo/tf1.png" group-title="France",TF1 HD\r\n'
        'http://exemple.com/tf1.m3u8\r\n'
        '#EXTINF:-1 tvg-name="Sport, Live",Sport, Live\n'
        '#EXTVLCOPT:http-user-agent=VLC\n'
        'http://exemple.com/sport.ts\n'
        '#EXTINF:-1,Ciné\n'
        '#EXTGRP:Films\n'
        'http://exemple.com/cine\n';

    final channels = M3uParser.parse(playlist);

    expect(channels, hasLength(3));
    expect(channels[0].name, 'TF1 HD');
    expect(channels[0].group, 'France');
    expect(channels[0].logoUrl, 'https://logo/tf1.png');
    expect(channels[0].id, 'http://exemple.com/tf1.m3u8');
    expect(channels[0].streamUrl, 'http://exemple.com/tf1.m3u8');
    expect(channels[1].name, 'Sport, Live');
    expect(channels[1].group, Channel.defaultGroup);
    expect(channels[1].logoUrl, isNull);
    expect(channels[2].group, 'Films');
  });

  test('ignore les URL sans #EXTINF', () {
    expect(M3uParser.parse('#EXTM3U\nhttp://orphelin\n'), isEmpty);
  });
}
