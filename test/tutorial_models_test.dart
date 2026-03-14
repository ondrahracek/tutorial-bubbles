// ignore_for_file: deprecated_member_use_from_same_package

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tutorial_bubbles/tutorial_bubbles.dart';

void main() {
  test('TutorialStep accepts a key target', () {
    final key = GlobalKey();
    final step = TutorialStep(
      target: TutorialTarget.key(key),
      bubbleBuilder: (context) => const Text('Step'),
    );

    expect(step.target, isA<KeyTutorialTarget>());
    expect((step.target as KeyTutorialTarget).key, key);
    expect(step.targetKey, key);
  });

  test('TutorialStep accepts a rect target', () {
    final step = TutorialStep(
      target: TutorialTarget.rect((context) => const Rect.fromLTWH(1, 2, 3, 4)),
      bubbleBuilder: (context) => const Text('Step'),
    );

    expect(step.target, isA<RectTutorialTarget>());
    expect(
      () => step.targetKey,
      throwsA(isA<StateError>()),
    );
  });

  test('TutorialVisuals.merge includes bubbleCornerRadius', () {
    const base = TutorialVisuals(bubbleCornerRadius: 12);
    const overrides = TutorialVisuals(bubbleCornerRadius: 24);

    final merged = base.merge(overrides);

    expect(merged.bubbleCornerRadius, 24);
  });

  test('TutorialPersistence derives a default completed key', () {
    const persistence = TutorialPersistence(id: 'dashboard_tutorial');

    expect(persistence.effectiveCompletedKey, 'dashboard_tutorial_completed');
  });

  test('TutorialEngineController preserves step ids across navigation', () {
    final key = GlobalKey();
    final controller = TutorialEngineController(
      steps: [
        TutorialStep(
          id: 'welcome',
          targetKey: key,
          bubbleBuilder: (context) => const Text('Welcome'),
        ),
        TutorialStep(
          id: 'actions',
          targetKey: key,
          bubbleBuilder: (context) => const Text('Actions'),
        ),
      ],
    );

    expect(controller.currentStep.id, 'welcome');
    controller.advance();
    expect(controller.currentStep.id, 'actions');
    controller.goBack();
    expect(controller.currentStep.id, 'welcome');
  });
}
