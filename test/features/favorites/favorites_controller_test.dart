import 'dart:convert';

import 'package:flow_tv/core/storage/preferences.dart';
import 'package:flow_tv/features/auth/domain/iptv_account.dart';
import 'package:flow_tv/features/auth/presentation/auth_controller.dart';
import 'package:flow_tv/features/favorites/presentation/favorites_controller.dart';
import 'package:flow_tv/features/live_tv/domain/channel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _tf1 = Channel(id: '1', name: 'TF1', streamUrl: 'http://x/1');
const _m6 = Channel(id: '2', name: 'M6', streamUrl: 'http://x/2');
const _account = XtreamAccount(serverUrl: 'http://exemple.com', username: 'lucas', password: 'x');

Future<ProviderContainer> _container() async {
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(prefs)]);
  addTearDown(container.dispose);
  return container;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({'iptv_account': jsonEncode(_account.toJson())}));

  test('ajoute, retire et conserve les favoris entre deux lancements', () async {
    final container = await _container();
    final favorites = container.read(favoritesProvider.notifier);

    await favorites.add(_tf1);
    await favorites.toggle(_m6);
    expect(container.read(favoritesProvider), {'1', '2'});

    await favorites.toggle(_tf1);
    expect(container.read(favoritesProvider), {'2'});

    final relaunched = await _container();
    expect(relaunched.read(favoritesProvider), {'2'});
  });

  test('les favoris sont propres à chaque compte', () async {
    final container = await _container();
    await container.read(favoritesProvider.notifier).add(_tf1);

    await container
        .read(authControllerProvider.notifier)
        .signInWithM3u(location: 'http://exemple.com/tv.m3u', isLocalFile: false);
    expect(container.read(favoritesProvider), isEmpty);
  });
}
