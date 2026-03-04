import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tutorial_bubbles/tutorial_bubbles.dart';

void main() {
  test('TutorialVisuals.merge prefers non-null override fields', () {
    const base = TutorialVisuals(
      bubbleBackgroundColor: Color(0xFF000000),
      overlayColor: Color(0x11000000),
      arrowEnabled: true,
      bubbleHaloEnabled: false,
    );

    const overrides = TutorialVisuals(
      bubbleBackgroundColor: Color(0xFFFFFFFF),
      arrowEnabled: false,
    );

    final merged = base.merge(overrides);

    expect(merged.bubbleBackgroundColor, const Color(0xFFFFFFFF));
    expect(merged.overlayColor, const Color(0x11000000));
    expect(merged.arrowEnabled, isFalse);
    expect(merged.bubbleHaloEnabled, isFalse);
  });
}

