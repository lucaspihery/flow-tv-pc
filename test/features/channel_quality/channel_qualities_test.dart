import 'dart:convert';

import 'package:flow_tv/core/storage/preferences.dart';
import 'package:flow_tv/features/auth/domain/iptv_account.dart';
import 'package:flow_tv/features/auth/presentation/auth_controller.dart';
import 'package:flow_tv/features/channel_quality/domain/channel_quality.dart';
import 'package:flow_tv/features/channel_quality/presentation/channel_qualities_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _account = XtreamAccount(serverUrl: 'http://exemple.com', username: 'lucas', password: 'x');

Future<ProviderContainer> _container() async {
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(prefs)]);
  addTearDown(container.dispose);
  return container;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({'iptv_account': jsonEncode(_account.toJson())}));

  test('libellé : résolution et fps, ou résolution seule', () {
    expect(const ChannelQuality(resolution: '4K', frameRate: 50).label, '4K · 50 fps');
    expect(const ChannelQuality(resolution: '1080p').label, '1080p');
  });

  test('mémorise la qualité par chaîne, la met à jour et la conserve au redémarrage', () async {
    final container = await _container();
    final qualities = container.read(channelQualitiesProvider.notifier);

    await qualities.save('1', const ChannelQuality(resolution: '720p', frameRate: 25));
    await qualities.save('1', const ChannelQuality(resolution: '1080p', frameRate: 50));
    await qualities.save('2', const ChannelQuality(resolution: '4K'));

    final relaunched = await _container();
    expect(relaunched.read(channelQualitiesProvider).map((k, v) => MapEntry(k, v.label)), {
      '1': '1080p · 50 fps',
      '2': '4K',
    });
  });

  test('les qualités sont propres à chaque compte', () async {
    final container = await _container();
    await container.read(channelQualitiesProvider.notifier).save('1', const ChannelQuality(resolution: '4K'));

    await container
        .read(authControllerProvider.notifier)
        .signInWithM3u(location: 'http://exemple.com/tv.m3u', isLocalFile: false);
    expect(container.read(channelQualitiesProvider), isEmpty);
  });
}
