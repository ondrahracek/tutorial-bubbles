import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:tutorial_bubbles/tutorial_bubbles.dart';

void main() {
  testWidgets('TutorialBubble renders its child', (tester) async {
    const childKey = ValueKey('child');

    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: TutorialBubble(
          child: SizedBox(key: childKey),
        ),
      ),
    );

    expect(find.byKey(childKey), findsOneWidget);
  });

  testWidgets(
      'TutorialBubble uses a sensible default background color when none is provided',
      (tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: TutorialBubble(
          child: SizedBox(),
        ),
      ),
    );

    final decoratedBox =
        tester.widget<DecoratedBox>(find.byType(DecoratedBox));
    final decoration = decoratedBox.decoration as BoxDecoration;

    expect(decoration.color, const Color(0xFF303030));
  });

  testWidgets('TutorialBubble uses the provided background color',
      (tester) async {
    const customColor = Color(0xFFFF0000);

    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: TutorialBubble(
          backgroundColor: customColor,
          child: SizedBox(),
        ),
      ),
    );

    final decoratedBox =
        tester.widget<DecoratedBox>(find.byType(DecoratedBox));
    final decoration = decoratedBox.decoration as BoxDecoration;

    expect(decoration.color, customColor);
  });

  testWidgets(
      'TutorialBubbleOverlay positions bubble on the preferred side of the target',
      (tester) async {
    const targetRect = Rect.fromLTWH(100, 100, 40, 40);

    Future<Rect> pumpAndGetBubbleRect(TutorialBubbleSide side) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox.expand(
            child: TutorialBubbleOverlay(
              targetRect: targetRect,
              preferredSide: side,
              child: const SizedBox(width: 10, height: 10),
            ),
          ),
        ),
      );

      return tester.getRect(find.byType(TutorialBubble));
    }

    final topRect =
        await pumpAndGetBubbleRect(TutorialBubbleSide.top);
    expect(topRect.bottom <= targetRect.top, isTrue);

    final bottomRect =
        await pumpAndGetBubbleRect(TutorialBubbleSide.bottom);
    expect(bottomRect.top >= targetRect.bottom, isTrue);

    final leftRect =
        await pumpAndGetBubbleRect(TutorialBubbleSide.left);
    expect(leftRect.right <= targetRect.left, isTrue);

    final rightRect =
        await pumpAndGetBubbleRect(TutorialBubbleSide.right);
    expect(rightRect.left >= targetRect.right, isTrue);
  });

  testWidgets(
      'TutorialBubbleOverlay automatic side chooses the side with most space',
      (tester) async {
    const targetRectLocal = Rect.fromLTWH(80, 40, 40, 40);
    const overlaySize = Size(200, 200);
    const overlayKey = ValueKey('overlay');

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox(
            key: overlayKey,
            width: overlaySize.width,
            height: overlaySize.height,
            child: const TutorialBubbleOverlay(
              targetRect: targetRectLocal,
              preferredSide: TutorialBubbleSide.automatic,
              child: SizedBox(width: 10, height: 10),
            ),
          ),
        ),
      ),
    );

    final overlayRect = tester.getRect(find.byKey(overlayKey));
    final bubbleRectGlobal = tester.getRect(find.byType(TutorialBubble));
    final bubbleRectLocal = bubbleRectGlobal.shift(-overlayRect.topLeft);

    expect(bubbleRectLocal.top >= targetRectLocal.bottom, isTrue);
  });
}

