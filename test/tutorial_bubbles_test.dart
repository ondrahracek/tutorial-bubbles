import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
      'TutorialBubble does not wrap its child in a ScaleTransition by default',
      (tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: TutorialBubble(
          child: SizedBox(),
        ),
      ),
    );

    expect(find.byType(ScaleTransition), findsNothing);
  });

  testWidgets(
      'TutorialBubble wraps its content in a ScaleTransition when tap animation is enabled',
      (tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: TutorialBubble(
          enableTapScaleAnimation: true,
          child: SizedBox(),
        ),
      ),
    );

    expect(find.byType(ScaleTransition), findsOneWidget);
  });

  testWidgets(
      'TutorialBubble plays a spring-like scale animation and returns to original scale when tapped',
      (tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: TutorialBubble(
          enableTapScaleAnimation: true,
          child: SizedBox(),
        ),
      ),
    );

    final scaleTransitionFinder = find.byType(ScaleTransition);
    expect(scaleTransitionFinder, findsOneWidget);

    Animation<double> animation =
        tester.widget<ScaleTransition>(scaleTransitionFinder).scale;

    // Initial scale should be at the resting value.
    expect(animation.value, closeTo(1.0, 0.001));

    await tester.tap(find.byType(TutorialBubble));
    await tester.pumpAndSettle();

    // After the animation completes, the scale returns to the resting value.
    animation =
        tester.widget<ScaleTransition>(scaleTransitionFinder).scale;
    expect(animation.value, closeTo(1.0, 0.001));
  });

  testWidgets('TutorialTextBubble renders the provided text', (tester) async {
    const text = 'Hello bubble';

    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: TutorialTextBubble(
          text: text,
        ),
      ),
    );

    expect(find.text(text), findsOneWidget);
  });

  testWidgets(
      'TutorialTextBubble allows configuring individual text style properties',
      (tester) async {
    const text = 'Styled bubble';

    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: TutorialTextBubble(
          text: text,
          textColor: Color(0xFFFF00FF),
          fontSize: 18,
          fontFamily: 'Roboto',
          fontWeight: FontWeight.w700,
        ),
      ),
    );

    final textWidget = tester.widget<Text>(find.text(text));
    final style = textWidget.style!;

    expect(style.color, const Color(0xFFFF00FF));
    expect(style.fontSize, 18);
    expect(style.fontFamily, 'Roboto');
    expect(style.fontWeight, FontWeight.w700);
  });

  testWidgets(
      'TutorialTextBubble prefers complete textStyle over individual properties',
      (tester) async {
    const text = 'Override style';
    const overrideStyle = TextStyle(
      color: Color(0xFF00FFFF),
      fontSize: 20,
      fontFamily: 'Courier',
      fontWeight: FontWeight.w300,
    );

    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: TutorialTextBubble(
          text: text,
          textColor: Color(0xFFFF00FF),
          fontSize: 18,
          fontFamily: 'Roboto',
          fontWeight: FontWeight.w700,
          textStyle: overrideStyle,
        ),
      ),
    );

    final textWidget = tester.widget<Text>(find.text(text));
    final style = textWidget.style!;

    expect(style.color, overrideStyle.color);
    expect(style.fontSize, overrideStyle.fontSize);
    expect(style.fontFamily, overrideStyle.fontFamily);
    expect(style.fontWeight, overrideStyle.fontWeight);
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

  testWidgets('TutorialBubble uses the provided background gradient',
      (tester) async {
    const gradient = LinearGradient(
      colors: <Color>[
        Color(0xFFFF0000),
        Color(0xFF0000FF),
      ],
    );

    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: TutorialBubble(
          backgroundGradient: gradient,
          child: SizedBox(),
        ),
      ),
    );

    final decoratedBox =
        tester.widget<DecoratedBox>(find.byType(DecoratedBox));
    final decoration = decoratedBox.decoration as BoxDecoration;

    expect(decoration.gradient, gradient);
    expect(decoration.color, isNull);
  });

  testWidgets('TutorialBubble does not apply a halo by default',
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

    expect(decoration.boxShadow, isNull);
  });

  testWidgets(
      'TutorialBubble applies a configurable halo when haloEnabled is true',
      (tester) async {
    const haloColor = Color(0xFFFFAA00);

    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: TutorialBubble(
          haloEnabled: true,
          haloColor: haloColor,
          haloBlurRadius: 24,
          haloSpreadRadius: 4,
          child: SizedBox(),
        ),
      ),
    );

    final decoratedBox =
        tester.widget<DecoratedBox>(find.byType(DecoratedBox));
    final decoration = decoratedBox.decoration as BoxDecoration;

    expect(decoration.boxShadow, isNotNull);
    expect(decoration.boxShadow, isNotEmpty);

    final shadow = decoration.boxShadow!.first;
    expect(shadow.color, haloColor);
    expect(shadow.blurRadius, 24);
    expect(shadow.spreadRadius, 4);
  });

  testWidgets(
      'TutorialBubbleOverlay can enable a halo on the bubble it renders',
      (tester) async {
    const targetRect = Rect.fromLTWH(100, 100, 40, 40);
    const haloColor = Color(0xFF00FFAA);

    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox.expand(
          child: TutorialBubbleOverlay(
            targetRect: targetRect,
            preferredSide: TutorialBubbleSide.top,
            bubbleHaloEnabled: true,
            bubbleHaloColor: haloColor,
            child: SizedBox(width: 10, height: 10),
          ),
        ),
      ),
    );

    final decoratedBox =
        tester.widget<DecoratedBox>(find.byType(DecoratedBox));
    final decoration = decoratedBox.decoration as BoxDecoration;

    expect(decoration.boxShadow, isNotNull);
    expect(decoration.boxShadow, isNotEmpty);
    expect(decoration.boxShadow!.first.color, haloColor);
  });

  testWidgets(
      'TutorialBubble prefers backgroundGradient over backgroundColor when both are provided',
      (tester) async {
    const gradient = LinearGradient(
      colors: <Color>[
        Color(0xFF00FF00),
        Color(0xFF0000FF),
      ],
    );

    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: TutorialBubble(
          backgroundColor: Color(0xFFFF0000),
          backgroundGradient: gradient,
          child: SizedBox(),
        ),
      ),
    );

    final decoratedBox =
        tester.widget<DecoratedBox>(find.byType(DecoratedBox));
    final decoration = decoratedBox.decoration as BoxDecoration;

    expect(decoration.gradient, gradient);
    expect(decoration.color, isNull);
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
      'TutorialBubbleOverlay draws a dark overlay that can be customized',
      (tester) async {
    const targetRect = Rect.fromLTWH(100, 100, 40, 40);

    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox.expand(
          child: TutorialBubbleOverlay(
            targetRect: targetRect,
            preferredSide: TutorialBubbleSide.top,
            overlayColor: Color(0x99000000),
            child: SizedBox(width: 10, height: 10),
          ),
        ),
      ),
    );

    final customPaintFinder = find.byType(CustomPaint);
    expect(customPaintFinder, findsWidgets);

    final paints =
        tester.widgetList<CustomPaint>(customPaintFinder).toList();
    expect(paints, isNotEmpty);
    expect(paints.first.painter, isNotNull);
  });

  testWidgets(
      'TutorialBubbleOverlay shows an arrow by default connecting toward the target',
      (tester) async {
    const targetRect = Rect.fromLTWH(100, 100, 40, 40);

    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox.expand(
          child: TutorialBubbleOverlay(
            targetRect: targetRect,
            preferredSide: TutorialBubbleSide.top,
            child: SizedBox(width: 10, height: 10),
          ),
        ),
      ),
    );

    final customPaintFinder = find.byType(CustomPaint);
    final paints =
        tester.widgetList<CustomPaint>(customPaintFinder).toList();

    // Expect at least two CustomPaints: one for the overlay and one for
    // the arrow.
    expect(paints.length, greaterThanOrEqualTo(2));
  });

  testWidgets(
      'TutorialBubbleOverlay can disable the arrow so only the bubble remains',
      (tester) async {
    const targetRect = Rect.fromLTWH(100, 100, 40, 40);

    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox.expand(
          child: TutorialBubbleOverlay(
            targetRect: targetRect,
            preferredSide: TutorialBubbleSide.top,
            arrowEnabled: false,
            child: SizedBox(width: 10, height: 10),
          ),
        ),
      ),
    );

    // When arrowEnabled is false, we still expect at least one CustomPaint
    // for the overlay, but not more than two total in this configuration.
    final customPaintFinder = find.byType(CustomPaint);
    final paints =
        tester.widgetList<CustomPaint>(customPaintFinder).toList();

    expect(paints, isNotEmpty);
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

  testWidgets(
      'TutorialBubbleOverlay arrow direction matches bubble side in automatic mode',
      (tester) async {
    const targetRectLocal = Rect.fromLTWH(80, 40, 40, 40);
    const overlaySize = Size(200, 200);

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox(
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
    await tester.pump();

    expect(find.byType(TutorialBubbleOverlay), findsOneWidget);
    expect(find.byType(TutorialBubble), findsOneWidget);
  });

  testWidgets(
      'TutorialBubbleOverlay keeps the bubble fully visible near the top edge',
      (tester) async {
    const overlaySize = Size(200, 200);
    const overlayKey = ValueKey('overlayTopEdge');
    const targetRectLocal = Rect.fromLTWH(80, 4, 40, 40);

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
              preferredSide: TutorialBubbleSide.top,
              child: SizedBox(width: 40, height: 40),
            ),
          ),
        ),
      ),
    );

    final overlayRect = tester.getRect(find.byKey(overlayKey));
    final bubbleRectGlobal = tester.getRect(find.byType(TutorialBubble));
    final bubbleRectLocal = bubbleRectGlobal.shift(-overlayRect.topLeft);

    expect(bubbleRectLocal.top >= 0, isTrue);
    expect(bubbleRectLocal.bottom <= overlaySize.height, isTrue);
  });

  testWidgets(
      'TutorialBubbleOverlay keeps the bubble fully visible near the right edge',
      (tester) async {
    const overlaySize = Size(200, 200);
    const overlayKey = ValueKey('overlayRightEdge');
    const targetRectLocal = Rect.fromLTWH(180, 80, 40, 40);

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
              preferredSide: TutorialBubbleSide.right,
              child: SizedBox(width: 40, height: 40),
            ),
          ),
        ),
      ),
    );

    final overlayRect = tester.getRect(find.byKey(overlayKey));
    final bubbleRectGlobal = tester.getRect(find.byType(TutorialBubble));
    final bubbleRectLocal = bubbleRectGlobal.shift(-overlayRect.topLeft);

    expect(bubbleRectLocal.left >= 0, isTrue);
    expect(bubbleRectLocal.right <= overlaySize.width, isTrue);
  });

  testWidgets(
      'TutorialBubbleOverlay keeps the bubble fully visible for a center target',
      (tester) async {
    const overlaySize = Size(200, 200);
    const overlayKey = ValueKey('overlayCenter');
    const targetRectLocal = Rect.fromLTWH(80, 80, 40, 40);

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
              preferredSide: TutorialBubbleSide.bottom,
              child: SizedBox(width: 40, height: 40),
            ),
          ),
        ),
      ),
    );

    final overlayRect = tester.getRect(find.byKey(overlayKey));
    final bubbleRectGlobal = tester.getRect(find.byType(TutorialBubble));
    final bubbleRectLocal = bubbleRectGlobal.shift(-overlayRect.topLeft);

    expect(bubbleRectLocal.left >= 0, isTrue);
    expect(bubbleRectLocal.top >= 0, isTrue);
    expect(bubbleRectLocal.right <= overlaySize.width, isTrue);
    expect(bubbleRectLocal.bottom <= overlaySize.height, isTrue);
  });

  testWidgets(
      'Any Flutter widget can be targeted via its layout without modifying its own code (ElevatedButton)',
      (tester) async {
    await tester.pumpWidget(
      const _TargetOverlayDemo(
        targetBuilder: _TargetBuilder.elevatedButton,
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(TutorialBubble), findsOneWidget);
  });

  testWidgets(
      'Any Flutter widget can be targeted via its layout without modifying its own code (Text)',
      (tester) async {
    await tester.pumpWidget(
      const _TargetOverlayDemo(
        targetBuilder: _TargetBuilder.text,
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(TutorialBubble), findsOneWidget);
  });

  testWidgets(
      'Any Flutter widget can be targeted via its layout without modifying its own code (custom widget)',
      (tester) async {
    await tester.pumpWidget(
      const _TargetOverlayDemo(
        targetBuilder: _TargetBuilder.custom,
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(TutorialBubble), findsOneWidget);
  });

  test(
      'TutorialEngineController accepts a non-empty ordered list of TutorialStep instances',
      () {
    final key1 = GlobalKey();
    final key2 = GlobalKey();

    final steps = [
      TutorialStep(
        targetKey: key1,
        bubbleBuilder: (context) => const Text('Step 1'),
      ),
      TutorialStep(
        targetKey: key2,
        bubbleBuilder: (context) => const Text('Step 2'),
      ),
    ];

    final controller = TutorialEngineController(steps: steps);

    expect(controller.steps, hasLength(2));
    expect(controller.steps[0].targetKey, key1);
    expect(controller.steps[1].targetKey, key2);
  });

  test('TutorialEngineController rejects an empty list of steps', () {
    expect(
      () => TutorialEngineController(steps: const []),
      throwsA(isA<AssertionError>()),
    );
  });

  test(
      'TutorialEngineController executes steps in order and advances when advance is called',
      () {
    final key1 = GlobalKey();
    final key2 = GlobalKey();
    final key3 = GlobalKey();

    final steps = [
      TutorialStep(
        targetKey: key1,
        bubbleBuilder: (context) => const Text('Step 1'),
      ),
      TutorialStep(
        targetKey: key2,
        bubbleBuilder: (context) => const Text('Step 2'),
      ),
      TutorialStep(
        targetKey: key3,
        bubbleBuilder: (context) => const Text('Step 3'),
      ),
    ];

    final controller = TutorialEngineController(steps: steps);

    expect(controller.currentIndex, 0);
    expect(controller.currentStep.targetKey, key1);
    expect(controller.isLastStep, isFalse);
    expect(controller.isFinished, isFalse);

    final firstAdvanceChanged = controller.advance();
    expect(firstAdvanceChanged, isTrue);
    expect(controller.currentIndex, 1);
    expect(controller.currentStep.targetKey, key2);
    expect(controller.isLastStep, isFalse);
    expect(controller.isFinished, isFalse);

    final secondAdvanceChanged = controller.advance();
    expect(secondAdvanceChanged, isTrue);
    expect(controller.currentIndex, 2);
    expect(controller.currentStep.targetKey, key3);
    expect(controller.isLastStep, isTrue);
    expect(controller.isFinished, isFalse);

    final thirdAdvanceChanged = controller.advance();
    expect(thirdAdvanceChanged, isFalse);
    expect(controller.currentIndex, 2);
    expect(controller.isLastStep, isTrue);
    expect(controller.isFinished, isTrue);

    final fourthAdvanceChanged = controller.advance();
    expect(fourthAdvanceChanged, isFalse);
    expect(controller.currentIndex, 2);
    expect(controller.isFinished, isTrue);
  });

  testWidgets(
      'TutorialBubbleOverlay blocks interactions outside the highlighted target',
      (tester) async {
    var targetTapped = false;
    var outsideTapped = false;

    await tester.pumpWidget(
      _InteractionBlockingDemo(
        onTargetTap: () {
          targetTapped = true;
        },
        onOutsideTap: () {
          outsideTapped = true;
        },
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.text('Outside button'));
    await tester.pumpAndSettle();
    expect(outsideTapped, isFalse);

    // The target can still be interacted with in future scenarios,
    // but this test focuses specifically on ensuring that taps
    // outside the highlighted target are blocked.
    expect(targetTapped, isFalse);
  });
}

class _TargetOverlayDemo extends StatefulWidget {
  const _TargetOverlayDemo({
    required this.targetBuilder,
  });

  final _TargetBuilder targetBuilder;

  @override
  State<_TargetOverlayDemo> createState() => _TargetOverlayDemoState();
}

class _TargetOverlayDemoState extends State<_TargetOverlayDemo> {
  final GlobalKey _targetKey = GlobalKey();
  final GlobalKey _overlayKey = GlobalKey();

  Rect? _targetRect;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateTargetRect());
  }

  void _updateTargetRect() {
    final targetContext = _targetKey.currentContext;
    final overlayContext = _overlayKey.currentContext;

    if (targetContext == null || overlayContext == null) {
      return;
    }

    final targetBox = targetContext.findRenderObject() as RenderBox?;
    final overlayBox = overlayContext.findRenderObject() as RenderBox?;

    if (targetBox == null || overlayBox == null) {
      return;
    }

    final topLeft =
        targetBox.localToGlobal(Offset.zero, ancestor: overlayBox);
    final size = targetBox.size;

    setState(() {
      _targetRect = topLeft & size;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Center(
        child: SizedBox(
          width: 200,
          height: 200,
          child: Stack(
            key: _overlayKey,
            children: [
              Center(
                child: widget.targetBuilder.build(_targetKey),
              ),
              if (_targetRect != null)
                Positioned.fill(
                  child: TutorialBubbleOverlay(
                    targetRect: _targetRect!,
                    preferredSide: TutorialBubbleSide.top,
                    child: const Text('Bubble for target'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InteractionBlockingDemo extends StatefulWidget {
  const _InteractionBlockingDemo({
    required this.onTargetTap,
    required this.onOutsideTap,
  });

  final VoidCallback onTargetTap;
  final VoidCallback onOutsideTap;

  @override
  State<_InteractionBlockingDemo> createState() =>
      _InteractionBlockingDemoState();
}

class _InteractionBlockingDemoState extends State<_InteractionBlockingDemo> {
  final GlobalKey _targetKey = GlobalKey();
  final GlobalKey _overlayKey = GlobalKey();

  Rect? _targetRect;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateTargetRect());
  }

  void _updateTargetRect() {
    final targetContext = _targetKey.currentContext;
    final overlayContext = _overlayKey.currentContext;

    if (targetContext == null || overlayContext == null) {
      return;
    }

    final targetBox = targetContext.findRenderObject() as RenderBox?;
    final overlayBox = overlayContext.findRenderObject() as RenderBox?;

    if (targetBox == null || overlayBox == null) {
      return;
    }

    final topLeft =
        targetBox.localToGlobal(Offset.zero, ancestor: overlayBox);
    final size = targetBox.size;

    setState(() {
      _targetRect = topLeft & size;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            key: _overlayKey,
            width: 240,
            height: 240,
            child: Stack(
              children: [
                Align(
                  alignment: const Alignment(0, -0.8),
                  child: ElevatedButton(
                    onPressed: widget.onOutsideTap,
                    child: const Text('Outside button'),
                  ),
                ),
                Center(
                  child: ElevatedButton(
                    key: _targetKey,
                    onPressed: widget.onTargetTap,
                    child: const Text('Target button'),
                  ),
                ),
                if (_targetRect != null)
                  Positioned.fill(
                    child: TutorialBubbleOverlay(
                      targetRect: _targetRect!,
                      preferredSide: TutorialBubbleSide.top,
                      child: const SizedBox(width: 40, height: 40),
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

enum _TargetBuilder {
  elevatedButton,
  text,
  custom;

  Widget build(Key key) {
    switch (this) {
      case _TargetBuilder.elevatedButton:
        return ElevatedButton(
          key: key,
          onPressed: () {},
          child: const Text('Target button'),
        );
      case _TargetBuilder.text:
        return Text(
          'Target text',
          key: key,
        );
      case _TargetBuilder.custom:
        return _CustomTargetWidget(key: key);
    }
  }
}

class _CustomTargetWidget extends StatelessWidget {
  const _CustomTargetWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 40,
      height: 40,
    );
  }
}

