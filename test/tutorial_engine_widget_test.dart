import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tutorial_bubbles/tutorial_bubbles.dart';

void main() {
  testWidgets(
      'TutorialEngine can span multiple screens by overlaying a Navigator and targeting widgets on different routes',
      (tester) async {
    final firstTargetKey = GlobalKey();
    final secondTargetKey = GlobalKey();

    final controller = TutorialEngineController(
      steps: [
        TutorialStep(
          targetKey: firstTargetKey,
          bubbleBuilder: (context) => const Text('First step'),
        ),
        TutorialStep(
          targetKey: secondTargetKey,
          bubbleBuilder: (context) => const Text('Second step'),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) {
          return TutorialEngine(
            controller: controller,
            child: child ?? const SizedBox.shrink(),
          );
        },
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case '/second':
              return MaterialPageRoute<void>(
                builder: (context) {
                  return Scaffold(
                    body: Center(
                      child: ElevatedButton(
                        key: secondTargetKey,
                        onPressed: () {},
                        child: const Text('Second screen target'),
                      ),
                    ),
                  );
                },
                settings: settings,
              );
            case '/':
            default:
              return MaterialPageRoute<void>(
                builder: (context) {
                  return Scaffold(
                    body: Center(
                      child: ElevatedButton(
                        key: firstTargetKey,
                        onPressed: () {
                          Navigator.of(context).pushNamed<void>('/second');
                          controller.advance();
                        },
                        child: const Text('First screen target'),
                      ),
                    ),
                  );
                },
                settings: settings,
              );
          }
        },
      ),
    );

    await tester.pumpAndSettle();

    // Engine has steps configured but has not been started yet; start it so the
    // overlay becomes visible for the first step.
    controller.start();
    await tester.pumpAndSettle();

    // Initially, the overlay highlights the first route's target.
    expect(find.byType(TutorialBubbleOverlay), findsOneWidget);
    expect(find.text('First step'), findsOneWidget);
    expect(find.text('Second step'), findsNothing);

    // Tapping the first target navigates to the second route; once navigation
    // completes, the controller advances so the next step can target a widget
    // on the new screen.
    await tester.tap(find.byKey(firstTargetKey), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.byType(TutorialBubbleOverlay), findsOneWidget);
    expect(find.text('First step'), findsNothing);
    expect(find.text('Second step'), findsOneWidget);
    expect(find.byKey(secondTargetKey), findsOneWidget);
  });

  testWidgets(
      'TutorialEngine hides the overlay when the last step completes',
      (tester) async {
    final key1 = GlobalKey();
    final key2 = GlobalKey();

    final controller = TutorialEngineController(
      steps: [
        TutorialStep(
          targetKey: key1,
          bubbleBuilder: (context) => const Text('Step 1'),
        ),
        TutorialStep(
          targetKey: key2,
          bubbleBuilder: (context) => const Text('Step 2'),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: TutorialEngine(
          controller: controller,
          child: Column(
            children: [
              ElevatedButton(
                key: key1,
                onPressed: () {},
                child: const Text('First'),
              ),
              ElevatedButton(
                key: key2,
                onPressed: () {},
                child: const Text('Second'),
              ),
            ],
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Start the engine so the overlay becomes visible for the initial step.
    controller.start();
    await tester.pumpAndSettle();
    expect(find.byType(TutorialBubbleOverlay), findsOneWidget);

    // Advance to the second (last) step.
    controller.advance();
    await tester.pumpAndSettle();
    expect(find.byType(TutorialBubbleOverlay), findsOneWidget);

    // Advancing past the last step finishes the tutorial and hides the overlay.
    controller.advance();
    await tester.pumpAndSettle();
    expect(find.byType(TutorialBubbleOverlay), findsNothing);
  });

  testWidgets(
      'TutorialEngine hides the overlay when the tutorial is finished early',
      (tester) async {
    final key1 = GlobalKey();
    final key2 = GlobalKey();

    final controller = TutorialEngineController(
      steps: [
        TutorialStep(
          targetKey: key1,
          bubbleBuilder: (context) => const Text('Step 1'),
        ),
        TutorialStep(
          targetKey: key2,
          bubbleBuilder: (context) => const Text('Step 2'),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: TutorialEngine(
          controller: controller,
          child: Column(
            children: [
              ElevatedButton(
                key: key1,
                onPressed: () {},
                child: const Text('First'),
              ),
              ElevatedButton(
                key: key2,
                onPressed: () {},
                child: const Text('Second'),
              ),
            ],
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Start the engine so the overlay becomes visible for the initial step.
    controller.start();
    await tester.pumpAndSettle();
    expect(find.byType(TutorialBubbleOverlay), findsOneWidget);

    // Finishing early hides the overlay without needing to reach the last step.
    controller.finish();
    await tester.pumpAndSettle();
    expect(find.byType(TutorialBubbleOverlay), findsNothing);
  });

  testWidgets(
      'TutorialEngine applies global visual defaults to the overlay and bubble',
      (tester) async {
    final key = GlobalKey();

    final controller = TutorialEngineController(
      steps: [
        TutorialStep(
          targetKey: key,
          bubbleBuilder: (context) => const TutorialTextBubble(
            text: 'Step',
          ),
        ),
      ],
    );

    const overlayColor = Color(0x66000000);
    const bubbleColor = Color(0xFF123456);
    const shineColor = Color(0x80FFFFFF);

    await tester.pumpWidget(
      MaterialApp(
        home: TutorialEngine(
          controller: controller,
          globalVisuals: const TutorialVisuals(
            overlayColor: overlayColor,
            bubbleBackgroundColor: bubbleColor,
            arrowEnabled: false,
            arrowHeadLength: 12,
            bubbleHaloEnabled: true,
            targetShineEnabled: true,
            targetShineColor: shineColor,
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

    await tester.pumpAndSettle();

    controller.start();
    await tester.pumpAndSettle();

    final overlay = tester.widget<TutorialBubbleOverlay>(
      find.byType(TutorialBubbleOverlay),
    );

    expect(overlay.overlayColor, overlayColor);
    expect(overlay.backgroundColor, bubbleColor);
    expect(overlay.arrowEnabled, isFalse);
    expect(overlay.arrowHeadLength, 12);
    expect(overlay.bubbleHaloEnabled, isTrue);
    expect(overlay.targetShineEnabled, isTrue);
    expect(overlay.targetShineColor, shineColor);
  });

  testWidgets(
      'Per-step TutorialVisuals overrides global defaults for overlay and arrow',
      (tester) async {
    final key = GlobalKey();

    final controller = TutorialEngineController(
      steps: [
        TutorialStep(
          targetKey: key,
          bubbleBuilder: (context) => const Text('Visual step'),
          visuals: const TutorialVisuals(
            overlayColor: Color(0x22000000),
            arrowEnabled: false,
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: TutorialEngine(
          controller: controller,
          globalVisuals: const TutorialVisuals(
            overlayColor: Color(0x88000000),
            arrowEnabled: true,
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

    await tester.pumpAndSettle();

    controller.start();
    await tester.pumpAndSettle();

    final overlay = tester.widget<TutorialBubbleOverlay>(
      find.byType(TutorialBubbleOverlay),
    );

    expect(overlay.overlayColor, const Color(0x22000000));
    expect(overlay.arrowEnabled, isFalse);
  });

  testWidgets(
      'TutorialEngine applies global text style defaults that can be overridden per step',
      (tester) async {
    final key = GlobalKey();

    final controller = TutorialEngineController(
      steps: [
        TutorialStep(
          targetKey: key,
          bubbleBuilder: (context) => const TutorialTextBubble(
            text: 'Visual step',
          ),
        ),
      ],
    );

    const globalTextStyle = TextStyle(
      color: Color(0xFF0099FF),
      fontSize: 20,
      fontWeight: FontWeight.w600,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: TutorialEngine(
          controller: controller,
          globalVisuals: const TutorialVisuals(
            textStyle: globalTextStyle,
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

    await tester.pumpAndSettle();

    controller.start();
    await tester.pumpAndSettle();

    final textWidget = tester.widget<Text>(find.text('Visual step'));
    final style = textWidget.style!;

    expect(style.color, globalTextStyle.color);
    expect(style.fontSize, globalTextStyle.fontSize);
    expect(style.fontWeight, globalTextStyle.fontWeight);
  });

  testWidgets(
      'TutorialEngineController provides onComplete callback with completed when last step is advanced through',
      (tester) async {
    final key = GlobalKey();
    TutorialCompletionReason? capturedReason;
    final controller = TutorialEngineController(
      steps: [
        TutorialStep(
          targetKey: key,
          bubbleBuilder: (context) =>
              const TutorialTextBubble(text: 'Only step'),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: TutorialEngine(
          controller: controller,
          onComplete: (reason) {
            capturedReason = reason;
          },
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
    expect(capturedReason, isNull);

    controller.advance();
    await tester.pumpAndSettle();
    expect(capturedReason, TutorialCompletionReason.completed);
  });

  testWidgets(
      'TutorialEngineController provides onComplete callback with skipped when last step is skipped',
      (tester) async {
    final key = GlobalKey();
    TutorialCompletionReason? capturedReason;
    final controller = TutorialEngineController(
      steps: [
        TutorialStep(
          targetKey: key,
          bubbleBuilder: (context) =>
              const TutorialTextBubble(text: 'Only step'),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: TutorialEngine(
          controller: controller,
          onComplete: (reason) {
            capturedReason = reason;
          },
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
    expect(capturedReason, isNull);

    controller.skip();
    await tester.pumpAndSettle();
    expect(capturedReason, TutorialCompletionReason.skipped);
  });

  testWidgets(
      'TutorialEngineController provides onComplete callback with finished when finish() is called',
      (tester) async {
    final key = GlobalKey();
    TutorialCompletionReason? capturedReason;
    final controller = TutorialEngineController(
      steps: [
        TutorialStep(
          targetKey: key,
          bubbleBuilder: (context) =>
              const TutorialTextBubble(text: 'Step'),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: TutorialEngine(
          controller: controller,
          onComplete: (reason) {
            capturedReason = reason;
          },
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
    expect(capturedReason, isNull);

    controller.finish();
    await tester.pumpAndSettle();
    expect(capturedReason, TutorialCompletionReason.finished);
  });

  testWidgets(
      'TutorialEngine can advance when the bubble is tapped when configured',
      (tester) async {
    final key1 = GlobalKey();
    final key2 = GlobalKey();

    final controller = TutorialEngineController(
      steps: [
        TutorialStep(
          targetKey: key1,
          bubbleBuilder: (context) => const TutorialTextBubble(
            text: 'Step 1',
          ),
        ),
        TutorialStep(
          targetKey: key2,
          bubbleBuilder: (context) => const TutorialTextBubble(
            text: 'Step 2',
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: TutorialEngine(
          controller: controller,
          advanceOnBubbleTap: true,
          child: Column(
            children: [
              ElevatedButton(
                key: key1,
                onPressed: () {},
                child: const Text('First'),
              ),
              ElevatedButton(
                key: key2,
                onPressed: () {},
                child: const Text('Second'),
              ),
            ],
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    controller.start();
    await tester.pumpAndSettle();

    expect(controller.currentIndex, 0);
    expect(find.text('Step 1'), findsOneWidget);

    await tester.tap(find.text('Step 1'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(controller.currentIndex, 1);
  });

  testWidgets(
      'TutorialEngine shows previous step when controller goBack is called',
      (tester) async {
    final key1 = GlobalKey();
    final key2 = GlobalKey();
    final controller = TutorialEngineController(
      steps: [
        TutorialStep(
          targetKey: key1,
          bubbleBuilder: (context) => const TutorialTextBubble(
            text: 'Back step 1',
          ),
        ),
        TutorialStep(
          targetKey: key2,
          bubbleBuilder: (context) => const TutorialTextBubble(
            text: 'Back step 2',
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: TutorialEngine(
          controller: controller,
          child: Column(
            children: [
              ElevatedButton(
                key: key1,
                onPressed: () {},
                child: const Text('First'),
              ),
              ElevatedButton(
                key: key2,
                onPressed: () {},
                child: const Text('Second'),
              ),
            ],
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    controller.start();
    await tester.pumpAndSettle();

    expect(find.text('Back step 1'), findsOneWidget);
    controller.advance();
    await tester.pump();
    await tester.pumpAndSettle();
    expect(controller.currentIndex, 1);

    controller.goBack();
    await tester.pump();
    await tester.pumpAndSettle();
    expect(controller.currentIndex, 0);
    expect(find.text('Back step 1'), findsOneWidget);
  });

  testWidgets(
      'TutorialEngine can advance when tapping the dark overlay background when configured',
      (tester) async {
    final key1 = GlobalKey();
    final key2 = GlobalKey();

    final controller = TutorialEngineController(
      steps: [
        TutorialStep(
          targetKey: key1,
          bubbleBuilder: (context) => const TutorialTextBubble(
            text: 'Overlay step 1',
          ),
        ),
        TutorialStep(
          targetKey: key2,
          bubbleBuilder: (context) => const TutorialTextBubble(
            text: 'Overlay step 2',
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TutorialEngine(
            controller: controller,
            advanceOnOverlayTap: true,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton(
                    key: key1,
                    onPressed: () {},
                    child: const Text('First target'),
                  ),
                  ElevatedButton(
                    key: key2,
                    onPressed: () {},
                    child: const Text('Second target'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    controller.start();
    await tester.pumpAndSettle();

    expect(controller.currentIndex, 0);
    expect(find.text('Overlay step 1'), findsOneWidget);

    // Tap a point near the top-left corner, away from the highlighted target,
    // to simulate tapping the dark overlay background.
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(controller.currentIndex, 1);
  });

  testWidgets(
      'TutorialEngine gracefully waits for the current step target to appear on screen',
      (tester) async {
    final targetKey = GlobalKey();

    final controller = TutorialEngineController(
      steps: [
        TutorialStep(
          targetKey: targetKey,
          bubbleBuilder: (context) => const TutorialTextBubble(
            text: 'Delayed target step',
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: _DelayedTargetHost(
          controller: controller,
          targetKey: targetKey,
        ),
      ),
    );

    // Start the engine; initially the target is not yet built so the engine
    // should not crash and no overlay is shown.
    controller.start();
    await tester.pump();
    expect(find.byType(TutorialBubbleOverlay), findsNothing);

    // Make the target appear on screen, then pump frames so the engine can
    // resolve its layout and show the overlay for the current step.
    final hostState = tester.state<_DelayedTargetHostState>(
      find.byType(_DelayedTargetHost),
    );
    hostState.showTarget();
    await tester.pumpAndSettle();

    expect(find.byType(TutorialBubbleOverlay), findsOneWidget);
    expect(find.text('Delayed target step'), findsOneWidget);
  });
}

class _DelayedTargetHost extends StatefulWidget {
  const _DelayedTargetHost({
    required this.controller,
    required this.targetKey,
  });

  final TutorialEngineController controller;
  final GlobalKey targetKey;

  @override
  State<_DelayedTargetHost> createState() => _DelayedTargetHostState();
}

class _DelayedTargetHostState extends State<_DelayedTargetHost> {
  bool _showTarget = false;

  void showTarget() {
    if (mounted) {
      setState(() {
        _showTarget = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return TutorialEngine(
      controller: widget.controller,
      child: Center(
        child: _showTarget
            ? ElevatedButton(
                key: widget.targetKey,
                onPressed: () {},
                child: const Text('Delayed target'),
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}

