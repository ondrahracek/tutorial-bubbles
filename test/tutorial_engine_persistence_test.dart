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

  testWidgets('Progress is only saved at configurable checkpoint steps',
      (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    final key = GlobalKey();

    final steps = List.generate(
      6,
      (i) => TutorialStep(
        targetKey: key,
        bubbleBuilder: (context) => TutorialTextBubble(text: 'Step ${i + 1}'),
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
        bubbleBuilder: (context) => const TutorialTextBubble(text: 'Step 1'),
      ),
      TutorialStep(
        targetKey: key,
        bubbleBuilder: (context) => const TutorialTextBubble(text: 'Step 2'),
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

  testWidgets('Progress is cleared when the tutorial completes',
      (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    final key = GlobalKey();
    final controller = TutorialEngineController(
      steps: [
        TutorialStep(
          targetKey: key,
          bubbleBuilder: (context) =>
              const TutorialTextBubble(text: 'Only step'),
        ),
      ],
    );

    const tutorialId = 'completion-clear-tutorial';

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

    controller.start();
    await tester.pumpAndSettle();

    controller.advance();
    await tester.pumpAndSettle();

    expect(await TutorialProgressStorage.readIndex(tutorialId), isNull);
  });

  testWidgets('Null checkpointSteps saves progress on every step change',
      (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    final key = GlobalKey();
    final controller = TutorialEngineController(
      steps: [
        TutorialStep(
          targetKey: key,
          bubbleBuilder: (context) => const TutorialTextBubble(text: 'Step 1'),
        ),
        TutorialStep(
          targetKey: key,
          bubbleBuilder: (context) => const TutorialTextBubble(text: 'Step 2'),
        ),
      ],
    );

    const tutorialId = 'save-every-step-tutorial';

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

    controller.start();
    await tester.pumpAndSettle();
    controller.advance();
    await tester.pumpAndSettle();

    expect(await TutorialProgressStorage.readIndex(tutorialId), 1);
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

    expect(await TutorialProgressStorage.readIndex('manual-tutorial'), isNull);
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

  testWidgets(
      'completionPersistencePolicy completedOnly does not mark skipped tutorials completed',
      (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    final key = GlobalKey();
    const persistence = TutorialPersistence(
      id: 'skip-completed-only',
      completionPersistencePolicy:
          TutorialCompletionPersistencePolicy.completedOnly,
    );

    final controller = TutorialEngineController(
      steps: [
        TutorialStep(
          targetKey: key,
          bubbleBuilder: (context) => const Text('Only step'),
        ),
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
    controller.skip();
    await tester.pumpAndSettle();

    expect(
      await TutorialProgressStorage.readCompleted(
          persistence.effectiveCompletedKey),
      isFalse,
    );
  });

  testWidgets(
      'completionPersistencePolicy completedOnly does not mark finished tutorials completed',
      (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    final key = GlobalKey();
    const persistence = TutorialPersistence(
      id: 'finish-completed-only',
      completionPersistencePolicy:
          TutorialCompletionPersistencePolicy.completedOnly,
    );

    final controller = TutorialEngineController(
      steps: [
        TutorialStep(
          targetKey: key,
          bubbleBuilder: (context) => const Text('Only step'),
        ),
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
    controller.finish();
    await tester.pumpAndSettle();

    expect(
      await TutorialProgressStorage.readCompleted(
          persistence.effectiveCompletedKey),
      isFalse,
    );
  });

  testWidgets(
      'completionPersistencePolicy completedOrSkipped marks skipped tutorials completed',
      (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    final key = GlobalKey();
    const persistence = TutorialPersistence(
      id: 'skip-completed-or-skipped',
      completionPersistencePolicy:
          TutorialCompletionPersistencePolicy.completedOrSkipped,
    );

    final controller = TutorialEngineController(
      steps: [
        TutorialStep(
          targetKey: key,
          bubbleBuilder: (context) => const Text('Only step'),
        ),
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
    controller.skip();
    await tester.pumpAndSettle();

    expect(
      await TutorialProgressStorage.readCompleted(
          persistence.effectiveCompletedKey),
      isTrue,
    );
  });

  testWidgets(
      'completionPersistencePolicy always marks finished tutorials completed',
      (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    final key = GlobalKey();
    const persistence = TutorialPersistence(
      id: 'finish-always',
      completionPersistencePolicy: TutorialCompletionPersistencePolicy.always,
    );

    final controller = TutorialEngineController(
      steps: [
        TutorialStep(
          targetKey: key,
          bubbleBuilder: (context) => const Text('Only step'),
        ),
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
    controller.finish();
    await tester.pumpAndSettle();

    expect(
      await TutorialProgressStorage.readCompleted(
          persistence.effectiveCompletedKey),
      isTrue,
    );
  });

  testWidgets(
      'completionPersistencePolicy completedOrSkipped does not mark finished tutorials completed',
      (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    final key = GlobalKey();
    const persistence = TutorialPersistence(
      id: 'finish-completed-or-skipped',
      completionPersistencePolicy:
          TutorialCompletionPersistencePolicy.completedOrSkipped,
    );

    final controller = TutorialEngineController(
      steps: [
        TutorialStep(
          targetKey: key,
          bubbleBuilder: (context) => const Text('Only step'),
        ),
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
    controller.finish();
    await tester.pumpAndSettle();

    expect(
      await TutorialProgressStorage.readCompleted(
          persistence.effectiveCompletedKey),
      isFalse,
    );
  });

  testWidgets(
      'completionPersistencePolicy always marks skipped tutorials completed',
      (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    final key = GlobalKey();
    const persistence = TutorialPersistence(
      id: 'skip-always',
      completionPersistencePolicy: TutorialCompletionPersistencePolicy.always,
    );

    final controller = TutorialEngineController(
      steps: [
        TutorialStep(
          targetKey: key,
          bubbleBuilder: (context) => const Text('Only step'),
        ),
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
    controller.skip();
    await tester.pumpAndSettle();

    expect(
      await TutorialProgressStorage.readCompleted(
          persistence.effectiveCompletedKey),
      isTrue,
    );
  });
}
