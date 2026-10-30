import 'package:flow_tv/features/auth/domain/iptv_account.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('XtreamAccount.normalizeServerUrl', () {
    test('ajoute http:// et retire le slash final', () {
      expect(XtreamAccount.normalizeServerUrl(' exemple.com:8080/ '), 'http://exemple.com:8080');
    });

    test('retire player_api.php et les paramètres', () {
      expect(
        XtreamAccount.normalizeServerUrl('https://exemple.com/player_api.php?username=a&password=b'),
        'https://exemple.com',
      );
    });

    test('conserve un sous-chemin', () {
      expect(XtreamAccount.normalizeServerUrl('http://exemple.com/iptv/'), 'http://exemple.com/iptv');
    });
  });

  test('sérialisation aller-retour des deux types de compte', () {
    const xtream = XtreamAccount(serverUrl: 'http://exemple.com', username: 'lucas', password: 'secret');
    const m3u = M3uAccount(location: r'C:\playlists\tv.m3u', isLocalFile: true);

    final x = IptvAccount.fromJson(xtream.toJson()) as XtreamAccount;
    expect((x.serverUrl, x.username, x.password), ('http://exemple.com', 'lucas', 'secret'));

    final m = IptvAccount.fromJson(m3u.toJson()) as M3uAccount;
    expect((m.location, m.isLocalFile), (r'C:\playlists\tv.m3u', true));
    expect(m.displayName, 'tv.m3u');
  });
}
