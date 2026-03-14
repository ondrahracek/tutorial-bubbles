import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tutorial_bubbles/tutorial_bubbles.dart';

import 'test_helpers/tutorial_engine_test_hosts.dart';

void main() {
  group('TutorialEngine beforeShow', () {
    testWidgets('runs before measurement and can prepare the target',
        (tester) async {
      final hostKey = GlobalKey<BeforeShowHostState>();
      final targetKey = GlobalKey();
      late final TutorialEngineController controller;
      controller = TutorialEngineController(
        steps: [
          TutorialStep(
            targetKey: targetKey,
            beforeShow: (context, controller) async {
              hostKey.currentState!.showTarget();
              await Future<void>.delayed(const Duration(milliseconds: 10));
            },
            bubbleBuilder: (context) =>
                const TutorialTextBubble(text: 'Prepared step'),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: BeforeShowHost(
            key: hostKey,
            controller: controller,
            targetKey: targetKey,
          ),
        ),
      );

      controller.start();
      await tester.pump();
      expect(find.byType(TutorialBubbleOverlay), findsNothing);

      await tester.pump(const Duration(milliseconds: 20));
      await tester.pumpAndSettle();

      expect(find.text('Prepared step'), findsOneWidget);
      expect(find.byType(TutorialBubbleOverlay), findsOneWidget);
    });
  });
}
