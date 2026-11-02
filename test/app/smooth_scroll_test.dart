import 'package:flow_tv/app/widgets/smooth_scroll.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('la molette anime le défilement et cumule les crans rapprochés', (tester) async {
    final controller = SmoothScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: ListView.builder(
          controller: controller,
          itemCount: 200,
          itemBuilder: (_, i) => SizedBox(height: 50, child: Text('Ligne $i')),
        ),
      ),
    );

    final center = tester.getCenter(find.byType(ListView));
    await tester.sendEventToBinding(PointerScrollEvent(position: center, scrollDelta: const Offset(0, 100)));
    await tester.pump();
    // Pas de saut immédiat : la position avance progressivement.
    await tester.pump(const Duration(milliseconds: 60));
    expect(controller.offset, inExclusiveRange(0, 100));

    // Un second cran pendant l'animation s'ajoute à la cible.
    await tester.sendEventToBinding(PointerScrollEvent(position: center, scrollDelta: const Offset(0, 100)));
    await tester.pumpAndSettle();
    expect(controller.offset, 200);

    // Vers le haut, sans dépasser le début de la liste.
    await tester.sendEventToBinding(PointerScrollEvent(position: center, scrollDelta: const Offset(0, -500)));
    await tester.pumpAndSettle();
    expect(controller.offset, 0);
  });
}
