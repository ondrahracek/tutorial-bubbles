import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tutorial_bubbles/tutorial_bubbles.dart';

void main() {
  group('TutorialEngine placement', () {
    testWidgets('per-step preferredSide overrides automatic placement',
        (tester) async {
      final key = GlobalKey();
      final controller = TutorialEngineController(
        steps: [
          TutorialStep(
            targetKey: key,
            preferredSide: TutorialBubbleSide.top,
            bubbleBuilder: (context) =>
                const TutorialTextBubble(text: 'Top step'),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: TutorialEngine(
            controller: controller,
            child: Center(
              child: ElevatedButton(
                key: key,
                onPressed: () {},
                child: const Text('Target'),
              ),
            ),
          ),
        ),
      );

      controller.start();
      await tester.pumpAndSettle();

      final overlay = tester
          .widget<TutorialBubbleOverlay>(find.byType(TutorialBubbleOverlay));
      expect(overlay.preferredSide, TutorialBubbleSide.top);
    });
  });
}
