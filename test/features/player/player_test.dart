import 'dart:convert';

import 'package:flow_tv/app/app.dart';
import 'package:flow_tv/core/storage/preferences.dart';
import 'package:flow_tv/features/auth/domain/iptv_account.dart';
import 'package:flow_tv/features/live_tv/domain/channel.dart';
import 'package:flow_tv/features/live_tv/presentation/live_tv_providers.dart';
import 'package:flow_tv/features/player/presentation/player_panel.dart';
import 'package:flow_tv/features/player/presentation/player_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('cliquer sur une chaîne ouvre le lecteur, la croix le ferme', (tester) async {
    const account = M3uAccount(location: 'http://exemple.com/tv.m3u', isLocalFile: false);
    SharedPreferences.setMockInitialValues({'iptv_account': jsonEncode(account.toJson())});
    final prefs = await SharedPreferences.getInstance();
    tester.view
      ..physicalSize = const Size(1440, 900)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          channelsProvider.overrideWith(
            (ref) async => const [Channel(id: '1', name: 'TF1', streamUrl: 'http://x/1', group: 'France')],
          ),
          // libmpv n'est pas disponible en test : on garde l'habillage avec une fausse image.
          playerPanelBuilderProvider.overrideWithValue(
            (channel, onClose) => PlayerView(
              channel: channel,
              video: const ColoredBox(color: Colors.black),
              onRetry: () {},
              onClose: onClose,
            ),
          ),
        ],
        child: const FlowTvApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(PlayerView), findsNothing);

    await tester.tap(find.text('TF1'));
    await tester.pumpAndSettle();
    expect(find.byType(PlayerView), findsOneWidget);
    expect(find.text('EN DIRECT'), findsOneWidget);

    await tester.tap(find.byTooltip('Fermer le lecteur'));
    await tester.pumpAndSettle();
    expect(find.byType(PlayerView), findsNothing);
  });
}
