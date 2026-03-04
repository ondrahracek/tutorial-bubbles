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
      'TutorialTextBubble renders text without underlines by default',
      (tester) async {
    const text = 'No underline';

    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: TutorialTextBubble(
          text: text,
        ),
      ),
    );

    final textWidget = tester.widget<Text>(find.text(text));
    final style = textWidget.style!;

    expect(style.decoration, TextDecoration.none);
  });

  testWidgets(
      'TutorialTextBubble respects explicit decoration when provided via textStyle',
      (tester) async {
    const text = 'Decorated text';
    const overrideStyle = TextStyle(
      decoration: TextDecoration.underline,
    );

    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: TutorialTextBubble(
          text: text,
          textStyle: overrideStyle,
        ),
      ),
    );

    final textWidget = tester.widget<Text>(find.text(text));
    final style = textWidget.style!;

    expect(style.decoration, TextDecoration.underline);
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

  testWidgets(
      'TutorialBubble can display an optional border with a darker-than-background default color',
      (tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: TutorialBubble(
          borderWidth: 2,
          child: SizedBox(),
        ),
      ),
    );

    final decoratedBox =
        tester.widget<DecoratedBox>(find.byType(DecoratedBox));
    final decoration = decoratedBox.decoration as BoxDecoration;

    expect(decoration.border, isNotNull);
    final Border border = decoration.border! as Border;
    expect(border.top.width, 2);
    // Default background is 0xFF303030; the darker border color should be
    // a slightly darker gray.
    expect(border.top.color, const Color(0xFF292929));
  });

  testWidgets(
      'TutorialBubble uses a soft rounded default corner radius when none is provided',
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

    expect(decoration.borderRadius, BorderRadius.circular(12));
  });

  testWidgets('TutorialBubble corner radius is configurable', (tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: TutorialBubble(
          cornerRadius: 24,
          child: SizedBox(),
        ),
      ),
    );

    final decoratedBox =
        tester.widget<DecoratedBox>(find.byType(DecoratedBox));
    final decoration = decoratedBox.decoration as BoxDecoration;

    expect(decoration.borderRadius, BorderRadius.circular(24));
  });

  testWidgets('TutorialBubble border color and width are configurable',
      (tester) async {
    const borderColor = Color(0xFFFF0000);

    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: TutorialBubble(
          backgroundColor: Color(0xFF0000FF),
          borderColor: borderColor,
          borderWidth: 3,
          child: SizedBox(),
        ),
      ),
    );

    final decoratedBox =
        tester.widget<DecoratedBox>(find.byType(DecoratedBox));
    final decoration = decoratedBox.decoration as BoxDecoration;

    expect(decoration.border, isNotNull);
    final Border border = decoration.border! as Border;
    expect(border.top.color, borderColor);
    expect(border.top.width, 3);
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
}

