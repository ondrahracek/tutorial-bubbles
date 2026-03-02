library tutorial_bubbles;

import 'package:flutter/widgets.dart';

/// Preferred side for positioning a bubble relative to its target.
enum TutorialBubbleSide {
  top,
  bottom,
  left,
  right,

  /// Chooses the side with the most available space around the target.
  automatic,
}

/// A simple bubble widget that wraps the given [child] with a
/// configurable background.
class TutorialBubble extends StatelessWidget {
  const TutorialBubble({
    super.key,
    required this.child,
    this.backgroundColor,
    this.backgroundGradient,
    this.haloEnabled = false,
    this.haloColor,
    this.haloBlurRadius = 16,
    this.haloSpreadRadius = 2,
  });

  final Widget child;
  final Color? backgroundColor;
  final Gradient? backgroundGradient;

  /// Whether to draw a glow/halo around the bubble.
  ///
  /// When enabled, a soft shadow is rendered around the bubble using
  /// [haloColor], [haloBlurRadius], and [haloSpreadRadius].
  final bool haloEnabled;

  /// Optional color for the halo glow.
  ///
  /// When null, a color derived from the bubble background is used.
  final Color? haloColor;

  /// Blur radius for the halo glow.
  final double haloBlurRadius;

  /// Spread radius for the halo glow.
  final double haloSpreadRadius;

  static const Color _defaultBackgroundColor = Color(0xFF303030);

  @override
  Widget build(BuildContext context) {
    final Color defaultBackground =
        backgroundColor ?? _defaultBackgroundColor;

    final Color haloFallbackColor =
        backgroundGradient == null ? defaultBackground : _defaultBackgroundColor;

    final List<BoxShadow>? boxShadow =
        (haloEnabled || haloColor != null)
            ? <BoxShadow>[
                BoxShadow(
                  color: haloColor ?? haloFallbackColor,
                  blurRadius: haloBlurRadius,
                  spreadRadius: haloSpreadRadius,
                ),
              ]
            : null;

    final decoration = BoxDecoration(
      color: backgroundGradient == null ? defaultBackground : null,
      gradient: backgroundGradient,
      borderRadius: BorderRadius.circular(12),
      boxShadow: boxShadow,
    );

    return DecoratedBox(
      decoration: decoration,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        child: child,
      ),
    );
  }
}

/// A convenience bubble widget for text content with configurable styling.
///
/// This composes [TutorialBubble] and [Text] so callers can configure text
/// appearance without building their own child tree.
class TutorialTextBubble extends StatelessWidget {
  const TutorialTextBubble({
    super.key,
    required this.text,
    this.textColor,
    this.fontSize,
    this.fontFamily,
    this.fontWeight,
    this.textStyle,
    this.backgroundColor,
    this.backgroundGradient,
  });

  /// The text content shown inside the bubble.
  final String text;

  /// Optional text color override.
  final Color? textColor;

  /// Optional font size override.
  final double? fontSize;

  /// Optional font family override.
  final String? fontFamily;

  /// Optional font weight override.
  final FontWeight? fontWeight;

  /// Optional complete [TextStyle] override.
  ///
  /// When provided, this style takes precedence over the individual text
  /// properties such as [textColor], [fontSize], [fontFamily], and
  /// [fontWeight].
  final TextStyle? textStyle;

  /// Optional override for the bubble background color.
  final Color? backgroundColor;

  /// Optional override for the bubble background gradient.
  ///
  /// When provided, this takes precedence over [backgroundColor].
  final Gradient? backgroundGradient;

  @override
  Widget build(BuildContext context) {
    final defaultStyle = DefaultTextStyle.of(context).style;

    TextStyle effectiveStyle;
    if (textStyle != null) {
      effectiveStyle = defaultStyle.merge(textStyle);
    } else {
      effectiveStyle = defaultStyle.copyWith(
        color: textColor,
        fontSize: fontSize,
        fontFamily: fontFamily,
        fontWeight: fontWeight,
      );
    }

    return TutorialBubble(
      backgroundColor: backgroundColor,
      backgroundGradient: backgroundGradient,
      child: Text(
        text,
        style: effectiveStyle,
      ),
    );
  }
}

/// Positions a [TutorialBubble] relative to a given [targetRect]
/// within the available layout bounds.
///
/// The bubble is laid out using a [CustomSingleChildLayout] so it can
/// choose its final position after its size is known.
class TutorialBubbleOverlay extends StatelessWidget {
  const TutorialBubbleOverlay({
    super.key,
    required this.targetRect,
    required this.child,
    this.preferredSide = TutorialBubbleSide.automatic,
    this.overlayColor = const Color(0xB3000000),
    this.backgroundColor,
    this.backgroundGradient,
    this.padding = const EdgeInsets.all(8),
    this.bubbleHaloEnabled = false,
    this.bubbleHaloColor,
    this.bubbleHaloBlurRadius = 16,
    this.bubbleHaloSpreadRadius = 2,
  });

  /// Rectangle describing the target widget in this overlay's
  /// coordinate space.
  final Rect targetRect;

  /// Which side of the [targetRect] the bubble prefers to appear on.
  final TutorialBubbleSide preferredSide;

  /// Color of the dark overlay that dims everything except the bubble
  /// and target.
  ///
  /// Use an opaque or semi-transparent color to control how dark the
  /// background appears while this overlay is active.
  final Color overlayColor;

  /// Optional override for the bubble background color.
  final Color? backgroundColor;

  /// Optional override for the bubble background gradient.
  ///
  /// When provided, this takes precedence over [backgroundColor].
  final Gradient? backgroundGradient;

  /// Padding between the bubble and the [targetRect].
  final EdgeInsets padding;

  /// Whether the bubble rendered by this overlay should draw a halo glow.
  final bool bubbleHaloEnabled;

  /// Optional color for the bubble halo glow.
  final Color? bubbleHaloColor;

  /// Blur radius for the bubble halo glow.
  final double bubbleHaloBlurRadius;

  /// Spread radius for the bubble halo glow.
  final double bubbleHaloSpreadRadius;

  /// Content inside the bubble.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _TutorialOverlayPainter(
        targetRect: targetRect,
        overlayColor: overlayColor,
      ),
      child: CustomSingleChildLayout(
        delegate: _TutorialBubblePositionDelegate(
          targetRect: targetRect,
          preferredSide: preferredSide,
          padding: padding,
        ),
        child: TutorialBubble(
          backgroundColor: backgroundColor,
          backgroundGradient: backgroundGradient,
          haloEnabled: bubbleHaloEnabled,
          haloColor: bubbleHaloColor,
          haloBlurRadius: bubbleHaloBlurRadius,
          haloSpreadRadius: bubbleHaloSpreadRadius,
          child: child,
        ),
      ),
    );
  }
}

class _TutorialBubblePositionDelegate extends SingleChildLayoutDelegate {
  _TutorialBubblePositionDelegate({
    required this.targetRect,
    required this.preferredSide,
    required this.padding,
  });

  final Rect targetRect;
  final TutorialBubbleSide preferredSide;
  final EdgeInsets padding;

  TutorialBubbleSide _resolveSide(Size overlaySize, Size childSize) {
    if (preferredSide != TutorialBubbleSide.automatic) {
      return preferredSide;
    }

    final above = targetRect.top;
    final below = overlaySize.height - targetRect.bottom;
    final left = targetRect.left;
    final right = overlaySize.width - targetRect.right;

    final candidates = <TutorialBubbleSide, double>{
      TutorialBubbleSide.top: above,
      TutorialBubbleSide.bottom: below,
      TutorialBubbleSide.left: left,
      TutorialBubbleSide.right: right,
    };

    return candidates.entries
        .reduce((a, b) => a.value >= b.value ? a : b)
        .key;
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final side = _resolveSide(size, childSize);

    double x;
    double y;

    switch (side) {
      case TutorialBubbleSide.top:
        y = targetRect.top - padding.bottom - childSize.height;
        x = targetRect.center.dx - childSize.width / 2;
        break;
      case TutorialBubbleSide.bottom:
        y = targetRect.bottom + padding.top;
        x = targetRect.center.dx - childSize.width / 2;
        break;
      case TutorialBubbleSide.left:
        x = targetRect.left - padding.right - childSize.width;
        y = targetRect.center.dy - childSize.height / 2;
        break;
      case TutorialBubbleSide.right:
        x = targetRect.right + padding.left;
        y = targetRect.center.dy - childSize.height / 2;
        break;
      case TutorialBubbleSide.automatic:
        // Should not be reached because _resolveSide never returns automatic.
        x = targetRect.center.dx - childSize.width / 2;
        y = targetRect.bottom + padding.top;
        break;
    }

    // Keep the bubble within the available bounds as much as possible, even
    // when the bubble is larger than the overlay in one or both dimensions.
    final maxX = size.width - childSize.width;
    final maxY = size.height - childSize.height;

    final clampedX = x.clamp(0.0, maxX >= 0 ? maxX : 0.0);
    final clampedY = y.clamp(0.0, maxY >= 0 ? maxY : 0.0);

    return Offset(clampedX, clampedY);
  }

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    return BoxConstraints.loose(constraints.biggest);
  }

  @override
  bool shouldRelayout(_TutorialBubblePositionDelegate oldDelegate) {
    return oldDelegate.targetRect != targetRect ||
        oldDelegate.preferredSide != preferredSide ||
        oldDelegate.padding != padding;
  }
}

class _TutorialOverlayPainter extends CustomPainter {
  _TutorialOverlayPainter({
    required this.targetRect,
    required this.overlayColor,
  });

  final Rect targetRect;
  final Color overlayColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (overlayColor.a == 0) {
      return;
    }

    final overlayRect = Offset.zero & size;

    canvas.saveLayer(overlayRect, Paint());

    final overlayPaint = Paint()..color = overlayColor;
    canvas.drawRect(overlayRect, overlayPaint);

    final clearPaint = Paint()..blendMode = BlendMode.clear;
    final highlightRect = RRect.fromRectAndRadius(
      targetRect.inflate(8),
      const Radius.circular(12),
    );
    canvas.drawRRect(highlightRect, clearPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(_TutorialOverlayPainter oldDelegate) {
    return oldDelegate.targetRect != targetRect ||
        oldDelegate.overlayColor != overlayColor;
  }
}

/// Immutable description of a single tutorial step.
///
/// Each step identifies a target widget by [targetKey] and provides
/// [bubbleBuilder] to build the bubble content for that step.
class TutorialStep {
  const TutorialStep({
    required this.targetKey,
    required this.bubbleBuilder,
  });

  /// Key of the widget that should be highlighted for this step.
  ///
  /// The engine uses this key to locate the widget and compute its
  /// layout rectangle for the bubble and overlay.
  final GlobalKey targetKey;

  /// Builder used to create the bubble contents for this step.
  final WidgetBuilder bubbleBuilder;
}

/// A simple controller that owns a list of [TutorialStep]s.
///
/// This class focuses on accepting and exposing the ordered list of
/// steps. Behavioral concerns such as when the tutorial starts or how
/// it advances are modeled by higher-level APIs built on top of this.
class TutorialEngineController {
  TutorialEngineController({
    required List<TutorialStep> steps,
  })  : assert(steps.isNotEmpty, 'TutorialEngineController requires at least one step.'),
        _steps = List.unmodifiable(steps);

  final List<TutorialStep> _steps;

  /// Ordered, immutable list of steps managed by this controller.
  List<TutorialStep> get steps => _steps;
}

