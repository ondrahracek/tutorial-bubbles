library tutorial_bubbles;

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Preferred side for positioning a bubble relative to its target.
enum TutorialBubbleSide {
  top,
  bottom,
  left,
  right,

  /// Chooses the side with the most available space around the target.
  automatic,
}

/// Reason the tutorial ended, used by [TutorialEngine.onComplete].
enum TutorialCompletionReason {
  /// The user completed the final step (e.g. via [TutorialEngineController.advance]).
  completed,

  /// The current step was skipped and that was the last step (e.g. via [TutorialEngineController.skip]).
  skipped,

  /// The tutorial was ended programmatically (e.g. via [TutorialEngineController.finish]).
  finished,
}

/// A simple bubble widget that wraps the given [child] with a
/// configurable background.
class TutorialBubble extends StatelessWidget {
  const TutorialBubble({
    super.key,
    required this.child,
    this.backgroundColor,
    this.backgroundGradient,
    this.borderColor,
    this.borderWidth = 0,
    this.haloEnabled = false,
    this.haloColor,
    this.haloBlurRadius = 16,
    this.haloSpreadRadius = 2,
    this.enableTapScaleAnimation = false,
    this.onTap,
    this.cornerRadius = 12,
  });

  final Widget child;
  final Color? backgroundColor;
  final Gradient? backgroundGradient;
  final Color? borderColor;

  /// Width of the optional border around the bubble.
  ///
  /// A value of 0 (the default) disables the border. When the border is
  /// visible, its default color is slightly darker than the bubble background,
  /// and callers can override the color via [borderColor].
  final double borderWidth;

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

  /// Corner radius applied to the bubble background.
  ///
  /// The default value of 12 gives the bubble a soft, rounded,
  /// bubble-like appearance. Callers can adjust this to customize
  /// how round the bubble corners appear.
  final double cornerRadius;

  static const Color _defaultBackgroundColor = Color(0xFF303030);

  @override
  Widget build(BuildContext context) {
    return _TutorialBubbleBody(
      backgroundColor: backgroundColor,
      backgroundGradient: backgroundGradient,
      borderColor: borderColor,
      borderWidth: borderWidth,
      haloEnabled: haloEnabled,
      haloColor: haloColor,
      haloBlurRadius: haloBlurRadius,
      haloSpreadRadius: haloSpreadRadius,
      enableTapScaleAnimation: enableTapScaleAnimation,
      onTap: onTap,
      cornerRadius: cornerRadius,
      child: child,
    );
  }
}

class _TutorialBubbleBody extends StatefulWidget {
  const _TutorialBubbleBody({
    required this.child,
    required this.backgroundColor,
    required this.backgroundGradient,
    required this.borderColor,
    required this.borderWidth,
    required this.haloEnabled,
    required this.haloColor,
    required this.haloBlurRadius,
    required this.haloSpreadRadius,
    required this.enableTapScaleAnimation,
    required this.onTap,
    required this.cornerRadius,
  });

  final Widget child;
  final Color? backgroundColor;
  final Gradient? backgroundGradient;
  final Color? borderColor;
  final double borderWidth;
  final bool haloEnabled;
  final Color? haloColor;
  final double haloBlurRadius;
  final double haloSpreadRadius;
  final bool enableTapScaleAnimation;
  final VoidCallback? onTap;
  final double cornerRadius;

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

    Border? border;
    if (widget.borderWidth > 0) {
      final Color base = widget.backgroundGradient == null
          ? defaultBackground
          : TutorialBubble._defaultBackgroundColor;
      final Color effectiveBorderColor =
          widget.borderColor ?? _darkerColor(base);
      border = Border.all(
        color: effectiveBorderColor,
        width: widget.borderWidth,
      );
    }

    final decoration = BoxDecoration(
      color: widget.backgroundGradient == null ? defaultBackground : null,
      gradient: widget.backgroundGradient,
      borderRadius: BorderRadius.circular(widget.cornerRadius),
      border: border,
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

  Color _darkerColor(Color color) {
    const double factor = 0.85;
    int scale(double channel) =>
        ((channel * factor) * 255.0).round() & 0xff;
    final int alpha = (color.a * 255.0).round() & 0xff;
    return Color.fromARGB(
      alpha,
      scale(color.r),
      scale(color.g),
      scale(color.b),
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
class TutorialBubbleOverlay extends StatefulWidget {
  const TutorialBubbleOverlay({
    super.key,
    required this.targetRect,
    required this.child,
    this.preferredSide = TutorialBubbleSide.automatic,
    this.maxBubbleWidthFraction = 0.6,
    this.overlayColor = const Color(0xB3000000),
    this.backgroundColor,
    this.backgroundGradient,
    this.padding = const EdgeInsets.all(8),
    this.targetHaloEnabled = false,
    this.targetHaloColor,
    this.targetHaloBlurRadius = 16,
    this.targetHaloStrokeWidth = 4,
    this.bubbleHaloEnabled = false,
    this.bubbleHaloColor,
    this.bubbleHaloBlurRadius = 16,
    this.bubbleHaloSpreadRadius = 2,
    this.blockOutsideTarget = true,
    this.onTargetTap,
    this.onBackgroundTap,
    this.arrowEnabled = true,
    this.arrowColor = const Color(0xFFFFFFFF),
    this.arrowStrokeWidth = 2,
    this.arrowHaloEnabled = false,
    this.arrowHaloColor,
    this.arrowHaloBlurRadius = 8,
    this.arrowHaloStrokeWidthMultiplier = 2,
  });

  /// Rectangle describing the target widget in this overlay's
  /// coordinate space.
  final Rect targetRect;

  /// Which side of the [targetRect] the bubble prefers to appear on.
  final TutorialBubbleSide preferredSide;

  /// Fraction of the available width that the bubble may occupy at most.
  ///
  /// This is applied as an upper bound when laying out the bubble so that
  /// it does not stretch edge-to-edge across the screen by default. The
  /// value is clamped between 0 and 1; a value around 0.5–0.7 typically
  /// produces a comfortable reading width.
  final double maxBubbleWidthFraction;

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

  /// Whether to draw a glow/halo around the highlighted [targetRect].
  ///
  /// When enabled, a soft halo is rendered around the target using
  /// [targetHaloColor], [targetHaloBlurRadius], and
  /// [targetHaloStrokeWidth].
  final bool targetHaloEnabled;

  /// Optional color for the target halo glow.
  ///
  /// When null, a color derived from [overlayColor] is used.
  final Color? targetHaloColor;

  /// Blur radius for the target halo glow.
  final double targetHaloBlurRadius;

  /// Stroke width for the target halo glow.
  final double targetHaloStrokeWidth;

  /// Whether the bubble rendered by this overlay should draw a halo glow.
  final bool bubbleHaloEnabled;

  /// Optional color for the bubble halo glow.
  final Color? bubbleHaloColor;

  /// Blur radius for the bubble halo glow.
  final double bubbleHaloBlurRadius;

  /// Spread radius for the bubble halo glow.
  final double bubbleHaloSpreadRadius;

  /// Whether interactions outside the highlighted [targetRect] should be
  /// blocked while this overlay is active.
  ///
  /// When true (the default), taps and gestures anywhere outside the target
  /// will be absorbed so that only the highlighted target remains interactive.
  final bool blockOutsideTarget;

  /// Optional callback invoked when the highlighted target region is tapped
  /// while this overlay is active.
  ///
  /// When provided, taps within the [targetRect] area are routed to this
  /// callback even though interactions outside the target remain blocked.
  final VoidCallback? onTargetTap;

  /// Optional callback invoked when the darkened background area outside the
  /// highlighted [targetRect] is tapped while this overlay is active.
  ///
  /// When provided together with [blockOutsideTarget], taps that land outside
  /// the target region are intercepted so they do not reach the underlying
  /// content, and this callback is invoked to allow behaviors such as
  /// advancing a tutorial step by tapping the overlay.
  final VoidCallback? onBackgroundTap;

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

  /// Whether to draw a glow/halo around the arrow stroke.
  ///
  /// When enabled, a soft blurred stroke is rendered behind the arrow using
  /// [arrowHaloColor], [arrowHaloBlurRadius], and
  /// [arrowHaloStrokeWidthMultiplier].
  final bool arrowHaloEnabled;

  /// Optional override color for the arrow halo glow.
  ///
  /// When null, a color derived from [arrowColor] is used.
  final Color? arrowHaloColor;

  /// Blur radius for the arrow halo glow.
  final double arrowHaloBlurRadius;

  /// Multiplier applied to [arrowStrokeWidth] to compute the halo stroke
  /// width.
  final double arrowHaloStrokeWidthMultiplier;

  /// Content inside the bubble.
  final Widget child;

  @override
  State<TutorialBubbleOverlay> createState() => _TutorialBubbleOverlayState();
}

class _TutorialBubbleOverlayState extends State<TutorialBubbleOverlay> {
  /// Resolved side when [TutorialBubbleOverlay.preferredSide] is automatic;
  /// updated after layout so the arrow direction matches the bubble's side.
  TutorialBubbleSide? _resolvedSide;

  void _onLayoutResolved(TutorialBubbleSide side) {
    if (!mounted) return;
    if (_resolvedSide != side) {
      setState(() => _resolvedSide = side);
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveArrowSide = widget.preferredSide == TutorialBubbleSide.automatic
        ? (_resolvedSide ?? TutorialBubbleSide.bottom)
        : widget.preferredSide;

    return Stack(
      fit: StackFit.expand,
      children: [
        IgnorePointer(
          child: CustomPaint(
            painter: _TutorialOverlayPainter(
              targetRect: widget.targetRect,
              overlayColor: widget.overlayColor,
            ),
          ),
        ),
        if (widget.targetHaloEnabled)
          IgnorePointer(
            child: CustomPaint(
              painter: TutorialTargetHaloPainter(
                targetRect: widget.targetRect,
                overlayColor: widget.overlayColor,
                color: widget.targetHaloColor,
                blurRadius: widget.targetHaloBlurRadius,
                strokeWidth: widget.targetHaloStrokeWidth,
              ),
            ),
          ),
        _TutorialInteractionBlocker(
          targetRect: widget.targetRect,
          enabled: widget.blockOutsideTarget,
          onTargetTap: widget.onTargetTap,
          onOutsideTap: widget.onBackgroundTap,
        ),
        CustomSingleChildLayout(
          delegate: _TutorialBubblePositionDelegate(
            targetRect: widget.targetRect,
            preferredSide: widget.preferredSide,
            padding: widget.padding,
            maxBubbleWidthFraction: widget.maxBubbleWidthFraction,
            onResolvedSide: widget.preferredSide == TutorialBubbleSide.automatic
                ? _onLayoutResolved
                : null,
          ),
          child: TutorialBubble(
            backgroundColor: widget.backgroundColor,
            backgroundGradient: widget.backgroundGradient,
            haloEnabled: widget.bubbleHaloEnabled,
            haloColor: widget.bubbleHaloColor,
            haloBlurRadius: widget.bubbleHaloBlurRadius,
            haloSpreadRadius: widget.bubbleHaloSpreadRadius,
            child: widget.child,
          ),
        ),
        if (widget.arrowEnabled)
          IgnorePointer(
            child: CustomPaint(
              painter: TutorialArrowPainter(
                targetRect: widget.targetRect,
                side: effectiveArrowSide,
                color: widget.arrowColor,
                strokeWidth: widget.arrowStrokeWidth,
                haloEnabled: widget.arrowHaloEnabled,
                haloColor: widget.arrowHaloColor,
                haloBlurRadius: widget.arrowHaloBlurRadius,
                haloStrokeWidthMultiplier:
                    widget.arrowHaloStrokeWidthMultiplier,
              ),
            ),
          ),
      ],
    );
  }
}

class _TutorialBubblePositionDelegate extends SingleChildLayoutDelegate {
  _TutorialBubblePositionDelegate({
    required this.targetRect,
    required this.preferredSide,
    required this.padding,
    required this.maxBubbleWidthFraction,
    this.onResolvedSide,
  });

  final Rect targetRect;
  final TutorialBubbleSide preferredSide;
  final EdgeInsets padding;

  /// Maximum fraction of the overlay width that the bubble may occupy.
  final double maxBubbleWidthFraction;

  /// Called with the resolved side after layout when [preferredSide] is automatic.
  final void Function(TutorialBubbleSide)? onResolvedSide;

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
    if (onResolvedSide != null && preferredSide == TutorialBubbleSide.automatic) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        onResolvedSide!(side);
      });
    }

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
    final Size biggest = constraints.biggest;
    final double clampedFraction =
        maxBubbleWidthFraction.clamp(0.0, 1.0);
    final double maxWidth = biggest.width.isFinite
        ? biggest.width * clampedFraction
        : double.infinity;

    return BoxConstraints(
      minWidth: 0,
      maxWidth: maxWidth,
      minHeight: 0,
      maxHeight: biggest.height,
    );
  }

  @override
  bool shouldRelayout(_TutorialBubblePositionDelegate oldDelegate) {
    return oldDelegate.targetRect != targetRect ||
        oldDelegate.preferredSide != preferredSide ||
        oldDelegate.padding != padding ||
        oldDelegate.maxBubbleWidthFraction != maxBubbleWidthFraction ||
        oldDelegate.onResolvedSide != onResolvedSide;
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

    final Rect overlayRect = Offset.zero & size;

    // Draw the dimming overlay across the full available bounds.
    canvas.saveLayer(overlayRect, Paint());
    final Paint overlayPaint = Paint()..color = overlayColor;
    canvas.drawRect(overlayRect, overlayPaint);

    // Clear a hole that matches the target's layout bounds exactly, without
    // adding extra padding around it.
    final double left = targetRect.left.clamp(0.0, overlayRect.right);
    final double right = targetRect.right.clamp(0.0, overlayRect.right);
    final double top = targetRect.top.clamp(0.0, overlayRect.bottom);
    final double bottom = targetRect.bottom.clamp(0.0, overlayRect.bottom);

    if (right > left && bottom > top) {
      final Rect highlightRect = Rect.fromLTRB(left, top, right, bottom);
      final Paint clearPaint = Paint()..blendMode = BlendMode.clear;
      canvas.drawRect(highlightRect, clearPaint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(_TutorialOverlayPainter oldDelegate) {
    return oldDelegate.targetRect != targetRect ||
        oldDelegate.overlayColor != overlayColor;
  }
}

class TutorialArrowPainter extends CustomPainter {
  TutorialArrowPainter({
    required this.targetRect,
    required this.side,
    required this.color,
    required this.strokeWidth,
    this.haloEnabled = false,
    this.haloColor,
    this.haloBlurRadius = 8,
    this.haloStrokeWidthMultiplier = 2,
  });

  final Rect targetRect;
  final TutorialBubbleSide side;
  final Color color;
  final double strokeWidth;
  final bool haloEnabled;
  final Color? haloColor;
  final double haloBlurRadius;
  final double haloStrokeWidthMultiplier;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint arrowPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    // Arrow runs from the bubble side toward the target; the arrowhead tip
    // lands exactly on the target's border without overlapping its interior.
    final Offset tip = _targetEdgePoint(side);
    final Offset fromBubble = _bubbleSidePoint(side, tip);

    final Offset fullLine = tip - fromBubble;
    final double fullDist = fullLine.distance;
    if (fullDist == 0) {
      return;
    }

    const double arrowHeadLength = 6;

    // Keep the arrow body and head entirely outside the target by ending the
    // curved body just before the tip on the target border.
    final double clampedHeadLength =
        fullDist > arrowHeadLength ? arrowHeadLength : fullDist * 0.5;
    final Offset direction = fullLine / fullDist;
    final Offset bodyEnd = tip - direction * clampedHeadLength;

    final Path path = Path()..moveTo(fromBubble.dx, fromBubble.dy);

    // Smooth curved path: quadratic Bezier with control point offset
    // perpendicular to the line so the curve bulges naturally.
    final Offset mid = Offset(
      (fromBubble.dx + bodyEnd.dx) / 2,
      (fromBubble.dy + bodyEnd.dy) / 2,
    );
    final Offset bodyVector = bodyEnd - fromBubble;
    final double bodyDist = bodyVector.distance;
    if (bodyDist > 0) {
      final Offset perp =
          Offset(-bodyVector.dy / bodyDist, bodyVector.dx / bodyDist);
      // Bulge amount: ~15% of segment length for a visible curve.
      const double bulgeFraction = 0.15;
      final Offset control = mid + perp * (bodyDist * bulgeFraction);
      path.quadraticBezierTo(
        control.dx,
        control.dy,
        bodyEnd.dx,
        bodyEnd.dy,
      );
    } else {
      path.lineTo(bodyEnd.dx, bodyEnd.dy);
    }

    // Optionally draw a blurred halo behind the arrow using a thicker stroke.
    if (haloEnabled) {
      final double haloStrokeWidth =
          (strokeWidth * haloStrokeWidthMultiplier).clamp(strokeWidth, strokeWidth * 4);
      final Paint haloPaint = Paint()
        ..color = (haloColor ?? color).withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = haloStrokeWidth
        ..strokeCap = StrokeCap.round
        ..maskFilter = MaskFilter.blur(
          BlurStyle.normal,
          haloBlurRadius,
        );

      canvas.drawPath(path, haloPaint);
    }

    canvas.drawPath(path, arrowPaint);

    // Arrowhead that ends exactly at the target border tip.
    final Offset perp = Offset(-direction.dy, direction.dx);
    final Path head = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(
        tip.dx - direction.dx * clampedHeadLength +
            perp.dx * (clampedHeadLength / 2),
        tip.dy - direction.dy * clampedHeadLength +
            perp.dy * (clampedHeadLength / 2),
      )
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(
        tip.dx - direction.dx * clampedHeadLength -
            perp.dx * (clampedHeadLength / 2),
        tip.dy - direction.dy * clampedHeadLength -
            perp.dy * (clampedHeadLength / 2),
      );
    if (haloEnabled) {
      final double haloStrokeWidth =
          (strokeWidth * haloStrokeWidthMultiplier).clamp(strokeWidth, strokeWidth * 4);
      final Paint haloHeadPaint = Paint()
        ..color = (haloColor ?? color).withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = haloStrokeWidth
        ..strokeCap = StrokeCap.round
        ..maskFilter = MaskFilter.blur(
          BlurStyle.normal,
          haloBlurRadius,
        );
      canvas.drawPath(head, haloHeadPaint);
    }

    canvas.drawPath(head, arrowPaint);
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
  bool shouldRepaint(TutorialArrowPainter oldDelegate) {
    return oldDelegate.targetRect != targetRect ||
        oldDelegate.side != side ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.haloEnabled != haloEnabled ||
        oldDelegate.haloColor != haloColor ||
        oldDelegate.haloBlurRadius != haloBlurRadius ||
        oldDelegate.haloStrokeWidthMultiplier !=
            haloStrokeWidthMultiplier;
  }
}

/// Painter that draws a soft glow/halo around the highlighted target rect.
class TutorialTargetHaloPainter extends CustomPainter {
  TutorialTargetHaloPainter({
    required this.targetRect,
    required this.overlayColor,
    this.color,
    this.blurRadius = 16,
    this.strokeWidth = 4,
  });

  final Rect targetRect;
  final Color overlayColor;
  final Color? color;
  final double blurRadius;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    if (overlayColor.a == 0) {
      return;
    }

    final Rect haloRect = targetRect.inflate(6);
    final RRect haloRRect = RRect.fromRectAndRadius(
      haloRect,
      const Radius.circular(14),
    );

    final Color effectiveColor =
        (color ?? overlayColor).withValues(alpha: 0.7);

    final Paint haloPaint = Paint()
      ..color = effectiveColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..maskFilter = MaskFilter.blur(
        BlurStyle.outer,
        blurRadius,
      );

    canvas.drawRRect(haloRRect, haloPaint);
  }

  @override
  bool shouldRepaint(TutorialTargetHaloPainter oldDelegate) {
    return oldDelegate.targetRect != targetRect ||
        oldDelegate.overlayColor != overlayColor ||
        oldDelegate.color != color ||
        oldDelegate.blurRadius != blurRadius ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

class _TutorialInteractionBlocker extends StatelessWidget {
  const _TutorialInteractionBlocker({
    required this.targetRect,
    required this.enabled,
    this.onTargetTap,
    this.onOutsideTap,
  });

  final Rect targetRect;
  final bool enabled;
  final VoidCallback? onTargetTap;
   /// Optional callback for taps that land outside the highlighted target
  /// region while interaction blocking is enabled.
  final VoidCallback? onOutsideTap;

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final Size size = constraints.biggest;
        if (size.isEmpty) {
          return const SizedBox.shrink();
        }

        final double left = targetRect.left.clamp(0.0, size.width);
        final double right = targetRect.right.clamp(0.0, size.width);
        final double top = targetRect.top.clamp(0.0, size.height);
        final double bottom = targetRect.bottom.clamp(0.0, size.height);

        final Rect clamped = Rect.fromLTRB(left, top, right, bottom);

        if (clamped.isEmpty) {
          return _AbsorbingRegion(onTap: onOutsideTap);
        }

        return Stack(
          children: [
            Positioned(
              left: 0,
              top: 0,
              right: 0,
              height: clamped.top,
              child: _AbsorbingRegion(onTap: onOutsideTap),
            ),
            Positioned(
              left: 0,
              top: clamped.bottom,
              right: 0,
              bottom: 0,
              child: _AbsorbingRegion(onTap: onOutsideTap),
            ),
            Positioned(
              left: 0,
              top: clamped.top,
              width: clamped.left,
              height: clamped.height,
              child: _AbsorbingRegion(onTap: onOutsideTap),
            ),
            Positioned(
              left: clamped.right,
              top: clamped.top,
              right: 0,
              height: clamped.height,
              child: _AbsorbingRegion(onTap: onOutsideTap),
            ),
            if (onTargetTap != null)
              Positioned(
                left: clamped.left,
                top: clamped.top,
                width: clamped.width,
                height: clamped.height,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onTargetTap,
                  child: const SizedBox.expand(),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _AbsorbingRegion extends StatelessWidget {
  const _AbsorbingRegion({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    if (onTap == null) {
      return const AbsorbPointer(
        child: SizedBox.expand(
          child: ColoredBox(
            color: Color(0x00000000),
          ),
        ),
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: const SizedBox.expand(
        child: ColoredBox(
          color: Color(0x00000000),
        ),
      ),
    );
  }
}

/// Immutable configuration for visual parameters used by the tutorial engine.
///
/// These values can be provided globally to [TutorialEngine] and optionally
/// overridden per [TutorialStep]. When both a global and per-step value are
/// provided, the per-step value wins.
class TutorialVisuals {
  const TutorialVisuals({
    this.bubbleBackgroundColor,
    this.bubbleBackgroundGradient,
    this.overlayColor,
    this.arrowEnabled,
    this.bubbleHaloEnabled,
    this.bubbleHaloColor,
    this.targetHaloEnabled,
    this.targetHaloColor,
    this.arrowHaloEnabled,
    this.arrowHaloColor,
    this.textStyle,
  });

  /// Background color applied to the bubble when no gradient is used.
  final Color? bubbleBackgroundColor;

  /// Gradient applied to the bubble background.
  ///
  /// When provided, this takes precedence over [bubbleBackgroundColor].
  final Gradient? bubbleBackgroundGradient;

  /// Color of the dimmed overlay that surrounds the target and bubble.
  final Color? overlayColor;

  /// Whether the arrow connecting the bubble toward the target is visible.
  final bool? arrowEnabled;

  /// Whether the bubble should render a halo/glow.
  final bool? bubbleHaloEnabled;

  /// Optional color for the bubble halo.
  final Color? bubbleHaloColor;

  /// Whether the target should render a halo/glow.
  final bool? targetHaloEnabled;

  /// Optional color for the target halo.
  final Color? targetHaloColor;

  /// Whether the arrow should render a halo/glow.
  final bool? arrowHaloEnabled;

  /// Optional color for the arrow halo.
  final Color? arrowHaloColor;

  /// Optional text style applied to bubble content.
  ///
  /// This is applied via [DefaultTextStyle.merge] so that it can provide
  /// a consistent baseline across all steps while still allowing widgets
  /// such as [TutorialTextBubble] to override specific fields when needed.
  final TextStyle? textStyle;

  /// Returns a new [TutorialVisuals] where non-null fields from [overrides]
  /// replace the corresponding fields in this instance.
  TutorialVisuals merge(TutorialVisuals? overrides) {
    if (overrides == null) {
      return this;
    }

    return TutorialVisuals(
      bubbleBackgroundColor:
          overrides.bubbleBackgroundColor ?? bubbleBackgroundColor,
      bubbleBackgroundGradient:
          overrides.bubbleBackgroundGradient ?? bubbleBackgroundGradient,
      overlayColor: overrides.overlayColor ?? overlayColor,
      arrowEnabled: overrides.arrowEnabled ?? arrowEnabled,
      bubbleHaloEnabled: overrides.bubbleHaloEnabled ?? bubbleHaloEnabled,
      bubbleHaloColor: overrides.bubbleHaloColor ?? bubbleHaloColor,
      targetHaloEnabled: overrides.targetHaloEnabled ?? targetHaloEnabled,
      targetHaloColor: overrides.targetHaloColor ?? targetHaloColor,
      arrowHaloEnabled: overrides.arrowHaloEnabled ?? arrowHaloEnabled,
      arrowHaloColor: overrides.arrowHaloColor ?? arrowHaloColor,
      textStyle: overrides.textStyle ?? textStyle,
    );
  }
}

/// Simple key-value storage for persisting tutorial progress across app restarts.
///
/// This implementation uses [SharedPreferences] under the hood so callers do not
/// need to provide their own persistence layer. Progress is stored as the
/// zero-based index of the last active step for a given tutorial identifier.
class TutorialProgressStorage {
  TutorialProgressStorage._();

  static const String _keyPrefix = 'tutorial_bubbles_progress_';

  static String _storageKey(String tutorialId) =>
      '$_keyPrefix$tutorialId';

  /// Reads the persisted zero-based step index for the given [tutorialId].
  ///
  /// Returns null when no progress has been saved yet.
  static Future<int?> readIndex(String tutorialId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_storageKey(tutorialId));
  }

  /// Persists the given zero-based [stepIndex] for the provided [tutorialId].
  static Future<void> writeIndex(String tutorialId, int stepIndex) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_storageKey(tutorialId), stepIndex);
  }

  /// Clears any saved progress for the provided [tutorialId].
  static Future<void> clear(String tutorialId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey(tutorialId));
  }
}

/// Immutable description of a single tutorial step.
///
/// Each step identifies a target widget by [targetKey] and provides
/// [bubbleBuilder] to build the bubble content for that step. Visual
/// parameters can optionally be customized per-step via [visuals].
class TutorialStep {
  const TutorialStep({
    required this.targetKey,
    required this.bubbleBuilder,
    this.visuals,
  });

  /// Key of the widget that should be highlighted for this step.
  ///
  /// The engine uses this key to locate the widget and compute its
  /// layout rectangle for the bubble and overlay.
  final GlobalKey targetKey;

  /// Builder used to create the bubble contents for this step.
  final WidgetBuilder bubbleBuilder;

  /// Optional per-step overrides for visual parameters.
  ///
  /// When provided together with [TutorialEngine.globalVisuals], any
  /// non-null fields here override the corresponding global defaults.
  final TutorialVisuals? visuals;
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
        _steps = List.unmodifiable(steps),
        _currentIndexNotifier = ValueNotifier<int>(0),
        _isStartedNotifier = ValueNotifier<bool>(false);

  final List<TutorialStep> _steps;

  /// Ordered, immutable list of steps managed by this controller.
  List<TutorialStep> get steps => _steps;

  /// Total number of steps in the tutorial.
  int get totalSteps => _steps.length;

  int _currentIndex = 0;
  bool _isStarted = false;

  /// Index of the currently active step in [steps].
  int get currentIndex => _currentIndex;

  /// The currently active [TutorialStep].
  TutorialStep get currentStep => _steps[_currentIndex];

  /// Whether the current step is the last step in the tutorial.
  bool get isLastStep => _currentIndex == _steps.length - 1;

  final ValueNotifier<int> _currentIndexNotifier;

  /// Listenable that fires whenever the active step index changes.
  ///
  /// Listeners are notified only when the active step changes; repeated
  /// calls to [advance] or [skip] after the tutorial has finished will not
  /// trigger additional notifications.
  ValueNotifier<int> get currentIndexListenable => _currentIndexNotifier;

  final ValueNotifier<bool> _isStartedNotifier;

  /// Whether the tutorial has been explicitly started.
  ///
  /// The tutorial overlay does not become visible until [start] has been
  /// called. Once started, this remains true for the lifetime of the
  /// controller.
  bool get isStarted => _isStarted;

  /// Listenable that fires when the started state changes.
  ValueNotifier<bool> get isStartedListenable => _isStartedNotifier;

  bool _isFinished = false;

  TutorialCompletionReason? _lastCompletionReason;

  /// The reason the tutorial ended, if [isFinished] is true.
  ///
  /// Set when the tutorial transitions to finished via [advance] (completed),
  /// [skip] (skipped), or [finish] (finished). Used by [TutorialEngine] to
  /// invoke [TutorialEngine.onComplete] with the correct context.
  TutorialCompletionReason? get lastCompletionReason => _lastCompletionReason;

  /// Whether the tutorial has finished executing all steps.
  bool get isFinished => _isFinished;

  final ValueNotifier<bool> _isFinishedNotifier = ValueNotifier<bool>(false);

  /// Listenable that fires when the finished state changes.
  ///
  /// This is notified when the tutorial reaches the end of the steps via
  /// [advance] or [skip], or when [finish] is called explicitly.
  ValueNotifier<bool> get isFinishedListenable => _isFinishedNotifier;

  /// Marks the tutorial as started so that the overlay may become visible.
  ///
  /// Calling [start] multiple times is safe and has no additional effect
  /// after the first invocation.
  void start() {
    if (_isStarted) {
      return;
    }
    _isStarted = true;
    _isStartedNotifier.value = true;
  }

  /// Advances to the next step when the current step has completed.
  ///
  /// Returns true when the active step index changes. When the tutorial
  /// has already run through all steps or has been finished explicitly,
  /// this returns false and leaves the controller in a finished state.
  bool advance() {
    if (_isFinished) {
      return false;
    }

    if (_currentIndex < _steps.length - 1) {
      _currentIndex += 1;
      _currentIndexNotifier.value = _currentIndex;
      return true;
    }

    if (!_isFinished) {
      _lastCompletionReason = TutorialCompletionReason.completed;
      _isFinished = true;
      _isFinishedNotifier.value = true;
    }
    return false;
  }

  /// Skips the current step without requiring the target's action to run.
  ///
  /// This behaves similarly to [advance] in that it moves to the next step
  /// in order, but is intended for flows where the current step should be
  /// bypassed programmatically. When the tutorial has already finished,
  /// this returns false and leaves the controller state unchanged.
  bool skip() {
    if (_isFinished) {
      return false;
    }

    if (_currentIndex < _steps.length - 1) {
      _currentIndex += 1;
      _currentIndexNotifier.value = _currentIndex;
      return true;
    }

    if (!_isFinished) {
      _lastCompletionReason = TutorialCompletionReason.skipped;
      _isFinished = true;
      _isFinishedNotifier.value = true;
    }
    return false;
  }

  /// Goes back to the previous step when possible.
  ///
  /// Returns true when the active step index changes (i.e. the controller
  /// was not on the first step). When already on the first step (index 0),
  /// this does nothing and returns false. When the tutorial has already
  /// finished, this also does nothing and returns false.
  ///
  /// Going back from step 2 shows step 1 again with its target and bubble.
  /// Listeners of [currentIndexListenable] are notified when the step
  /// changes. If persistence is configured, the saved position is updated
  /// to the new step index.
  bool goBack() {
    if (_isFinished) {
      return false;
    }
    if (_currentIndex == 0) {
      return false;
    }
    _currentIndex -= 1;
    _currentIndexNotifier.value = _currentIndex;
    return true;
  }

  /// Marks the tutorial as finished from any step.
  ///
  /// After calling [finish], the controller enters a finished state and
  /// subsequent calls to [advance] or [skip] will return false without
  /// changing the current step index.
  void finish() {
    if (_isFinished) {
      return;
    }
    _lastCompletionReason = TutorialCompletionReason.finished;
    _isFinished = true;
    _isFinishedNotifier.value = true;
  }

  /// Jumps to the given zero-based [index] within the list of steps.
  ///
  /// Indices outside the valid range are ignored. When the resolved index
  /// differs from the current one, listeners of [currentIndexListenable] are
  /// notified.
  void jumpTo(int index) {
    if (index < 0 || index >= _steps.length) {
      return;
    }
    if (_currentIndex == index) {
      return;
    }
    _currentIndex = index;
    _currentIndexNotifier.value = _currentIndex;
  }
}

/// Widget that renders a tutorial overlay for the current [TutorialStep].
///
/// This widget composes the same visual primitives used in standalone
/// spotlight mode: it measures the current step's [TutorialStep.targetKey]
/// and renders a [TutorialBubbleOverlay], which in turn draws the dark
/// overlay, optional arrow, halos, and a [TutorialBubble] for the bubble
/// content. No separate engine-specific implementation of these visuals
/// exists; changes to [TutorialBubble], [TutorialBubbleOverlay], or their
/// painters automatically apply to both standalone and engine-driven usage.
///
/// The overlay is visible while the associated [TutorialEngineController]
/// has not finished. When the last step completes via
/// [TutorialEngineController.advance] or the tutorial is finished early via
/// [TutorialEngineController.finish] or [TutorialEngineController.skip], the
/// overlay is removed.
class TutorialEngine extends StatefulWidget {
  const TutorialEngine({
    super.key,
    required this.controller,
    required this.child,
    this.advanceOnBubbleTap = false,
    this.advanceOnOverlayTap = false,
    this.globalVisuals,
    this.persistenceId,
    this.checkpointSteps,
    this.onComplete,
  });

  /// Controller that owns the ordered list of tutorial steps.
  final TutorialEngineController controller;

  /// The underlying application content that the tutorial overlays.
  final Widget child;

  /// Whether tapping the bubble content should attempt to advance the
  /// tutorial to the next step.
  ///
  /// When true, the bubble built for each step is wrapped in a tap handler
  /// that calls [TutorialEngineController.advance]. Reaching the end of the
  /// steps via this mechanism finishes the tutorial and hides the overlay.
  final bool advanceOnBubbleTap;

  /// Whether tapping the dark background overlay outside the target should
  /// attempt to advance the tutorial to the next step.
  ///
  /// When true, taps that land in the dimmed area surrounding the highlighted
  /// target are intercepted so they do not reach the underlying content and
  /// are instead routed to [TutorialEngineController.advance].
  final bool advanceOnOverlayTap;

  /// Optional global defaults for visual parameters applied to all steps.
  ///
  /// Individual [TutorialStep.visuals] can override these defaults on a
  /// per-step basis.
  final TutorialVisuals? globalVisuals;

  /// Optional identifier used to persist and restore tutorial progress.
  ///
  /// When provided, the engine saves the zero-based index of the current step
  /// using [TutorialProgressStorage] according to [checkpointSteps], and
  /// clears the saved value when the tutorial finishes. On a subsequent app
  /// run, creating a new [TutorialEngine] with the same [persistenceId] will
  /// resume from the saved step index without requiring any extra setup.
  final String? persistenceId;

  /// Optional set of step indices at which progress is persisted.
  ///
  /// When null (the default), progress is saved on every step change. When
  /// non-null, progress is saved only when the current step index is in this
  /// set. Use an empty set to disable saving (e.g. never persist). Valid
  /// configurations: null or all indices to save at every step; a non-empty
  /// set to save only at checkpoint steps; an empty set to never save.
  final Set<int>? checkpointSteps;

  /// Optional callback invoked when the tutorial ends.
  ///
  /// Called when the tutorial finishes because the last step was completed
  /// ([TutorialCompletionReason.completed]), the last step was skipped
  /// ([TutorialCompletionReason.skipped]), or the tutorial was ended
  /// programmatically ([TutorialCompletionReason.finished]).
  final void Function(TutorialCompletionReason reason)? onComplete;

  @override
  State<TutorialEngine> createState() => _TutorialEngineState();
}

class _TutorialEngineState extends State<TutorialEngine> {
  final GlobalKey _overlayKey = GlobalKey();
  Rect? _currentTargetRect;
  bool _pendingTargetRectUpdate = false;
  bool _hasLoadedPersistedProgress = false;

  TutorialEngineController get _controller => widget.controller;

  TutorialVisuals? _resolveVisuals() {
    final TutorialVisuals? global = widget.globalVisuals;
    final TutorialVisuals? stepVisuals = _controller.currentStep.visuals;

    if (global == null) {
      return stepVisuals;
    }

    return global.merge(stepVisuals);
  }

  @override
  void initState() {
    super.initState();
    _controller.currentIndexListenable.addListener(_handleStepChanged);
    _controller.isFinishedListenable.addListener(_handleFinishedChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateTargetRect());
    _maybeLoadPersistedProgress();
  }

  @override
  void didUpdateWidget(TutorialEngine oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.currentIndexListenable
          .removeListener(_handleStepChanged);
      oldWidget.controller.isFinishedListenable
          .removeListener(_handleFinishedChanged);
      _controller.currentIndexListenable.addListener(_handleStepChanged);
      _controller.isFinishedListenable.addListener(_handleFinishedChanged);
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _updateTargetRect());
    }

    if (oldWidget.persistenceId != widget.persistenceId) {
      _hasLoadedPersistedProgress = false;
      _maybeLoadPersistedProgress();
    }
  }

  @override
  void dispose() {
    _controller.currentIndexListenable.removeListener(_handleStepChanged);
    _controller.isFinishedListenable.removeListener(_handleFinishedChanged);
    super.dispose();
  }

  void _handleStepChanged() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _updateTargetRect();
      }
    });
    _persistProgressIfNeeded();
  }

  void _handleFinishedChanged() {
    if (!mounted) return;
    _clearPersistedProgressIfNeeded();
    final onComplete = widget.onComplete;
    final reason = _controller.lastCompletionReason ?? TutorialCompletionReason.completed;
    setState(() {
      _currentTargetRect = null;
    });
    onComplete?.call(reason);
  }

  void _maybeLoadPersistedProgress() {
    final String? id = widget.persistenceId;
    if (id == null || _hasLoadedPersistedProgress) {
      return;
    }
    _hasLoadedPersistedProgress = true;

    unawaited(() async {
      final savedIndex = await TutorialProgressStorage.readIndex(id);
      if (!mounted || savedIndex == null) {
        return;
      }
      var clamped = savedIndex;
      if (clamped < 0) {
        clamped = 0;
      } else if (clamped >= _controller.totalSteps) {
        clamped = _controller.totalSteps - 1;
      }
      if (clamped != _controller.currentIndex) {
        _controller.jumpTo(clamped);
      }
    }());
  }

  void _persistProgressIfNeeded() {
    final String? id = widget.persistenceId;
    if (id == null || _controller.isFinished) {
      return;
    }
    final checkpoints = widget.checkpointSteps;
    if (checkpoints != null && !checkpoints.contains(_controller.currentIndex)) {
      return;
    }
    unawaited(TutorialProgressStorage.writeIndex(id, _controller.currentIndex));
  }

  void _clearPersistedProgressIfNeeded() {
    final String? id = widget.persistenceId;
    if (id == null) {
      return;
    }
    unawaited(TutorialProgressStorage.clear(id));
  }

  void _handleAdvanceRequested() {
    if (!_controller.isFinished) {
      _controller.advance();
    }
  }

  void _scheduleTargetRectUpdateRetry() {
    if (!mounted || _controller.isFinished || _pendingTargetRectUpdate) {
      return;
    }
    _pendingTargetRectUpdate = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _updateTargetRect();
    });
  }

  void _updateTargetRect() {
    _pendingTargetRectUpdate = false;

    if (_controller.isFinished) {
      if (_currentTargetRect != null) {
        setState(() {
          _currentTargetRect = null;
        });
      }
      return;
    }

    final targetKey = _controller.currentStep.targetKey;
    final targetContext = targetKey.currentContext;
    final overlayContext = _overlayKey.currentContext;

    if (targetContext == null || overlayContext == null) {
      _scheduleTargetRectUpdateRetry();
      return;
    }

    final targetBox = targetContext.findRenderObject() as RenderBox?;
    final overlayBox = overlayContext.findRenderObject() as RenderBox?;

    if (targetBox == null || overlayBox == null) {
      _scheduleTargetRectUpdateRetry();
      return;
    }

    final topLeft =
        targetBox.localToGlobal(Offset.zero, ancestor: overlayBox);
    final size = targetBox.size;

    final nextRect = topLeft & size;
    if (_currentTargetRect != nextRect) {
      setState(() {
        _currentTargetRect = nextRect;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool showOverlay =
        !_controller.isFinished && _currentTargetRect != null;

    final visuals = _resolveVisuals();

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          key: _overlayKey,
          fit: StackFit.expand,
          children: [
            widget.child,
            if (showOverlay)
              Positioned.fill(
                child: TutorialBubbleOverlay(
                  targetRect: _currentTargetRect!,
                  preferredSide: TutorialBubbleSide.automatic,
                  overlayColor:
                      visuals?.overlayColor ?? const Color(0xB3000000),
                  backgroundColor: visuals?.bubbleBackgroundColor,
                  backgroundGradient: visuals?.bubbleBackgroundGradient,
                  targetHaloEnabled: visuals?.targetHaloEnabled ?? false,
                  targetHaloColor: visuals?.targetHaloColor,
                  bubbleHaloEnabled: visuals?.bubbleHaloEnabled ?? false,
                  bubbleHaloColor: visuals?.bubbleHaloColor,
                  arrowEnabled: visuals?.arrowEnabled ?? true,
                  arrowHaloEnabled: visuals?.arrowHaloEnabled ?? false,
                  arrowHaloColor: visuals?.arrowHaloColor,
                  onBackgroundTap:
                      widget.advanceOnOverlayTap ? _handleAdvanceRequested : null,
                  child: Builder(
                    builder: (context) {
                      final bubble = _controller.currentStep.bubbleBuilder(context);
                      Widget styledBubble = bubble;

                      if (visuals?.textStyle != null) {
                        styledBubble = DefaultTextStyle.merge(
                          style: visuals!.textStyle!,
                          child: styledBubble,
                        );
                      }

                      if (!widget.advanceOnBubbleTap) {
                        return styledBubble;
                      }
                      return GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: _handleAdvanceRequested,
                        child: styledBubble,
                      );
                    },
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}


