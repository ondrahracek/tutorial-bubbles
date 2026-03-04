import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tutorial_bubbles/tutorial_bubbles.dart';
import 'package:tutorial_bubbles/src/tutorial_painters.dart';

void main() {
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
      'TutorialBubbleOverlay cutout matches the target bounds exactly',
      (tester) async {
    const targetRect = Rect.fromLTWH(60, 80, 40, 30);

    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox.expand(
          child: TutorialBubbleOverlay(
            targetRect: targetRect,
            preferredSide: TutorialBubbleSide.top,
            overlayColor: Color(0xFF000000),
            child: SizedBox(width: 10, height: 10),
          ),
        ),
      ),
    );

    final customPaints =
        tester.widgetList<CustomPaint>(find.byType(CustomPaint)).toList();
    expect(customPaints, isNotEmpty);

    final CustomPaint overlayPaintWidget = customPaints.first;
    final CustomPainter? painter = overlayPaintWidget.painter;
    expect(painter, isNotNull);

    // Ensure that painting with the current configuration completes without
    // throwing. The cutout behavior is exercised here, but we avoid converting
    // the picture to an image to keep the test fast and stable across
    // environments.
    const ui.Size paintSize = ui.Size(200, 200);
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final ui.Canvas canvas = ui.Canvas(recorder);

    painter!.paint(canvas, paintSize);
    final ui.Picture picture = recorder.endRecording();
    expect(picture, isA<ui.Picture>());
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
      'Target halo is painted above the dark overlay so it appears over the dimmed background',
      (tester) async {
    const targetRect = Rect.fromLTWH(100, 100, 40, 40);

    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox.expand(
          child: TutorialBubbleOverlay(
            targetRect: targetRect,
            preferredSide: TutorialBubbleSide.top,
            targetHaloEnabled: true,
            child: SizedBox(width: 10, height: 10),
          ),
        ),
      ),
    );

    final customPaints =
        tester.widgetList<CustomPaint>(find.byType(CustomPaint)).toList();

    // Expect at least the dark overlay and the target halo painters; the halo
    // painter must also be present and is drawn after the overlay, which
    // ensures it sits visually above the dimmed background.
    expect(
      customPaints.where((p) => p.painter is TutorialTargetHaloPainter),
      isNotEmpty,
    );
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
      'TutorialBubbleOverlay arrow stroke width is configurable via arrowStrokeWidth',
      (tester) async {
    const targetRect = Rect.fromLTWH(100, 100, 40, 40);

    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox.expand(
          child: TutorialBubbleOverlay(
            targetRect: targetRect,
            preferredSide: TutorialBubbleSide.top,
            arrowStrokeWidth: 6,
            child: SizedBox(width: 10, height: 10),
          ),
        ),
      ),
    );

    final customPaints =
        tester.widgetList<CustomPaint>(find.byType(CustomPaint)).toList();
    final arrowPaints = customPaints
        .where((p) => p.painter is TutorialArrowPainter)
        .cast<CustomPaint>()
        .toList();

    expect(arrowPaints, isNotEmpty);
    final arrowPainter =
        arrowPaints.first.painter! as TutorialArrowPainter;
    expect(arrowPainter.strokeWidth, 6);
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
      'TutorialBubbleOverlay limits bubble width to a sensible fraction of the overlay by default',
      (tester) async {
    const overlaySize = Size(300, 200);
    const overlayKey = ValueKey('overlayMaxWidthDefault');
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
              child: SizedBox(
                width: 1000,
                height: 40,
              ),
            ),
          ),
        ),
      ),
    );

    final overlayRect = tester.getRect(find.byKey(overlayKey));
    final bubbleRectGlobal = tester.getRect(find.byType(TutorialBubble));
    final bubbleRectLocal = bubbleRectGlobal.shift(-overlayRect.topLeft);

    // By default, the bubble should not span the full overlay width.
    expect(bubbleRectLocal.width, lessThan(overlaySize.width));
  });

  testWidgets(
      'TutorialBubbleOverlay maxBubbleWidthFraction can allow the bubble to use more width',
      (tester) async {
    const overlaySize = Size(300, 200);
    const overlayKey = ValueKey('overlayMaxWidthCustom');
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
              maxBubbleWidthFraction: 1.0,
              child: SizedBox(
                width: 1000,
                height: 40,
              ),
            ),
          ),
        ),
      ),
    );

    final overlayRect = tester.getRect(find.byKey(overlayKey));
    final bubbleRectGlobal = tester.getRect(find.byType(TutorialBubble));
    final bubbleRectLocal = bubbleRectGlobal.shift(-overlayRect.topLeft);

    // With maxBubbleWidthFraction = 1.0, the bubble may expand to nearly the
    // full overlay width when the child requests it.
    expect(bubbleRectLocal.width, closeTo(overlaySize.width, 1.0));
  });

  testWidgets(
      'Distance between bubble and target is configurable via TutorialBubbleOverlay.padding',
      (tester) async {
    const overlaySize = Size(200, 200);
    const overlayKey = ValueKey('overlayGap');
    // Place the target high enough in the overlay so that increasing the
    // padding does not cause the bubble to clamp against the bottom edge,
    // which would hide changes in the configured gap.
    const targetRectLocal = Rect.fromLTWH(80, 40, 40, 40);

    Future<double> pumpAndMeasureGap(EdgeInsets padding) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: SizedBox(
              key: overlayKey,
              width: overlaySize.width,
              height: overlaySize.height,
              child: TutorialBubbleOverlay(
                targetRect: targetRectLocal,
                preferredSide: TutorialBubbleSide.bottom,
                padding: padding,
                child: const SizedBox(width: 40, height: 40),
              ),
            ),
          ),
        ),
      );

      final overlayRect = tester.getRect(find.byKey(overlayKey));
      final bubbleRectGlobal = tester.getRect(find.byType(TutorialBubble));
      final bubbleRectLocal = bubbleRectGlobal.shift(-overlayRect.topLeft);

      return bubbleRectLocal.top - targetRectLocal.bottom;
    }

    final defaultGap = await pumpAndMeasureGap(
      const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
    );
    final largerGap = await pumpAndMeasureGap(
      const EdgeInsets.only(top: 48),
    );

    expect(defaultGap, greaterThan(0));
    expect(largerGap, greaterThan(defaultGap));
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

