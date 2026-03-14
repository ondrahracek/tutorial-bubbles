// ignore_for_file: deprecated_member_use_from_same_package

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tutorial_bubbles/tutorial_bubbles.dart';

void main() {
  group('TutorialTarget', () {
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
        target:
            TutorialTarget.rect((context) => const Rect.fromLTWH(1, 2, 3, 4)),
        bubbleBuilder: (context) => const Text('Step'),
      );

      expect(step.target, isA<RectTutorialTarget>());
      expect(() => step.targetKey, throwsA(isA<StateError>()));
    });
  });
}
