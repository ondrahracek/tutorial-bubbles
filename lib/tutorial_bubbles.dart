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
    this.enableTapScaleAnimation = false,
    this.onTap,
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

  /// Whether tapping the bubble should trigger a spring-like
  /// scale animation.
  final bool enableTapScaleAnimation;

  /// Optional tap callback invoked when the bubble is tapped.
  ///
  /// When [enableTapScaleAnimation] is true, the callback is invoked
  /// and the scale animation plays.
  final VoidCallback? onTap;

  static const Color _defaultBackgroundColor = Color(0xFF303030);

  @override
  Widget build(BuildContext context) {
    return _TutorialBubbleBody(
      backgroundColor: backgroundColor,
      backgroundGradient: backgroundGradient,
      haloEnabled: haloEnabled,
      haloColor: haloColor,
      haloBlurRadius: haloBlurRadius,
      haloSpreadRadius: haloSpreadRadius,
      enableTapScaleAnimation: enableTapScaleAnimation,
      onTap: onTap,
      child: child,
    );
  }
}

class _TutorialBubbleBody extends StatefulWidget {
  const _TutorialBubbleBody({
    required this.child,
    required this.backgroundColor,
    required this.backgroundGradient,
    required this.haloEnabled,
    required this.haloColor,
    required this.haloBlurRadius,
    required this.haloSpreadRadius,
    required this.enableTapScaleAnimation,
    required this.onTap,
  });

  final Widget child;
  final Color? backgroundColor;
  final Gradient? backgroundGradient;
  final bool haloEnabled;
  final Color? haloColor;
  final double haloBlurRadius;
  final double haloSpreadRadius;
  final bool enableTapScaleAnimation;
  final VoidCallback? onTap;

  @override
  State<_TutorialBubbleBody> createState() => _TutorialBubbleBodyState();
}

class _TutorialBubbleBodyState extends State<_TutorialBubbleBody>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  Animation<double>? _scaleAnimation;

  void _ensureController() {
    if (_controller != null) {
      return;
    }

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
      value: 1.0,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller!,
      curve: Curves.elasticOut,
    );
  }

  void _handleTap() {
    widget.onTap?.call();

    if (!widget.enableTapScaleAnimation) {
      return;
    }

    _ensureController();

    _controller!
      ..stop()
      ..value = 0.9
      ..animateTo(
        1.0,
        duration: const Duration(milliseconds: 260),
        curve: Curves.elasticOut,
      );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color defaultBackground =
        widget.backgroundColor ?? TutorialBubble._defaultBackgroundColor;

    final Color haloFallbackColor =
        widget.backgroundGradient == null
            ? defaultBackground
            : TutorialBubble._defaultBackgroundColor;

    final List<BoxShadow>? boxShadow =
        (widget.haloEnabled || widget.haloColor != null)
            ? <BoxShadow>[
                BoxShadow(
                  color: widget.haloColor ?? haloFallbackColor,
                  blurRadius: widget.haloBlurRadius,
                  spreadRadius: widget.haloSpreadRadius,
                ),
              ]
            : null;

    final decoration = BoxDecoration(
      color: widget.backgroundGradient == null ? defaultBackground : null,
      gradient: widget.backgroundGradient,
      borderRadius: BorderRadius.circular(12),
      boxShadow: boxShadow,
    );

    Widget result = DecoratedBox(
      decoration: decoration,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        child: widget.child,
      ),
    );

    if (widget.onTap != null || widget.enableTapScaleAnimation) {
      result = GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _handleTap,
        child: result,
      );
    }

    if (widget.enableTapScaleAnimation) {
      _ensureController();

      result = ScaleTransition(
        scale: _scaleAnimation!,
        child: result,
      );
    }

    return result;
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
    this.arrowEnabled = true,
    this.arrowColor = const Color(0xFFFFFFFF),
    this.arrowStrokeWidth = 2,
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

  /// Whether to render an arrow connecting the bubble toward the target.
  ///
  /// When enabled (the default), a simple arrow is drawn starting from the
  /// edge of the target and extending in the direction of the bubble's side.
  /// Set this to false to hide the arrow and show only the bubble.
  final bool arrowEnabled;

  /// Color used when drawing the arrow stroke.
  final Color arrowColor;

  /// Stroke width used for the arrow path.
  final double arrowStrokeWidth;

  /// Content inside the bubble.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _TutorialOverlayPainter(
        targetRect: targetRect,
        overlayColor: overlayColor,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomSingleChildLayout(
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
          if (arrowEnabled)
            CustomPaint(
              painter: _TutorialArrowPainter(
                targetRect: targetRect,
                side: preferredSide,
                color: arrowColor,
                strokeWidth: arrowStrokeWidth,
              ),
            ),
        ],
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

class _TutorialArrowPainter extends CustomPainter {
  _TutorialArrowPainter({
    required this.targetRect,
    required this.side,
    required this.color,
    required this.strokeWidth,
  });

  final Rect targetRect;
  final TutorialBubbleSide side;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Arrow runs from bubble side toward the target; tip lands at target edge.
    final Offset toTarget = _targetEdgePoint(side);
    final Offset fromBubble = _bubbleSidePoint(side, toTarget);

    final Path path = Path();
    path.moveTo(fromBubble.dx, fromBubble.dy);

    // Smooth curved path: quadratic Bezier with control point offset
    // perpendicular to the line so the curve bulges naturally.
    final Offset mid = Offset(
      (fromBubble.dx + toTarget.dx) / 2,
      (fromBubble.dy + toTarget.dy) / 2,
    );
    final Offset line = toTarget - fromBubble;
    final double dist = line.distance;
    if (dist > 0) {
      final Offset perp = Offset(-line.dy / dist, line.dx / dist);
      // Bulge amount: ~15% of segment length for a visible curve.
      const double bulgeFraction = 0.15;
      final Offset control = mid + perp * (dist * bulgeFraction);
      path.quadraticBezierTo(
        control.dx,
        control.dy,
        toTarget.dx,
        toTarget.dy,
      );
    } else {
      path.lineTo(toTarget.dx, toTarget.dy);
    }

    canvas.drawPath(path, paint);

    // Arrowhead at the target end.
    if (dist > 0) {
      const double arrowHeadSize = 6;
      final Offset normalized = line / dist;
      final Offset perp = Offset(-normalized.dy, normalized.dx);
      final Offset left = toTarget +
          normalized * arrowHeadSize +
          perp * (arrowHeadSize / 2);
      final Offset right = toTarget +
          normalized * arrowHeadSize -
          perp * (arrowHeadSize / 2);
      final Path head = Path()
        ..moveTo(toTarget.dx, toTarget.dy)
        ..lineTo(left.dx, left.dy)
        ..moveTo(toTarget.dx, toTarget.dy)
        ..lineTo(right.dx, right.dy);
      canvas.drawPath(head, paint);
    }
  }

  /// Point on the target rect edge where the arrow tip lands (facing the bubble).
  Offset _targetEdgePoint(TutorialBubbleSide side) {
    switch (side) {
      case TutorialBubbleSide.top:
        return Offset(targetRect.center.dx, targetRect.top);
      case TutorialBubbleSide.bottom:
        return Offset(targetRect.center.dx, targetRect.bottom);
      case TutorialBubbleSide.left:
        return Offset(targetRect.left, targetRect.center.dy);
      case TutorialBubbleSide.right:
        return Offset(targetRect.right, targetRect.center.dy);
      case TutorialBubbleSide.automatic:
        return Offset(targetRect.center.dx, targetRect.bottom);
    }
  }

  /// Point on the bubble side (opposite the target) for the start of the arrow.
  Offset _bubbleSidePoint(TutorialBubbleSide side, Offset toTarget) {
    const double bubbleOffset = 24;
    switch (side) {
      case TutorialBubbleSide.top:
        return toTarget.translate(0, -bubbleOffset);
      case TutorialBubbleSide.bottom:
        return toTarget.translate(0, bubbleOffset);
      case TutorialBubbleSide.left:
        return toTarget.translate(-bubbleOffset, 0);
      case TutorialBubbleSide.right:
        return toTarget.translate(bubbleOffset, 0);
      case TutorialBubbleSide.automatic:
        return toTarget.translate(0, bubbleOffset);
    }
  }

  @override
  bool shouldRepaint(_TutorialArrowPainter oldDelegate) {
    return oldDelegate.targetRect != targetRect ||
        oldDelegate.side != side ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
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

