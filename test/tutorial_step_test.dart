import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tutorial_bubbles/tutorial_bubbles.dart';

void main() {
  group('TutorialStep', () {
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
  });
}
