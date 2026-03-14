import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tutorial_bubbles/tutorial_bubbles.dart';

import 'test_helpers/tutorial_engine_test_hosts.dart';

void main() {
  group('TutorialEngine target resolution', () {
    testWidgets('renders a rect target step without a backing GlobalKey',
        (tester) async {
      const targetRect = Rect.fromLTWH(40, 60, 120, 48);
      final controller = TutorialEngineController(
        steps: [
          TutorialStep(
            target: TutorialTarget.rect((context) => targetRect),
            bubbleBuilder: (context) =>
                const TutorialTextBubble(text: 'Rect step'),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: TutorialEngine(
            controller: controller,
            child: const SizedBox.expand(),
          ),
        ),
      );

      controller.start();
      await tester.pumpAndSettle();

      final overlay = tester
          .widget<TutorialBubbleOverlay>(find.byType(TutorialBubbleOverlay));

      expect(find.text('Rect step'), findsOneWidget);
      expect(overlay.targetRect, targetRect);
    });

    testWidgets('recomputes rect targets when the hosting widget rebuilds',
        (tester) async {
      final hostKey = GlobalKey<RectTargetHostState>();

      await tester.pumpWidget(
        MaterialApp(
          home: RectTargetHost(key: hostKey),
        ),
      );

      hostKey.currentState!.controller.start();
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<TutorialBubbleOverlay>(find.byType(TutorialBubbleOverlay))
            .targetRect,
        const Rect.fromLTWH(32, 48, 96, 40),
      );

      hostKey.currentState!
          .updateTargetRect(const Rect.fromLTWH(120, 140, 80, 36));
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<TutorialBubbleOverlay>(find.byType(TutorialBubbleOverlay))
            .targetRect,
        const Rect.fromLTWH(120, 140, 80, 36),
      );
    });
  });
}
