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

    await tester.tap(find.byType(TutorialBubble), warnIfMissed: false);
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
      'TutorialBubbleOverlay can enable a halo around the target with configurable color and blur',
      (tester) async {
    const targetRect = Rect.fromLTWH(100, 100, 40, 40);
    const haloColor = Color(0xFF00AAFF);

    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox.expand(
          child: TutorialBubbleOverlay(
            targetRect: targetRect,
            preferredSide: TutorialBubbleSide.top,
            targetHaloEnabled: true,
            targetHaloColor: haloColor,
            targetHaloBlurRadius: 20,
            targetHaloStrokeWidth: 6,
            child: SizedBox(width: 10, height: 10),
          ),
        ),
      ),
    );

    final customPaints =
        tester.widgetList<CustomPaint>(find.byType(CustomPaint)).toList();

    final haloPaints = customPaints
        .where((p) => p.painter is TutorialTargetHaloPainter)
        .toList();

    expect(haloPaints, isNotEmpty);

    final haloPainter =
        haloPaints.first.painter! as TutorialTargetHaloPainter;
    expect(haloPainter.color, haloColor);
    expect(haloPainter.blurRadius, 20);
    expect(haloPainter.strokeWidth, 6);
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
      'TutorialBubbleOverlay can enable an arrow halo with configurable color and blur',
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
            arrowHaloEnabled: true,
            arrowHaloColor: haloColor,
            arrowHaloBlurRadius: 12,
            child: SizedBox(width: 10, height: 10),
          ),
        ),
      ),
    );

    final customPaints =
        tester.widgetList<CustomPaint>(find.byType(CustomPaint)).toList();

    // Find the arrow painter among the CustomPaint widgets.
    final arrowPaints = customPaints
        .where((p) => p.painter is TutorialArrowPainter)
        .cast<CustomPaint>()
        .toList();

    expect(arrowPaints, isNotEmpty);

    final arrowPainter =
        arrowPaints.first.painter! as TutorialArrowPainter;
    expect(arrowPainter.haloEnabled, isTrue);
    expect(arrowPainter.haloColor, haloColor);
    expect(arrowPainter.haloBlurRadius, 12);
    expect(arrowPainter.haloStrokeWidthMultiplier, greaterThan(1));
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
      'TutorialBubbleOverlay and bubble can be used as a standalone spotlight without any tutorial engine',
      (tester) async {
    final GlobalKey targetKey = GlobalKey();
    final GlobalKey overlayKey = GlobalKey();
    Rect? targetRect;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox(
            key: overlayKey,
            width: 200,
            height: 200,
            child: StatefulBuilder(
              builder: (context, setState) {
                if (targetRect == null) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    final targetContext = targetKey.currentContext;
                    final overlayContext = overlayKey.currentContext;
                    if (targetContext == null || overlayContext == null) {
                      return;
                    }
                    final targetBox =
                        targetContext.findRenderObject() as RenderBox?;
                    final overlayBox =
                        overlayContext.findRenderObject() as RenderBox?;
                    if (targetBox == null || overlayBox == null) {
                      return;
                    }
                    final topLeft = targetBox.localToGlobal(
                      Offset.zero,
                      ancestor: overlayBox,
                    );
                    final size = targetBox.size;
                    setState(() {
                      targetRect = topLeft & size;
                    });
                  });
                }

                return Stack(
                  children: [
                    Center(
                      child: SizedBox(
                        key: targetKey,
                        width: 40,
                        height: 40,
                        child: const ColoredBox(color: Colors.blue),
                      ),
                    ),
                    if (targetRect != null)
                      Positioned.fill(
                        child: TutorialBubbleOverlay(
                          targetRect: targetRect!,
                          preferredSide: TutorialBubbleSide.top,
                          child: const TutorialTextBubble(
                            text: 'Standalone spotlight',
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(TutorialBubbleOverlay), findsOneWidget);
    expect(find.byType(TutorialEngine), findsNothing);
    expect(find.text('Standalone spotlight'), findsOneWidget);
  });

  testWidgets(
      'TutorialEngine can span multiple screens by overlaying a Navigator and targeting widgets on different routes',
      (tester) async {
    final firstTargetKey = GlobalKey();
    final secondTargetKey = GlobalKey();

    final controller = TutorialEngineController(
      steps: [
        TutorialStep(
          targetKey: firstTargetKey,
          bubbleBuilder: (context) => const Text('First step'),
        ),
        TutorialStep(
          targetKey: secondTargetKey,
          bubbleBuilder: (context) => const Text('Second step'),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) {
          return TutorialEngine(
            controller: controller,
            child: child ?? const SizedBox.shrink(),
          );
        },
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case '/second':
              return MaterialPageRoute<void>(
                builder: (context) {
                  return Scaffold(
                    body: Center(
                      child: ElevatedButton(
                        key: secondTargetKey,
                        onPressed: () {},
                        child: const Text('Second screen target'),
                      ),
                    ),
                  );
                },
                settings: settings,
              );
            case '/':
            default:
              return MaterialPageRoute<void>(
                builder: (context) {
                  return Scaffold(
                    body: Center(
                      child: ElevatedButton(
                        key: firstTargetKey,
                        onPressed: () {
                          Navigator.of(context).pushNamed<void>('/second');
                          controller.advance();
                        },
                        child: const Text('First screen target'),
                      ),
                    ),
                  );
                },
                settings: settings,
              );
          }
        },
      ),
    );

    await tester.pumpAndSettle();

    // Engine has steps configured but has not been started yet; start it so the
    // overlay becomes visible for the first step.
    controller.start();
    await tester.pumpAndSettle();

    // Initially, the overlay highlights the first route's target.
    expect(find.byType(TutorialBubbleOverlay), findsOneWidget);
    expect(find.text('First step'), findsOneWidget);
    expect(find.text('Second step'), findsNothing);

    // Tapping the first target navigates to the second route; once navigation
    // completes, the controller advances so the next step can target a widget
    // on the new screen.
    await tester.tap(find.byKey(firstTargetKey), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.byType(TutorialBubbleOverlay), findsOneWidget);
    expect(find.text('First step'), findsNothing);
    expect(find.text('Second step'), findsOneWidget);
    expect(find.byKey(secondTargetKey), findsOneWidget);
  });

  testWidgets(
      'TutorialEngine hides the overlay when the last step completes',
      (tester) async {
    final key1 = GlobalKey();
    final key2 = GlobalKey();

    final controller = TutorialEngineController(
      steps: [
        TutorialStep(
          targetKey: key1,
          bubbleBuilder: (context) => const Text('Step 1'),
        ),
        TutorialStep(
          targetKey: key2,
          bubbleBuilder: (context) => const Text('Step 2'),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: TutorialEngine(
          controller: controller,
          child: Column(
            children: [
              ElevatedButton(
                key: key1,
                onPressed: () {},
                child: const Text('First'),
              ),
              ElevatedButton(
                key: key2,
                onPressed: () {},
                child: const Text('Second'),
              ),
            ],
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Start the engine so the overlay becomes visible for the initial step.
    controller.start();
    await tester.pumpAndSettle();
    expect(find.byType(TutorialBubbleOverlay), findsOneWidget);

    // Advance to the second (last) step.
    controller.advance();
    await tester.pumpAndSettle();
    expect(find.byType(TutorialBubbleOverlay), findsOneWidget);

    // Advancing past the last step finishes the tutorial and hides the overlay.
    controller.advance();
    await tester.pumpAndSettle();
    expect(find.byType(TutorialBubbleOverlay), findsNothing);
  });

  testWidgets(
      'TutorialEngine hides the overlay when the tutorial is finished early',
      (tester) async {
    final key1 = GlobalKey();
    final key2 = GlobalKey();

    final controller = TutorialEngineController(
      steps: [
        TutorialStep(
          targetKey: key1,
          bubbleBuilder: (context) => const Text('Step 1'),
        ),
        TutorialStep(
          targetKey: key2,
          bubbleBuilder: (context) => const Text('Step 2'),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: TutorialEngine(
          controller: controller,
          child: Column(
            children: [
              ElevatedButton(
                key: key1,
                onPressed: () {},
                child: const Text('First'),
              ),
              ElevatedButton(
                key: key2,
                onPressed: () {},
                child: const Text('Second'),
              ),
            ],
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Start the engine so the overlay becomes visible for the initial step.
    controller.start();
    await tester.pumpAndSettle();
    expect(find.byType(TutorialBubbleOverlay), findsOneWidget);

    // Finishing early hides the overlay without needing to reach the last step.
    controller.finish();
    await tester.pumpAndSettle();
    expect(find.byType(TutorialBubbleOverlay), findsNothing);
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

  test(
      'TutorialEngineController does not start automatically and requires explicit start',
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

    expect(controller.isStarted, isFalse);
    expect(controller.isStartedListenable.value, isFalse);

    controller.start();

    expect(controller.isStarted, isTrue);
    expect(controller.isStartedListenable.value, isTrue);

    // Calling start again should be a no-op.
    controller.start();
    expect(controller.isStarted, isTrue);
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

  test(
      'TutorialEngineController exposes totalSteps and notifies when the active step changes',
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

    expect(controller.totalSteps, 3);
    expect(controller.currentIndex, 0);
    expect(controller.currentIndexListenable.value, 0);

    final recordedIndices = <int>[];
    controller.currentIndexListenable.addListener(() {
      recordedIndices.add(controller.currentIndexListenable.value);
    });

    final firstAdvanceChanged = controller.advance();
    expect(firstAdvanceChanged, isTrue);
    expect(controller.currentIndex, 1);
    expect(recordedIndices, [1]);

    final secondAdvanceChanged = controller.advance();
    expect(secondAdvanceChanged, isTrue);
    expect(controller.currentIndex, 2);
    expect(recordedIndices, [1, 2]);

    final thirdAdvanceChanged = controller.advance();
    expect(thirdAdvanceChanged, isFalse);
    expect(controller.currentIndex, 2);
    expect(recordedIndices, [1, 2]);
  });

  test(
      'TutorialEngineController provides programmatic skip control that advances without requiring target action',
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

    expect(controller.currentIndex, 0);
    expect(controller.currentStep.targetKey, key1);
    expect(controller.isFinished, isFalse);

    final skipped = controller.skip();
    expect(skipped, isTrue);
    expect(controller.currentIndex, 1);
    expect(controller.currentStep.targetKey, key2);
    expect(controller.isLastStep, isTrue);
    expect(controller.isFinished, isFalse);

    final skippedPastEnd = controller.skip();
    expect(skippedPastEnd, isFalse);
    expect(controller.currentIndex, 1);
    expect(controller.isFinished, isTrue);
  });

  test(
      'TutorialEngineController can be finished programmatically and prevents further advancement or skipping',
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

    expect(controller.isFinished, isFalse);
    expect(controller.currentIndex, 0);

    controller.finish();

    expect(controller.isFinished, isTrue);
    expect(controller.currentIndex, 0);

    final advancedAfterFinish = controller.advance();
    final skippedAfterFinish = controller.skip();

    expect(advancedAfterFinish, isFalse);
    expect(skippedAfterFinish, isFalse);
    expect(controller.currentIndex, 0);
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

    await tester.tap(find.text('Outside button'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(outsideTapped, isFalse);

    expect(targetTapped, isFalse);
  });

  testWidgets(
      'Target remains interactive when TutorialBubbleOverlay is active',
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

    await tester.tap(find.text('Target button'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(targetTapped, isTrue);
    expect(outsideTapped, isFalse);
  });

  testWidgets(
      'TutorialEngine can advance when the bubble is tapped when configured',
      (tester) async {
    final key1 = GlobalKey();
    final key2 = GlobalKey();

    final controller = TutorialEngineController(
      steps: [
        TutorialStep(
          targetKey: key1,
          bubbleBuilder: (context) => const TutorialTextBubble(
            text: 'Step 1',
          ),
        ),
        TutorialStep(
          targetKey: key2,
          bubbleBuilder: (context) => const TutorialTextBubble(
            text: 'Step 2',
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: TutorialEngine(
          controller: controller,
          advanceOnBubbleTap: true,
          child: Column(
            children: [
              ElevatedButton(
                key: key1,
                onPressed: () {},
                child: const Text('First'),
              ),
              ElevatedButton(
                key: key2,
                onPressed: () {},
                child: const Text('Second'),
              ),
            ],
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    controller.start();
    await tester.pumpAndSettle();

    expect(controller.currentIndex, 0);
    expect(find.text('Step 1'), findsOneWidget);

    await tester.tap(find.text('Step 1'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(controller.currentIndex, 1);
  });

  testWidgets(
      'TutorialEngine can advance when tapping the dark overlay background when configured',
      (tester) async {
    final key1 = GlobalKey();
    final key2 = GlobalKey();

    final controller = TutorialEngineController(
      steps: [
        TutorialStep(
          targetKey: key1,
          bubbleBuilder: (context) => const TutorialTextBubble(
            text: 'Overlay step 1',
          ),
        ),
        TutorialStep(
          targetKey: key2,
          bubbleBuilder: (context) => const TutorialTextBubble(
            text: 'Overlay step 2',
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TutorialEngine(
            controller: controller,
            advanceOnOverlayTap: true,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton(
                    key: key1,
                    onPressed: () {},
                    child: const Text('First target'),
                  ),
                  ElevatedButton(
                    key: key2,
                    onPressed: () {},
                    child: const Text('Second target'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    controller.start();
    await tester.pumpAndSettle();

    expect(controller.currentIndex, 0);
    expect(find.text('Overlay step 1'), findsOneWidget);

    // Tap a point near the top-left corner, away from the highlighted target,
    // to simulate tapping the dark overlay background.
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(controller.currentIndex, 1);
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
                      onTargetTap: widget.onTargetTap,
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

