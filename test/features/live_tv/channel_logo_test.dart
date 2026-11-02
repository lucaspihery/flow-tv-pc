import 'package:flow_tv/features/live_tv/domain/channel.dart';
import 'package:flow_tv/features/live_tv/presentation/widgets/channel_logo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const channel = Channel(id: '1', name: 'TF1', streamUrl: 'http://x/1', logoUrl: 'http://logo/tf1.png');

  Widget logo(bool visible) => MaterialApp(
    home: Center(child: visible ? const ChannelLogo(channel: channel) : const SizedBox()),
  );

  testWidgets('le logo ne se charge que si la tuile reste affichée', (tester) async {
    await tester.pumpWidget(logo(true));
    // D'abord les initiales, sans téléchargement.
    expect(find.byType(Image), findsNothing);
    expect(find.text('T'), findsOneWidget);

    await tester.pump(ChannelLogo.loadDelay);
    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('une tuile qui ne fait que passer ne télécharge rien', (tester) async {
    await tester.pumpWidget(logo(true));
    await tester.pump(ChannelLogo.loadDelay ~/ 2);
    await tester.pumpWidget(logo(false));
    await tester.pump(ChannelLogo.loadDelay);
    expect(find.byType(Image), findsNothing);
  });
}
