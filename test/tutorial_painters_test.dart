import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tutorial_bubbles/src/tutorial_painters.dart';
import 'package:tutorial_bubbles/tutorial_bubbles.dart';

void main() {
  group('Tutorial painters', () {
    test('TutorialOverlayPainter paints safely when overlay is fully transparent', () {
      final painter = TutorialOverlayPainter(
        targetRect: const Rect.fromLTWH(20, 20, 40, 40),
        overlayColor: const Color(0x00000000),
      );

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      expect(() => painter.paint(canvas, const Size(120, 120)), returnsNormally);
    });

    test('TutorialOverlayPainter shouldRepaint only when relevant fields change', () {
      final base = TutorialOverlayPainter(
        targetRect: const Rect.fromLTWH(20, 20, 40, 40),
        overlayColor: const Color(0x99000000),
        highlightShape: const TutorialHighlightShape.rect(),
      );

      final same = TutorialOverlayPainter(
        targetRect: const Rect.fromLTWH(20, 20, 40, 40),
        overlayColor: const Color(0x99000000),
        highlightShape: const TutorialHighlightShape.rect(),
      );
      final changedShape = TutorialOverlayPainter(
        targetRect: const Rect.fromLTWH(20, 20, 40, 40),
        overlayColor: const Color(0x99000000),
        highlightShape: const TutorialHighlightShape.oval(),
      );

      expect(base.shouldRepaint(same), isFalse);
      expect(base.shouldRepaint(changedShape), isTrue);
    });

    test('TutorialArrowPainter paints safely when bubble and target are nearly overlapping', () {
      final painter = TutorialArrowPainter(
        targetRect: const Rect.fromLTWH(50, 50, 20, 20),
        bubbleRect: const Rect.fromLTWH(50, 30, 20, 20),
        side: TutorialBubbleSide.top,
        color: const Color(0xFFFFFFFF),
        strokeWidth: 4,
      );

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      expect(() => painter.paint(canvas, const Size(120, 120)), returnsNormally);
    });

    test('TutorialArrowPainter supports automatic side input defensively', () {
      final painter = TutorialArrowPainter(
        targetRect: const Rect.fromLTWH(50, 50, 20, 20),
        bubbleRect: const Rect.fromLTWH(40, 80, 40, 20),
        side: TutorialBubbleSide.automatic,
        color: const Color(0xFFFFFFFF),
        strokeWidth: 4,
      );

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      expect(() => painter.paint(canvas, const Size(120, 120)), returnsNormally);
    });

    test('TutorialArrowPainter shouldRepaint tracks geometry and halo changes', () {
      final base = TutorialArrowPainter(
        targetRect: const Rect.fromLTWH(50, 50, 20, 20),
        bubbleRect: const Rect.fromLTWH(40, 80, 40, 20),
        side: TutorialBubbleSide.bottom,
        color: const Color(0xFFFFFFFF),
        strokeWidth: 4,
      );
      final same = TutorialArrowPainter(
        targetRect: const Rect.fromLTWH(50, 50, 20, 20),
        bubbleRect: const Rect.fromLTWH(40, 80, 40, 20),
        side: TutorialBubbleSide.bottom,
        color: const Color(0xFFFFFFFF),
        strokeWidth: 4,
      );
      final changed = TutorialArrowPainter(
        targetRect: const Rect.fromLTWH(50, 50, 20, 20),
        bubbleRect: const Rect.fromLTWH(40, 80, 40, 20),
        side: TutorialBubbleSide.bottom,
        color: const Color(0xFFFFFFFF),
        strokeWidth: 4,
        haloEnabled: true,
      );

      expect(base.shouldRepaint(same), isFalse);
      expect(base.shouldRepaint(changed), isTrue);
    });

    test('TutorialTargetHaloPainter and TutorialTargetShinePainter repaint on shape changes', () {
      final haloBase = TutorialTargetHaloPainter(
        targetRect: const Rect.fromLTWH(20, 20, 40, 40),
        overlayColor: const Color(0x99000000),
        highlightShape: const TutorialHighlightShape.rect(),
      );
      final haloChanged = TutorialTargetHaloPainter(
        targetRect: const Rect.fromLTWH(20, 20, 40, 40),
        overlayColor: const Color(0x99000000),
        highlightShape: const TutorialHighlightShape.oval(),
      );

      final shineBase = TutorialTargetShinePainter(
        targetRect: const Rect.fromLTWH(20, 20, 40, 40),
        highlightShape: const TutorialHighlightShape.rect(),
      );
      final shineChanged = TutorialTargetShinePainter(
        targetRect: const Rect.fromLTWH(20, 20, 40, 40),
        highlightShape: const TutorialHighlightShape.oval(),
      );

      expect(haloBase.shouldRepaint(haloChanged), isTrue);
      expect(shineBase.shouldRepaint(shineChanged), isTrue);
    });
  });
}
