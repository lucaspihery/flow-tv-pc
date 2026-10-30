import 'package:flow_tv/app/app.dart';
import 'package:flow_tv/core/storage/preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('sans compte enregistré, affiche la connexion et bascule entre Xtream et M3U', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    tester.view
      ..physicalSize = const Size(1440, 900)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(overrides: [sharedPreferencesProvider.overrideWithValue(prefs)], child: const FlowTvApp()),
    );

    expect(find.text('Se connecter'), findsOneWidget);
    expect(find.text('URL du serveur'), findsOneWidget);

    await tester.tap(find.text('Playlist M3U'));
    await tester.pumpAndSettle();

    expect(find.text('Charger la playlist'), findsOneWidget);
    expect(find.text('Ouvrir un fichier .m3u'), findsOneWidget);
  });
}
