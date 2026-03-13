// Custom painters for rendering tutorial overlay visuals.

import 'package:flutter/widgets.dart';

import 'enums.dart';
import 'tutorial_highlight_shape.dart';

/// Paints the dimming overlay with a cutout for the highlighted target.
class TutorialOverlayPainter extends CustomPainter {
  TutorialOverlayPainter({
    required this.targetRect,
    required this.overlayColor,
    this.highlightShape = const TutorialHighlightShape.rect(),
  });

  final Rect targetRect;
  final Color overlayColor;
  final TutorialHighlightShape highlightShape;

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
      canvas.drawPath(highlightShape.createPath(highlightRect), clearPaint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(TutorialOverlayPainter oldDelegate) {
    return oldDelegate.targetRect != targetRect ||
        oldDelegate.overlayColor != overlayColor ||
        oldDelegate.highlightShape != highlightShape;
  }
}

/// Paints an arrow connecting the bubble toward the highlighted target.
class TutorialArrowPainter extends CustomPainter {
  TutorialArrowPainter({
    required this.targetRect,
    required this.bubbleRect,
    required this.side,
    required this.color,
    this.gradient,
    required this.strokeWidth,
    this.arrowHeadLength = 10,
    this.haloEnabled = false,
    this.haloColor,
    this.haloBlurRadius = 8,
    this.haloStrokeWidthMultiplier = 2,
  });

  final Rect targetRect;
  final Rect bubbleRect;
  final TutorialBubbleSide side;
  final Color color;
  final Gradient? gradient;
  final double strokeWidth;
  final double arrowHeadLength;
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

    // Keep the arrow body and head entirely outside the target by ending the
    // curved body just before the tip on the target border.
    final double clampedHeadLength =
        fullDist > arrowHeadLength ? arrowHeadLength : fullDist * 0.5;
    final Offset direction = fullLine / fullDist;
    final Offset bodyEnd = tip - direction * clampedHeadLength;

    if (gradient != null) {
      final Rect shaderRect = Rect.fromPoints(fromBubble, tip).inflate(strokeWidth * 2);
      arrowPaint.shader = gradient!.createShader(shaderRect);
    }

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
    switch (side) {
      case TutorialBubbleSide.top:
        return Offset(
          toTarget.dx.clamp(bubbleRect.left, bubbleRect.right),
          bubbleRect.bottom,
        );
      case TutorialBubbleSide.bottom:
        return Offset(
          toTarget.dx.clamp(bubbleRect.left, bubbleRect.right),
          bubbleRect.top,
        );
      case TutorialBubbleSide.left:
        return Offset(
          bubbleRect.right,
          toTarget.dy.clamp(bubbleRect.top, bubbleRect.bottom),
        );
      case TutorialBubbleSide.right:
        return Offset(
          bubbleRect.left,
          toTarget.dy.clamp(bubbleRect.top, bubbleRect.bottom),
        );
      case TutorialBubbleSide.automatic:
        return Offset(
          toTarget.dx.clamp(bubbleRect.left, bubbleRect.right),
          bubbleRect.top,
        );
    }
  }

  @override
  bool shouldRepaint(TutorialArrowPainter oldDelegate) {
    return oldDelegate.targetRect != targetRect ||
        oldDelegate.bubbleRect != bubbleRect ||
        oldDelegate.side != side ||
        oldDelegate.color != color ||
        oldDelegate.gradient != gradient ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.arrowHeadLength != arrowHeadLength ||
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
    this.highlightShape = const TutorialHighlightShape.rect(),
  });

  final Rect targetRect;
  final Color overlayColor;
  final Color? color;
  final double blurRadius;
  final double strokeWidth;
  final TutorialHighlightShape highlightShape;

  @override
  void paint(Canvas canvas, Size size) {
    if (overlayColor.a == 0) {
      return;
    }

    final Rect haloRect = targetRect.inflate(6);

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

    canvas.drawPath(highlightShape.createPath(haloRect), haloPaint);
  }

  @override
  bool shouldRepaint(TutorialTargetHaloPainter oldDelegate) {
    return oldDelegate.targetRect != targetRect ||
        oldDelegate.overlayColor != overlayColor ||
        oldDelegate.color != color ||
        oldDelegate.blurRadius != blurRadius ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.highlightShape != highlightShape;
  }
}

/// Painter that draws a soft white-ish glow inside the highlighted target.
class TutorialTargetShinePainter extends CustomPainter {
  TutorialTargetShinePainter({
    required this.targetRect,
    this.color,
    this.blurRadius = 18,
    this.highlightShape = const TutorialHighlightShape.rect(),
  });

  final Rect targetRect;
  final Color? color;
  final double blurRadius;
  final TutorialHighlightShape highlightShape;

  @override
  void paint(Canvas canvas, Size size) {
    if (targetRect.isEmpty) {
      return;
    }

    final Path targetPath = highlightShape.createPath(targetRect);
    final Color effectiveColor = color ?? const Color(0xCCFFFFFF);
    final Paint shinePaint = Paint()
      ..color = effectiveColor.withValues(alpha: effectiveColor.a * 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..maskFilter = MaskFilter.blur(BlurStyle.outer, blurRadius);
    canvas.drawPath(targetPath, shinePaint);
  }

  @override
  bool shouldRepaint(TutorialTargetShinePainter oldDelegate) {
    return oldDelegate.targetRect != targetRect ||
        oldDelegate.color != color ||
        oldDelegate.blurRadius != blurRadius ||
        oldDelegate.highlightShape != highlightShape;
  }
}
