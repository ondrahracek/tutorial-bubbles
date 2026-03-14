import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tutorial_bubbles/tutorial_bubbles.dart';

void main() {
  group('TutorialHighlightShape', () {
    test('rect contains points inside its rectangle', () {
      const shape = TutorialHighlightShape.rect();
      const rect = Rect.fromLTWH(10, 20, 100, 50);

      expect(shape.contains(const Offset(20, 30), rect), isTrue);
      expect(shape.contains(const Offset(9, 30), rect), isFalse);
      expect(shape.contains(const Offset(20, 71), rect), isFalse);
    });

    test('roundedRect rejects points clipped by the rounded corners', () {
      const shape = TutorialHighlightShape.roundedRect(
        borderRadius: BorderRadius.all(Radius.circular(20)),
      );
      const rect = Rect.fromLTWH(0, 0, 100, 100);

      expect(shape.contains(const Offset(50, 50), rect), isTrue);
      expect(shape.contains(const Offset(4, 4), rect), isFalse);
      expect(shape.contains(const Offset(20, 20), rect), isTrue);
    });

    test('oval rejects corner points that are inside the rect but outside the ellipse', () {
      const shape = TutorialHighlightShape.oval();
      const rect = Rect.fromLTWH(0, 0, 100, 60);

      expect(shape.contains(const Offset(50, 30), rect), isTrue);
      expect(shape.contains(const Offset(5, 5), rect), isFalse);
      expect(shape.contains(const Offset(95, 30), rect), isTrue);
    });

    test('createPath returns a rounded path with the configured radius', () {
      const shape = TutorialHighlightShape.roundedRect(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
        ),
      );
      const rect = Rect.fromLTWH(0, 0, 120, 80);

      final path = shape.createPath(rect, textDirection: TextDirection.ltr);

      expect(path.contains(const Offset(6, 6)), isFalse);
      expect(path.contains(const Offset(24, 24)), isTrue);
      expect(path.contains(const Offset(114, 6)), isTrue);
    });

    test('equality and hashCode depend on type and borderRadius', () {
      const a = TutorialHighlightShape.roundedRect(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      );
      const b = TutorialHighlightShape.roundedRect(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      );
      const c = TutorialHighlightShape.oval();

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a == c, isFalse);
    });
  });
}
