import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tutorial_bubbles/tutorial_bubbles.dart';

void main() {
  group('TutorialEngine per-step behavior', () {
    testWidgets('can enable bubble advancement per step', (tester) async {
      final key = GlobalKey();
      final controller = TutorialEngineController(
        steps: [
          TutorialStep(
            targetKey: key,
            behavior: const TutorialStepBehavior(advanceOnBubbleTap: true),
            bubbleBuilder: (context) =>
                const TutorialTextBubble(text: 'Step 1'),
          ),
          TutorialStep(
            targetKey: key,
            bubbleBuilder: (context) =>
                const TutorialTextBubble(text: 'Step 2'),
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
      await tester.tap(find.text('Step 1'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(controller.currentIndex, 1);
      expect(find.text('Step 2'), findsOneWidget);
    });

    testWidgets('can enable overlay advancement per step', (tester) async {
      final key = GlobalKey();
      final controller = TutorialEngineController(
        steps: [
          TutorialStep(
            targetKey: key,
            behavior: const TutorialStepBehavior(advanceOnOverlayTap: true),
            bubbleBuilder: (context) =>
                const TutorialTextBubble(text: 'Step 1'),
          ),
          TutorialStep(
            targetKey: key,
            bubbleBuilder: (context) =>
                const TutorialTextBubble(text: 'Step 2'),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TutorialEngine(
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
        ),
      );

      controller.start();
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(8, 8));
      await tester.pumpAndSettle();

      expect(controller.currentIndex, 1);
    });

    testWidgets(
        'can allow outside interactions when blockOutsideTarget is false',
        (tester) async {
      var outsideTapCount = 0;
      final key = GlobalKey();
      final controller = TutorialEngineController(
        steps: [
          TutorialStep(
            targetKey: key,
            behavior: const TutorialStepBehavior(blockOutsideTarget: false),
            bubbleBuilder: (context) => const TutorialTextBubble(text: 'Step'),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TutorialEngine(
              controller: controller,
              child: Column(
                children: [
                  ElevatedButton(
                    onPressed: () => outsideTapCount += 1,
                    child: const Text('Outside button'),
                  ),
                  ElevatedButton(
                    key: key,
                    onPressed: () {},
                    child: const Text('Target button'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      controller.start();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Outside button'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(outsideTapCount, 1);
    });

    testWidgets('can block target taps when allowTargetTap is false',
        (tester) async {
      var targetTapCount = 0;
      final key = GlobalKey();
      final controller = TutorialEngineController(
        steps: [
          TutorialStep(
            targetKey: key,
            behavior: const TutorialStepBehavior(allowTargetTap: false),
            bubbleBuilder: (context) => const TutorialTextBubble(text: 'Step'),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TutorialEngine(
              controller: controller,
              child: Center(
                child: ElevatedButton(
                  key: key,
                  onPressed: () => targetTapCount += 1,
                  child: const Text('Target button'),
                ),
              ),
            ),
          ),
        ),
      );

      controller.start();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Target button'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(targetTapCount, 0);
    });

    testWidgets('invokes target and overlay callbacks', (tester) async {
      var targetTapCount = 0;
      var overlayTapCount = 0;
      final key = GlobalKey();
      final controller = TutorialEngineController(
        steps: [
          TutorialStep(
            targetKey: key,
            behavior: TutorialStepBehavior(
              allowTargetTap: false,
              onTargetTap: (context) {
                targetTapCount += 1;
              },
              onOverlayTap: (context) {
                overlayTapCount += 1;
              },
            ),
            bubbleBuilder: (context) => const TutorialTextBubble(text: 'Step'),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TutorialEngine(
              controller: controller,
              child: Center(
                child: ElevatedButton(
                  key: key,
                  onPressed: () {},
                  child: const Text('Target button'),
                ),
              ),
            ),
          ),
        ),
      );

      controller.start();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Target button'), warnIfMissed: false);
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(6, 6));
      await tester.pumpAndSettle();

      expect(targetTapCount, 1);
      expect(overlayTapCount, 1);
    });

    testWidgets('can advance on target tap when configured', (tester) async {
      final key = GlobalKey();
      final controller = TutorialEngineController(
        steps: [
          TutorialStep(
            targetKey: key,
            behavior: const TutorialStepBehavior(advanceOnTargetTap: true),
            bubbleBuilder: (context) =>
                const TutorialTextBubble(text: 'Step 1'),
          ),
          TutorialStep(
            targetKey: key,
            bubbleBuilder: (context) =>
                const TutorialTextBubble(text: 'Step 2'),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TutorialEngine(
              controller: controller,
              child: Center(
                child: ElevatedButton(
                  key: key,
                  onPressed: () {},
                  child: const Text('Target button'),
                ),
              ),
            ),
          ),
        ),
      );

      controller.start();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Target button'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(controller.currentIndex, 1);
      expect(find.text('Step 2'), findsOneWidget);
    });

    testWidgets('does not advance on target tap when not configured',
        (tester) async {
      final key = GlobalKey();
      final controller = TutorialEngineController(
        steps: [
          TutorialStep(
            targetKey: key,
            behavior: const TutorialStepBehavior(),
            bubbleBuilder: (context) =>
                const TutorialTextBubble(text: 'Step 1'),
          ),
          TutorialStep(
            targetKey: key,
            bubbleBuilder: (context) =>
                const TutorialTextBubble(text: 'Step 2'),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TutorialEngine(
              controller: controller,
              child: Center(
                child: ElevatedButton(
                  key: key,
                  onPressed: () {},
                  child: const Text('Target button'),
                ),
              ),
            ),
          ),
        ),
      );

      controller.start();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Target button'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(controller.currentIndex, 0);
      expect(find.text('Step 1'), findsOneWidget);
    });

    testWidgets('ignores repeated target taps while callback is in flight',
        (tester) async {
      var callCount = 0;
      final completer = Completer<void>();
      final key = GlobalKey();
      final controller = TutorialEngineController(
        steps: [
          TutorialStep(
            targetKey: key,
            behavior: TutorialStepBehavior(
              allowTargetTap: false,
              onTargetTap: (context) async {
                callCount += 1;
                await completer.future;
              },
              advanceOnTargetTap: true,
            ),
            bubbleBuilder: (context) =>
                const TutorialTextBubble(text: 'Step 1'),
          ),
          TutorialStep(
            targetKey: key,
            bubbleBuilder: (context) =>
                const TutorialTextBubble(text: 'Step 2'),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TutorialEngine(
              controller: controller,
              child: Center(
                child: ElevatedButton(
                  key: key,
                  onPressed: () {},
                  child: const Text('Target button'),
                ),
              ),
            ),
          ),
        ),
      );

      controller.start();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Target button'), warnIfMissed: false);
      await tester.pump();
      await tester.tap(find.text('Target button'), warnIfMissed: false);
      await tester.pump();

      expect(callCount, 1);
      expect(controller.currentIndex, 0);

      completer.complete();
      await tester.pumpAndSettle();

      expect(callCount, 1);
      expect(controller.currentIndex, 1);
    });

    testWidgets(
        'stale target tap completion does not advance after manual step change',
        (tester) async {
      final completer = Completer<void>();
      final key = GlobalKey();
      final controller = TutorialEngineController(
        steps: [
          TutorialStep(
            targetKey: key,
            behavior: TutorialStepBehavior(
              allowTargetTap: false,
              onTargetTap: (context) async {
                await completer.future;
              },
              advanceOnTargetTap: true,
            ),
            bubbleBuilder: (context) =>
                const TutorialTextBubble(text: 'Step 1'),
          ),
          TutorialStep(
            targetKey: key,
            bubbleBuilder: (context) =>
                const TutorialTextBubble(text: 'Step 2'),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TutorialEngine(
              controller: controller,
              child: Center(
                child: ElevatedButton(
                  key: key,
                  onPressed: () {},
                  child: const Text('Target button'),
                ),
              ),
            ),
          ),
        ),
      );

      controller.start();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Target button'), warnIfMissed: false);
      await tester.pump();

      controller.advance();
      await tester.pumpAndSettle();
      completer.complete();
      await tester.pumpAndSettle();

      expect(controller.currentIndex, 1);
      expect(find.text('Step 2'), findsOneWidget);
    });
  });
}
