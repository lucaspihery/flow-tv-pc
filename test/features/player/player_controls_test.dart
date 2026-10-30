import 'package:flow_tv/features/player/presentation/widgets/player_controls.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late List<String> calls;
  late double volume;

  Widget build({required bool playing}) => MaterialApp(
    home: Scaffold(
      body: StatefulBuilder(
        builder: (context, setState) => PlayerControls(
          playing: playing,
          volume: volume,
          fullscreen: false,
          onPlayPause: () => calls.add('playPause'),
          onVolumeChanged: (v) => setState(() => volume = v),
          onToggleFullscreen: () => calls.add('fullscreen'),
          hideDelay: const Duration(seconds: 1),
        ),
      ),
    ),
  );

  double opacity(WidgetTester tester) => tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity;

  setUp(() {
    calls = [];
    volume = 70;
  });

  testWidgets('en lecture, les contrôles apparaissent au survol puis se masquent', (tester) async {
    await tester.pumpWidget(build(playing: true));
    expect(opacity(tester), 0);

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouse.removePointer);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(tester.getCenter(find.byType(PlayerControls)));
    await tester.pump();
    expect(opacity(tester), 1);

    await tester.pump(const Duration(seconds: 2));
    expect(opacity(tester), 0);
  });

  testWidgets('en pause, les contrôles restent visibles', (tester) async {
    await tester.pumpWidget(build(playing: false));
    expect(opacity(tester), 1);
  });

  testWidgets('boutons lecture, plein écran et coupure du son', (tester) async {
    await tester.pumpWidget(build(playing: false));

    await tester.tap(find.byTooltip('Lecture'));
    await tester.tap(find.byTooltip('Plein écran'));
    expect(calls, ['playPause', 'fullscreen']);

    await tester.tap(find.byTooltip('Couper le son'));
    await tester.pump();
    expect(volume, 0);

    await tester.tap(find.byTooltip('Réactiver le son'));
    await tester.pump();
    expect(volume, 70);
  });
}
