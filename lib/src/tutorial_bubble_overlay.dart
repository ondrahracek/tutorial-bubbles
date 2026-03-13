// Overlay widget that positions tutorial bubbles relative to targets.

import 'package:flutter/widgets.dart';

import 'enums.dart';
import 'tutorial_bubble.dart';
import 'tutorial_highlight_shape.dart';
import 'tutorial_interaction.dart';
import 'tutorial_painters.dart';

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
    this.padding = const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
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
    this.arrowGradient,
    this.arrowStrokeWidth = 2,
    this.arrowHaloEnabled = false,
    this.arrowHaloColor,
    this.arrowHaloBlurRadius = 8,
    this.arrowHaloStrokeWidthMultiplier = 2,
    this.highlightShape = const TutorialHighlightShape.rect(),
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

  /// Padding used when positioning the bubble relative to [targetRect].
  ///
  /// For targets above or below the bubble, the vertical insets (top/bottom)
  /// control how far the bubble sits from the target; for targets to the left
  /// or right, the horizontal insets (left/right) control that gap. The
  /// default provides a comfortable amount of spacing between bubble and
  /// target while still keeping them visually connected.
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

  /// Gradient used when drawing the arrow stroke.
  final Gradient? arrowGradient;

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

  /// Shape used for the highlighted target region.
  final TutorialHighlightShape highlightShape;

  /// Content inside the bubble.
  final Widget child;

  @override
  State<TutorialBubbleOverlay> createState() => _TutorialBubbleOverlayState();
}

class _TutorialBubbleOverlayState extends State<TutorialBubbleOverlay> {
  /// Resolved side when [TutorialBubbleOverlay.preferredSide] is automatic;
  /// updated after layout so the arrow direction matches the bubble's side.
  TutorialBubbleSide? _resolvedSide;
  final GlobalKey _stackKey = GlobalKey();
  final GlobalKey _bubbleKey = GlobalKey();
  Rect? _bubbleRect;
  bool _bubbleRectMeasurementScheduled = false;

  void _onLayoutResolved(TutorialBubbleSide side) {
    if (!mounted) return;
    if (_resolvedSide != side) {
      setState(() => _resolvedSide = side);
    }
  }

  void _scheduleBubbleRectMeasurement() {
    if (_bubbleRectMeasurementScheduled) {
      return;
    }

    _bubbleRectMeasurementScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bubbleRectMeasurementScheduled = false;
      _updateBubbleRect();
    });
  }

  void _updateBubbleRect() {
    if (!mounted) {
      return;
    }

    final stackContext = _stackKey.currentContext;
    final bubbleContext = _bubbleKey.currentContext;
    if (stackContext == null || bubbleContext == null) {
      return;
    }

    final stackBox = stackContext.findRenderObject() as RenderBox?;
    final bubbleBox = bubbleContext.findRenderObject() as RenderBox?;
    if (stackBox == null || bubbleBox == null) {
      return;
    }

    final Offset topLeft = bubbleBox.localToGlobal(
      Offset.zero,
      ancestor: stackBox,
    );
    final Rect nextBubbleRect = topLeft & bubbleBox.size;
    if (_bubbleRect != nextBubbleRect) {
      setState(() => _bubbleRect = nextBubbleRect);
    }
  }

  Rect _fallbackBubbleRect(TutorialBubbleSide side) {
    const double bubbleOffset = 24;
    const double fallbackSize = 1;

    switch (side) {
      case TutorialBubbleSide.top:
        return Rect.fromCenter(
          center: widget.targetRect.topCenter.translate(0, -bubbleOffset),
          width: fallbackSize,
          height: fallbackSize,
        );
      case TutorialBubbleSide.bottom:
        return Rect.fromCenter(
          center: widget.targetRect.bottomCenter.translate(0, bubbleOffset),
          width: fallbackSize,
          height: fallbackSize,
        );
      case TutorialBubbleSide.left:
        return Rect.fromCenter(
          center: widget.targetRect.centerLeft.translate(-bubbleOffset, 0),
          width: fallbackSize,
          height: fallbackSize,
        );
      case TutorialBubbleSide.right:
        return Rect.fromCenter(
          center: widget.targetRect.centerRight.translate(bubbleOffset, 0),
          width: fallbackSize,
          height: fallbackSize,
        );
      case TutorialBubbleSide.automatic:
        return Rect.fromCenter(
          center: widget.targetRect.bottomCenter.translate(0, bubbleOffset),
          width: fallbackSize,
          height: fallbackSize,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    _scheduleBubbleRectMeasurement();

    final effectiveArrowSide = widget.preferredSide == TutorialBubbleSide.automatic
        ? (_resolvedSide ?? TutorialBubbleSide.bottom)
        : widget.preferredSide;
    final Widget bubbleChild = widget.child is TutorialBubbleContent
        ? (widget.child as TutorialBubbleContent).buildBubbleContent(context)
        : widget.child;
    final Gradient? effectiveArrowGradient =
        widget.arrowGradient ?? widget.backgroundGradient;
    final Color effectiveArrowColor = widget.arrowGradient == null &&
            widget.arrowColor == const Color(0xFFFFFFFF) &&
            widget.backgroundColor != null
        ? widget.backgroundColor!
        : widget.arrowColor;
    final Rect effectiveBubbleRect =
        _bubbleRect ?? _fallbackBubbleRect(effectiveArrowSide);

    return Stack(
      key: _stackKey,
      fit: StackFit.expand,
      children: [
        IgnorePointer(
          child: CustomPaint(
              painter: TutorialOverlayPainter(
                targetRect: widget.targetRect,
                overlayColor: widget.overlayColor,
                highlightShape: widget.highlightShape,
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
                highlightShape: widget.highlightShape,
              ),
            ),
          ),
        TutorialInteractionBlocker(
          targetRect: widget.targetRect,
          enabled: widget.blockOutsideTarget,
          onTargetTap: widget.onTargetTap,
          onOutsideTap: widget.onBackgroundTap,
          highlightShape: widget.highlightShape,
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
            key: _bubbleKey,
            backgroundColor: widget.backgroundColor,
            backgroundGradient: widget.backgroundGradient,
            haloEnabled: widget.bubbleHaloEnabled,
            haloColor: widget.bubbleHaloColor,
            haloBlurRadius: widget.bubbleHaloBlurRadius,
            haloSpreadRadius: widget.bubbleHaloSpreadRadius,
            child: bubbleChild,
          ),
        ),
        if (widget.arrowEnabled)
          IgnorePointer(
            child: CustomPaint(
              painter: TutorialArrowPainter(
                targetRect: widget.targetRect,
                bubbleRect: effectiveBubbleRect,
                side: effectiveArrowSide,
                color: effectiveArrowColor,
                gradient: effectiveArrowGradient,
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

/// Layout delegate that positions a child bubble relative to a target rectangle.
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
