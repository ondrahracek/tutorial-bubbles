import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tutorial_bubbles/tutorial_bubbles.dart';

void main() {
  test(
      'TutorialEngineController accepts a non-empty ordered list of TutorialStep instances',
      () {
    final key1 = GlobalKey();
    final key2 = GlobalKey();

    final steps = [
      TutorialStep(
        targetKey: key1,
        bubbleBuilder: (context) => const Text('Step 1'),
      ),
      TutorialStep(
        targetKey: key2,
        bubbleBuilder: (context) => const Text('Step 2'),
      ),
    ];

    final controller = TutorialEngineController(steps: steps);

    expect(controller.steps, hasLength(2));
    expect(controller.steps[0].targetKey, key1);
    expect(controller.steps[1].targetKey, key2);
  });

  test(
      'TutorialEngineController does not start automatically and requires explicit start',
      () {
    final key1 = GlobalKey();
    final key2 = GlobalKey();

    final steps = [
      TutorialStep(
        targetKey: key1,
        bubbleBuilder: (context) => const Text('Step 1'),
      ),
      TutorialStep(
        targetKey: key2,
        bubbleBuilder: (context) => const Text('Step 2'),
      ),
    ];

    final controller = TutorialEngineController(steps: steps);

    expect(controller.isStarted, isFalse);
    expect(controller.isStartedListenable.value, isFalse);

    controller.start();

    expect(controller.isStarted, isTrue);
    expect(controller.isStartedListenable.value, isTrue);

    // Calling start again should be a no-op.
    controller.start();
    expect(controller.isStarted, isTrue);
  });

  test('TutorialEngineController rejects an empty list of steps', () {
    expect(
      () => TutorialEngineController(steps: const []),
      throwsA(isA<AssertionError>()),
    );
  });

  test(
      'TutorialEngineController executes steps in order and advances when advance is called',
      () {
    final key1 = GlobalKey();
    final key2 = GlobalKey();
    final key3 = GlobalKey();

    final steps = [
      TutorialStep(
        targetKey: key1,
        bubbleBuilder: (context) => const Text('Step 1'),
      ),
      TutorialStep(
        targetKey: key2,
        bubbleBuilder: (context) => const Text('Step 2'),
      ),
      TutorialStep(
        targetKey: key3,
        bubbleBuilder: (context) => const Text('Step 3'),
      ),
    ];

    final controller = TutorialEngineController(steps: steps);

    expect(controller.currentIndex, 0);
    expect(controller.currentStep.targetKey, key1);
    expect(controller.isLastStep, isFalse);
    expect(controller.isFinished, isFalse);

    final firstAdvanceChanged = controller.advance();
    expect(firstAdvanceChanged, isTrue);
    expect(controller.currentIndex, 1);
    expect(controller.currentStep.targetKey, key2);
    expect(controller.isLastStep, isFalse);
    expect(controller.isFinished, isFalse);

    final secondAdvanceChanged = controller.advance();
    expect(secondAdvanceChanged, isTrue);
    expect(controller.currentIndex, 2);
    expect(controller.currentStep.targetKey, key3);
    expect(controller.isLastStep, isTrue);
    expect(controller.isFinished, isFalse);

    final thirdAdvanceChanged = controller.advance();
    expect(thirdAdvanceChanged, isFalse);
    expect(controller.currentIndex, 2);
    expect(controller.isLastStep, isTrue);
    expect(controller.isFinished, isTrue);

    final fourthAdvanceChanged = controller.advance();
    expect(fourthAdvanceChanged, isFalse);
    expect(controller.currentIndex, 2);
    expect(controller.isFinished, isTrue);
  });

  test(
      'TutorialEngineController exposes totalSteps and notifies when the active step changes',
      () {
    final key1 = GlobalKey();
    final key2 = GlobalKey();
    final key3 = GlobalKey();

    final steps = [
      TutorialStep(
        targetKey: key1,
        bubbleBuilder: (context) => const Text('Step 1'),
      ),
      TutorialStep(
        targetKey: key2,
        bubbleBuilder: (context) => const Text('Step 2'),
      ),
      TutorialStep(
        targetKey: key3,
        bubbleBuilder: (context) => const Text('Step 3'),
      ),
    ];

    final controller = TutorialEngineController(steps: steps);

    expect(controller.totalSteps, 3);
    expect(controller.currentIndex, 0);
    expect(controller.currentIndexListenable.value, 0);

    final recordedIndices = <int>[];
    controller.currentIndexListenable.addListener(() {
      recordedIndices.add(controller.currentIndexListenable.value);
    });

    final firstAdvanceChanged = controller.advance();
    expect(firstAdvanceChanged, isTrue);
    expect(controller.currentIndex, 1);
    expect(recordedIndices, [1]);

    final secondAdvanceChanged = controller.advance();
    expect(secondAdvanceChanged, isTrue);
    expect(controller.currentIndex, 2);
    expect(recordedIndices, [1, 2]);

    final thirdAdvanceChanged = controller.advance();
    expect(thirdAdvanceChanged, isFalse);
    expect(controller.currentIndex, 2);
    expect(recordedIndices, [1, 2]);
  });

  test(
      'TutorialEngineController provides programmatic skip control that advances without requiring target action',
      () {
    final key1 = GlobalKey();
    final key2 = GlobalKey();

    final steps = [
      TutorialStep(
        targetKey: key1,
        bubbleBuilder: (context) => const Text('Step 1'),
      ),
      TutorialStep(
        targetKey: key2,
        bubbleBuilder: (context) => const Text('Step 2'),
      ),
    ];

    final controller = TutorialEngineController(steps: steps);

    expect(controller.currentIndex, 0);
    expect(controller.currentStep.targetKey, key1);
    expect(controller.isFinished, isFalse);

    final skipped = controller.skip();
    expect(skipped, isTrue);
    expect(controller.currentIndex, 1);
    expect(controller.currentStep.targetKey, key2);
    expect(controller.isLastStep, isTrue);
    expect(controller.isFinished, isFalse);

    final skippedPastEnd = controller.skip();
    expect(skippedPastEnd, isFalse);
    expect(controller.currentIndex, 1);
    expect(controller.isFinished, isTrue);
  });

  test(
      'TutorialEngineController can be finished programmatically and prevents further advancement or skipping',
      () {
    final key1 = GlobalKey();
    final key2 = GlobalKey();

    final steps = [
      TutorialStep(
        targetKey: key1,
        bubbleBuilder: (context) => const Text('Step 1'),
      ),
      TutorialStep(
        targetKey: key2,
        bubbleBuilder: (context) => const Text('Step 2'),
      ),
    ];

    final controller = TutorialEngineController(steps: steps);

    expect(controller.isFinished, isFalse);
    expect(controller.currentIndex, 0);

    controller.finish();

    expect(controller.isFinished, isTrue);
    expect(controller.currentIndex, 0);

    final advancedAfterFinish = controller.advance();
    final skippedAfterFinish = controller.skip();

    expect(advancedAfterFinish, isFalse);
    expect(skippedAfterFinish, isFalse);
    expect(controller.currentIndex, 0);
    expect(controller.isFinished, isTrue);
  });

  test(
       'TutorialEngineController goBack moves to previous step and does nothing on first step or when finished',
       () {
    final key1 = GlobalKey();
    final key2 = GlobalKey();
    final key3 = GlobalKey();
    final steps = [
      TutorialStep(
        targetKey: key1,
        bubbleBuilder: (context) => const Text('Step 1'),
      ),
      TutorialStep(
        targetKey: key2,
        bubbleBuilder: (context) => const Text('Step 2'),
      ),
      TutorialStep(
        targetKey: key3,
        bubbleBuilder: (context) => const Text('Step 3'),
      ),
    ];
    final controller = TutorialEngineController(steps: steps);

    expect(controller.currentIndex, 0);
    final goBackFromFirst = controller.goBack();
    expect(goBackFromFirst, isFalse);
    expect(controller.currentIndex, 0);

    controller.advance();
    expect(controller.currentIndex, 1);
    expect(controller.currentStep.targetKey, key2);
    final goBackFromSecond = controller.goBack();
    expect(goBackFromSecond, isTrue);
    expect(controller.currentIndex, 0);
    expect(controller.currentStep.targetKey, key1);

    controller.advance();
    controller.advance();
    expect(controller.currentIndex, 2);
    controller.goBack();
    expect(controller.currentIndex, 1);
    controller.goBack();
    expect(controller.currentIndex, 0);

    controller.advance();
    controller.finish();
    expect(controller.isFinished, isTrue);
    final goBackWhenFinished = controller.goBack();
    expect(goBackWhenFinished, isFalse);
    expect(controller.currentIndex, 1);
  });

  test('TutorialEngineController jumpTo ignores out of range indices and does not notify', () {
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

    var notifications = 0;
    controller.currentIndexListenable.addListener(() {
      notifications += 1;
    });

    controller.jumpTo(-1);
    controller.jumpTo(99);

    expect(controller.currentIndex, 0);
    expect(notifications, 0);
  });

  test('TutorialEngineController jumpTo current index is a no-op', () {
    final key = GlobalKey();
    final controller = TutorialEngineController(
      steps: [
        TutorialStep(
          targetKey: key,
          bubbleBuilder: (context) => const Text('Step 1'),
        ),
      ],
    );

    var notifications = 0;
    controller.currentIndexListenable.addListener(() {
      notifications += 1;
    });

    controller.jumpTo(0);

    expect(controller.currentIndex, 0);
    expect(notifications, 0);
  });

  test('TutorialEngineController jumpTo valid index updates current step and notifies once', () {
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

    var notifications = 0;
    controller.currentIndexListenable.addListener(() {
      notifications += 1;
    });

    controller.jumpTo(1);

    expect(controller.currentIndex, 1);
    expect(controller.currentStep.targetKey, key2);
    expect(notifications, 1);
  });

  test('TutorialEngineController start only notifies the started listenable once', () {
    final key = GlobalKey();
    final controller = TutorialEngineController(
      steps: [
        TutorialStep(
          targetKey: key,
          bubbleBuilder: (context) => const Text('Step 1'),
        ),
      ],
    );

    var notifications = 0;
    controller.isStartedListenable.addListener(() {
      notifications += 1;
    });

    controller.start();
    controller.start();

    expect(controller.isStarted, isTrue);
    expect(notifications, 1);
  });

  test('TutorialEngineController records completion reason for advance, skip, and finish', () {
    final key = GlobalKey();

    final advanceController = TutorialEngineController(
      steps: [
        TutorialStep(
          targetKey: key,
          bubbleBuilder: (context) => const Text('Step 1'),
        ),
      ],
    );
    advanceController.advance();
    expect(advanceController.lastCompletionReason, TutorialCompletionReason.completed);

    final skipController = TutorialEngineController(
      steps: [
        TutorialStep(
          targetKey: key,
          bubbleBuilder: (context) => const Text('Step 1'),
        ),
      ],
    );
    skipController.skip();
    expect(skipController.lastCompletionReason, TutorialCompletionReason.skipped);

    final finishController = TutorialEngineController(
      steps: [
        TutorialStep(
          targetKey: key,
          bubbleBuilder: (context) => const Text('Step 1'),
        ),
      ],
    );
    finishController.finish();
    expect(finishController.lastCompletionReason, TutorialCompletionReason.finished);
  });
}

