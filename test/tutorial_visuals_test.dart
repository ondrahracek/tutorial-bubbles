import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tutorial_bubbles/tutorial_bubbles.dart';

void main() {
  test('TutorialVisuals.merge prefers non-null override fields', () {
    const base = TutorialVisuals(
      bubbleBackgroundColor: Color(0xFF000000),
      overlayColor: Color(0x11000000),
      arrowEnabled: true,
      arrowColor: Color(0xFF00FF00),
      arrowHeadLength: 9,
      bubbleHaloEnabled: false,
      targetShineEnabled: false,
      highlightShape: TutorialHighlightShape.rect(),
    );

    const overrides = TutorialVisuals(
      bubbleBackgroundColor: Color(0xFFFFFFFF),
      arrowEnabled: false,
      arrowGradient: LinearGradient(
        colors: <Color>[Color(0xFF42A5F5), Color(0xFFAB47BC)],
      ),
      targetShineEnabled: true,
      targetShineColor: Color(0x80FFFFFF),
      targetShineBlurRadius: 22,
      highlightShape: TutorialHighlightShape.roundedRect(
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
    );

    final merged = base.merge(overrides);

    expect(merged.bubbleBackgroundColor, const Color(0xFFFFFFFF));
    expect(merged.overlayColor, const Color(0x11000000));
    expect(merged.arrowEnabled, isFalse);
    expect(merged.arrowColor, const Color(0xFF00FF00));
    expect(merged.arrowGradient, overrides.arrowGradient);
    expect(merged.arrowHeadLength, 9);
    expect(merged.bubbleHaloEnabled, isFalse);
    expect(merged.targetShineEnabled, isTrue);
    expect(merged.targetShineColor, const Color(0x80FFFFFF));
    expect(merged.targetShineBlurRadius, 22);
    expect(merged.highlightShape, overrides.highlightShape);
  });
}
