import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tutorial_bubbles/src/tutorial_interaction.dart';
import 'package:tutorial_bubbles/tutorial_bubbles.dart';

void main() {
  group('TutorialInteractionBlocker', () {
    testWidgets('enabled false does not absorb outside interactions', (tester) async {
      var outsideTapCount = 0;

      await tester.pumpWidget(
        _InteractionHarness(
          blockerEnabled: false,
          onOutsideButtonPressed: () => outsideTapCount += 1,
        ),
      );

      await tester.tap(find.text('Outside button'));
      await tester.pumpAndSettle();

      expect(outsideTapCount, 1);
    });

    testWidgets('rect target invokes target callback and outside callback in the expected regions',
        (tester) async {
      var targetTapCount = 0;
      var outsideTapCount = 0;

      await tester.pumpWidget(
        _InteractionHarness(
          onTargetTap: () => targetTapCount += 1,
          onOutsideTap: () => outsideTapCount += 1,
        ),
      );

      await tester.tap(find.text('Target marker'), warnIfMissed: false);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Outside button'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(targetTapCount, 1);
      expect(outsideTapCount, 1);
    });

    testWidgets('roundedRect treats clipped corner taps as outside taps', (tester) async {
      var targetTapCount = 0;
      var outsideTapCount = 0;

      await tester.pumpWidget(
        _InteractionHarness(
          targetRect: const Rect.fromLTWH(80, 80, 100, 100),
          highlightShape: const TutorialHighlightShape.roundedRect(
            borderRadius: BorderRadius.all(Radius.circular(28)),
          ),
          onTargetTap: () => targetTapCount += 1,
          onOutsideTap: () => outsideTapCount += 1,
        ),
      );

      final overlayRect = tester.getRect(find.byKey(_InteractionHarness.overlayKey));
      await tester.tapAt(overlayRect.topLeft + const Offset(84, 84));
      await tester.pumpAndSettle();

      expect(targetTapCount, 0);
      expect(outsideTapCount, 1);
    });

    testWidgets('oval target treats corner taps as outside taps', (tester) async {
      var targetTapCount = 0;
      var outsideTapCount = 0;

      await tester.pumpWidget(
        _InteractionHarness(
          targetRect: const Rect.fromLTWH(80, 80, 100, 60),
          highlightShape: const TutorialHighlightShape.oval(),
          onTargetTap: () => targetTapCount += 1,
          onOutsideTap: () => outsideTapCount += 1,
        ),
      );

      final overlayRect = tester.getRect(find.byKey(_InteractionHarness.overlayKey));
      await tester.tapAt(overlayRect.topLeft + const Offset(82, 82));
      await tester.pumpAndSettle();

      expect(targetTapCount, 0);
      expect(outsideTapCount, 1);
    });

    testWidgets('empty target rect treats all taps as outside taps', (tester) async {
      var outsideTapCount = 0;

      await tester.pumpWidget(
        _InteractionHarness(
          targetRect: Rect.zero,
          onOutsideTap: () => outsideTapCount += 1,
        ),
      );

      await tester.tap(find.byKey(_InteractionHarness.overlayKey), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(outsideTapCount, 1);
    });

    testWidgets('target rect is clamped to the visible overlay bounds for hit testing', (tester) async {
      var targetTapCount = 0;
      var outsideTapCount = 0;

      await tester.pumpWidget(
        _InteractionHarness(
          targetRect: const Rect.fromLTWH(-40, -40, 120, 120),
          onTargetTap: () => targetTapCount += 1,
          onOutsideTap: () => outsideTapCount += 1,
        ),
      );

      final overlayRect = tester.getRect(find.byKey(_InteractionHarness.overlayKey));
      await tester.tapAt(overlayRect.topLeft + const Offset(10, 10));
      await tester.pumpAndSettle();
      await tester.tapAt(overlayRect.bottomRight - const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(targetTapCount, 1);
      expect(outsideTapCount, 1);
    });
  });
}

class _InteractionHarness extends StatelessWidget {
  const _InteractionHarness({
    this.blockerEnabled = true,
    this.targetRect = const Rect.fromLTWH(80, 80, 80, 80),
    this.highlightShape = const TutorialHighlightShape.rect(),
    this.onTargetTap,
    this.onOutsideTap,
    this.onOutsideButtonPressed,
  });

  static const overlayKey = ValueKey('interaction-overlay');

  final bool blockerEnabled;
  final Rect targetRect;
  final TutorialHighlightShape highlightShape;
  final VoidCallback? onTargetTap;
  final VoidCallback? onOutsideTap;
  final VoidCallback? onOutsideButtonPressed;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            key: overlayKey,
            width: 240,
            height: 240,
            child: Stack(
              children: [
                Align(
                  alignment: const Alignment(0, -0.9),
                  child: ElevatedButton(
                    onPressed: onOutsideButtonPressed,
                    child: const Text('Outside button'),
                  ),
                ),
                Positioned.fromRect(
                  rect: targetRect,
                  child: const ColoredBox(
                    color: Colors.blue,
                    child: Center(child: Text('Target marker')),
                  ),
                ),
                Positioned.fill(
                  child: TutorialInteractionBlocker(
                    targetRect: targetRect,
                    enabled: blockerEnabled,
                    highlightShape: highlightShape,
                    onTargetTap: onTargetTap,
                    onOutsideTap: onOutsideTap,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
