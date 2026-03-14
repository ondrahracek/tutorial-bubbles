import 'package:flutter_test/flutter_test.dart';
import 'package:tutorial_bubbles/tutorial_bubbles.dart';

void main() {
  group('TutorialPersistence', () {
    test('derives a default completed key', () {
      const persistence = TutorialPersistence(id: 'dashboard_tutorial');

      expect(persistence.effectiveCompletedKey, 'dashboard_tutorial_completed');
    });

    test('defaults completionPersistencePolicy to completedOnly', () {
      const persistence = TutorialPersistence(id: 'dashboard_tutorial');

      expect(
        persistence.completionPersistencePolicy,
        TutorialCompletionPersistencePolicy.completedOnly,
      );
    });
  });
}
