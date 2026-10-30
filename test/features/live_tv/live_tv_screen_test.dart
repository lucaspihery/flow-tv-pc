import 'dart:convert';

import 'package:flow_tv/app/app.dart';
import 'package:flow_tv/core/storage/preferences.dart';
import 'package:flow_tv/features/auth/domain/iptv_account.dart';
import 'package:flow_tv/features/live_tv/domain/channel.dart';
import 'package:flow_tv/features/live_tv/presentation/live_tv_providers.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('compte enregistré : affiche les chaînes, filtre par catégorie et par recherche', (tester) async {
    const account = XtreamAccount(serverUrl: 'http://exemple.com', username: 'lucas', password: 'x');
    SharedPreferences.setMockInitialValues({'iptv_account': jsonEncode(account.toJson())});
    final prefs = await SharedPreferences.getInstance();
    tester.view
      ..physicalSize = const Size(1440, 900)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    const channels = [
      Channel(id: '1', name: 'TF1', streamUrl: 'http://x/1', group: 'France'),
      Channel(id: '2', name: 'France 2', streamUrl: 'http://x/2', group: 'France'),
      Channel(id: '3', name: 'Eurosport 1', streamUrl: 'http://x/3', group: 'Sport'),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          channelsProvider.overrideWith((ref) async => channels),
        ],
        child: const FlowTvApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('3 chaînes'), findsOneWidget);
    expect(find.text('lucas@exemple.com'), findsOneWidget);

    await tester.tap(find.text('Sport'));
    await tester.pumpAndSettle();
    expect(find.text('1 chaîne'), findsOneWidget);
    expect(find.text('Eurosport 1'), findsOneWidget);
    expect(find.text('TF1'), findsNothing);

    await tester.tap(find.text('Toutes les chaînes'));
    await tester.enterText(find.byType(TextField), 'france');
    await tester.pumpAndSettle();
    expect(find.text('France 2'), findsOneWidget);
    expect(find.text('1 chaîne'), findsOneWidget);

    // Survol de la tuile puis clic sur l'étoile : la chaîne passe dans « Favoris ».
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouse.removePointer);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(tester.getCenter(find.text('France 2')));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Ajouter aux favoris'));
    await tester.enterText(find.byType(TextField), '');
    await tester.tap(find.text('Favoris'));
    await tester.pumpAndSettle();
    expect(find.text('1 chaîne'), findsOneWidget);
    expect(find.text('France 2'), findsOneWidget);
    expect(find.text('TF1'), findsNothing);
  });
}
