import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tutorial_bubbles/tutorial_bubbles.dart';

void main() {
  testWidgets(
      'TutorialEngine persists progress and resumes from where it left off across app restarts',
      (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    final key = GlobalKey();

    final steps = [
      TutorialStep(
        targetKey: key,
        bubbleBuilder: (context) => const TutorialTextBubble(
          text: 'Step 1',
        ),
      ),
      TutorialStep(
        targetKey: key,
        bubbleBuilder: (context) => const TutorialTextBubble(
          text: 'Step 2',
        ),
      ),
      TutorialStep(
        targetKey: key,
        bubbleBuilder: (context) => const TutorialTextBubble(
          text: 'Step 3',
        ),
      ),
      TutorialStep(
        targetKey: key,
        bubbleBuilder: (context) => const TutorialTextBubble(
          text: 'Step 4',
        ),
      ),
    ];

    const tutorialId = 'storage-test-tutorial';

    final controller = TutorialEngineController(steps: steps);

    await tester.pumpWidget(
      MaterialApp(
        home: TutorialEngine(
          controller: controller,
          persistenceId: tutorialId,
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

    expect(controller.currentIndex, 0);

    controller.advance();
    controller.advance();
    controller.advance();
    await tester.pumpAndSettle();

    expect(controller.currentIndex, 3);

    final savedIndex = await TutorialProgressStorage.readIndex(tutorialId);
    expect(savedIndex, 3);

    // Simulate an app restart by creating a new controller and restoring it
    // from the saved index.
    final resumedController = TutorialEngineController(steps: steps);
    expect(resumedController.currentIndex, 0);

    resumedController.jumpTo(savedIndex!);
    expect(resumedController.currentIndex, 3);
  });

  testWidgets(
      'Clearing saved tutorial progress causes a new engine to restart from the first step',
      (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    final key = GlobalKey();

    final steps = [
      TutorialStep(
        targetKey: key,
        bubbleBuilder: (context) => const TutorialTextBubble(
          text: 'Step 1',
        ),
      ),
      TutorialStep(
        targetKey: key,
        bubbleBuilder: (context) => const TutorialTextBubble(
          text: 'Step 2',
        ),
      ),
    ];

    const tutorialId = 'storage-reset-tutorial';

    final controller = TutorialEngineController(steps: steps);

    await tester.pumpWidget(
      MaterialApp(
        home: TutorialEngine(
          controller: controller,
          persistenceId: tutorialId,
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

    controller.advance();
    await tester.pumpAndSettle();

    expect(controller.currentIndex, 1);

    // Manually clear persisted progress to simulate a reset.
    await TutorialProgressStorage.clear(tutorialId);

    final resetController = TutorialEngineController(steps: steps);

    await tester.pumpWidget(
      MaterialApp(
        home: TutorialEngine(
          controller: resetController,
          persistenceId: tutorialId,
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

    resetController.start();
    await tester.pumpAndSettle();

    expect(resetController.currentIndex, 0);
  });

  testWidgets(
      'Progress is only saved at configurable checkpoint steps',
      (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    final key = GlobalKey();

    final steps = List.generate(
      6,
      (i) => TutorialStep(
        targetKey: key,
        bubbleBuilder: (context) =>
            TutorialTextBubble(text: 'Step ${i + 1}'),
      ),
    );

    const tutorialId = 'checkpoint-tutorial';

    final controller = TutorialEngineController(steps: steps);

    await tester.pumpWidget(
      MaterialApp(
        home: TutorialEngine(
          controller: controller,
          persistenceId: tutorialId,
          checkpointSteps: const {2, 5},
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

    expect(controller.currentIndex, 0);

    controller.advance();
    await tester.pumpAndSettle();
    expect(controller.currentIndex, 1);
    expect(await TutorialProgressStorage.readIndex(tutorialId), isNull);

    controller.advance();
    await tester.pumpAndSettle();
    expect(controller.currentIndex, 2);
    expect(await TutorialProgressStorage.readIndex(tutorialId), 2);

    controller.advance();
    await tester.pumpAndSettle();
    expect(controller.currentIndex, 3);
    expect(await TutorialProgressStorage.readIndex(tutorialId), 2);

    controller.advance();
    await tester.pumpAndSettle();
    expect(controller.currentIndex, 4);
    expect(await TutorialProgressStorage.readIndex(tutorialId), 2);

    controller.advance();
    await tester.pumpAndSettle();
    expect(controller.currentIndex, 5);
    expect(await TutorialProgressStorage.readIndex(tutorialId), 5);

    await TutorialProgressStorage.clear(tutorialId);
  });

  testWidgets(
      'With checkpointSteps empty, progress is never saved on step change',
      (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    final key = GlobalKey();

    final steps = [
      TutorialStep(
        targetKey: key,
        bubbleBuilder: (context) =>
            const TutorialTextBubble(text: 'Step 1'),
      ),
      TutorialStep(
        targetKey: key,
        bubbleBuilder: (context) =>
            const TutorialTextBubble(text: 'Step 2'),
      ),
    ];

    const tutorialId = 'no-checkpoint-tutorial';

    final controller = TutorialEngineController(steps: steps);

    await tester.pumpWidget(
      MaterialApp(
        home: TutorialEngine(
          controller: controller,
          persistenceId: tutorialId,
          checkpointSteps: const {},
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

    controller.advance();
    await tester.pumpAndSettle();
    expect(controller.currentIndex, 1);
    expect(await TutorialProgressStorage.readIndex(tutorialId), isNull);

    await TutorialProgressStorage.clear(tutorialId);
  });
}

