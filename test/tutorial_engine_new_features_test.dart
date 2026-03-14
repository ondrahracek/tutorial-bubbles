import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tutorial_bubbles/tutorial_bubbles.dart';

void main() {
  group('TutorialEngine new features', () {
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

      final overlay = tester.widget<TutorialBubbleOverlay>(
        find.byType(TutorialBubbleOverlay),
      );

      expect(find.text('Rect step'), findsOneWidget);
      expect(overlay.targetRect, targetRect);
    });

    testWidgets('recomputes rect targets when the hosting widget rebuilds',
        (tester) async {
      final hostKey = GlobalKey<_RectTargetHostState>();

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

    testWidgets('beforeShow runs before measurement and can prepare the target',
        (tester) async {
      final hostKey = GlobalKey<_BeforeShowHostState>();
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

    testWidgets('step behavior can enable bubble advancement per step',
        (tester) async {
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

    testWidgets('step behavior can enable overlay advancement per step',
        (tester) async {
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
        'step behavior can allow outside interactions when blockOutsideTarget is false',
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

    testWidgets(
        'step behavior can block target taps when allowTargetTap is false',
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

    testWidgets('step behavior target and overlay callbacks are invoked',
        (tester) async {
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

    testWidgets('TutorialPersistence manual mode does not auto-save',
        (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      final key = GlobalKey();
      final controller = TutorialEngineController(
        steps: [
          TutorialStep(
              targetKey: key, bubbleBuilder: (context) => const Text('1')),
          TutorialStep(
              targetKey: key, bubbleBuilder: (context) => const Text('2')),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: TutorialEngine(
            controller: controller,
            persistence: const TutorialPersistence(
              id: 'manual-tutorial',
              saveStrategy: TutorialSaveStrategy.manual,
            ),
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
      controller.advance();
      await tester.pumpAndSettle();

      expect(
          await TutorialProgressStorage.readIndex('manual-tutorial'), isNull);
    });

    testWidgets(
        'completed persistence suppresses the tutorial on future launches',
        (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      final key = GlobalKey();
      const persistence = TutorialPersistence(
        id: 'completed-tutorial',
        clearOnComplete: true,
      );

      final controller = TutorialEngineController(
        steps: [
          TutorialStep(
              targetKey: key,
              bubbleBuilder: (context) => const Text('Only step')),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: TutorialEngine(
            controller: controller,
            persistence: persistence,
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
      controller.advance();
      await tester.pumpAndSettle();

      expect(
        await TutorialProgressStorage.readCompleted(
            persistence.effectiveCompletedKey),
        isTrue,
      );

      final resumedController = TutorialEngineController(
        steps: [
          TutorialStep(
              targetKey: key,
              bubbleBuilder: (context) => const Text('Only step')),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: TutorialEngine(
            controller: resumedController,
            persistence: persistence,
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
      await tester.pumpAndSettle();

      resumedController.start();
      await tester.pumpAndSettle();

      expect(find.byType(TutorialBubbleOverlay), findsNothing);
    });

    testWidgets('global bubbleCornerRadius is applied to engine bubbles',
        (tester) async {
      final key = GlobalKey();
      final controller = TutorialEngineController(
        steps: [
          TutorialStep(
            targetKey: key,
            bubbleBuilder: (context) =>
                const TutorialTextBubble(text: 'Rounded'),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: TutorialEngine(
            controller: controller,
            globalVisuals: const TutorialVisuals(bubbleCornerRadius: 28),
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

      final decoratedBox =
          tester.widget<DecoratedBox>(find.byType(DecoratedBox).first);
      final decoration = decoratedBox.decoration as BoxDecoration;
      expect(decoration.borderRadius, BorderRadius.circular(28));
    });
  });
}

class RectTargetHost extends StatefulWidget {
  const RectTargetHost({super.key});

  @override
  State<RectTargetHost> createState() => _RectTargetHostState();
}

class _RectTargetHostState extends State<RectTargetHost> {
  late Rect targetRect = const Rect.fromLTWH(32, 48, 96, 40);
  late final TutorialEngineController controller = TutorialEngineController(
    steps: [
      TutorialStep(
        target: TutorialTarget.rect((context) => targetRect),
        bubbleBuilder: (context) =>
            const TutorialTextBubble(text: 'Rect target'),
      ),
    ],
  );

  void updateTargetRect(Rect rect) {
    setState(() {
      targetRect = rect;
    });
  }

  @override
  Widget build(BuildContext context) {
    return TutorialEngine(
      controller: controller,
      child: const SizedBox.expand(),
    );
  }
}

class BeforeShowHost extends StatefulWidget {
  const BeforeShowHost({
    super.key,
    required this.controller,
    required this.targetKey,
  });

  final TutorialEngineController controller;
  final GlobalKey targetKey;

  @override
  State<BeforeShowHost> createState() => _BeforeShowHostState();
}

class _BeforeShowHostState extends State<BeforeShowHost> {
  bool _showTarget = false;

  void showTarget() {
    if (!mounted) {
      return;
    }
    setState(() {
      _showTarget = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return TutorialEngine(
      controller: widget.controller,
      child: Center(
        child: _showTarget
            ? SizedBox(
                key: widget.targetKey,
                width: 80,
                height: 40,
                child: const ColoredBox(color: Colors.blue),
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}
