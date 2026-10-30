import 'package:flow_tv/features/player/domain/timeshift_window.dart';
import 'package:flow_tv/features/player/presentation/widgets/player_controls.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late List<String> calls;
  late double volume;
  late List<Duration> seeks;

  Widget build({required bool playing, TimeshiftWindow? timeshift}) => MaterialApp(
    home: Scaffold(
      body: StatefulBuilder(
        builder: (context, setState) => PlayerControls(
          playing: playing,
          volume: volume,
          fullscreen: false,
          onPlayPause: () => calls.add('playPause'),
          onVolumeChanged: (v) => setState(() => volume = v),
          onToggleFullscreen: () => calls.add('fullscreen'),
          timeshift: timeshift,
          onSeekTo: seeks.add,
          onGoLive: () => calls.add('live'),
          hideDelay: const Duration(seconds: 1),
        ),
      ),
    ),
  );

  double opacity(WidgetTester tester) => tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity;

  setUp(() {
    calls = [];
    volume = 70;
    seeks = [];
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

  testWidgets('timeshift : reculer de 10 s puis revenir au direct', (tester) async {
    const behind = TimeshiftWindow(
      start: Duration(seconds: 0),
      liveEdge: Duration(seconds: 300),
      position: Duration(seconds: 240),
    );
    await tester.pumpWidget(build(playing: false, timeshift: behind));

    expect(find.text('-01:00'), findsOneWidget);
    await tester.tap(find.byTooltip('Reculer de 10 s'));
    await tester.tap(find.byTooltip('Avancer de 10 s'));
    expect(seeks, [const Duration(seconds: 230), const Duration(seconds: 250)]);

    await tester.tap(find.text('REVENIR AU DIRECT'));
    expect(calls, ['live']);
  });

  testWidgets('en direct : pastille EN DIRECT, impossible d\'avancer', (tester) async {
    const live = TimeshiftWindow(
      start: Duration(seconds: 0),
      liveEdge: Duration(seconds: 300),
      position: Duration(seconds: 299),
    );
    await tester.pumpWidget(build(playing: false, timeshift: live));
    expect(find.text('EN DIRECT'), findsOneWidget);
    expect(find.text('REVENIR AU DIRECT'), findsNothing);
    final forward = tester.widget<IconButton>(
      find.ancestor(of: find.byIcon(Icons.forward_10_rounded), matching: find.byType(IconButton)),
    );
    expect(forward.onPressed, isNull);
  });
}
