// Interaction blocking widgets for tutorial overlays.

import 'package:flutter/widgets.dart';
import 'package:flutter/rendering.dart';

import 'tutorial_highlight_shape.dart';

/// Widget that blocks interactions outside the highlighted target region.
///
/// Creates absorbing regions around the target rectangle to prevent taps
/// from reaching the underlying content, while optionally allowing taps
/// on the target itself or on the background area.
class TutorialInteractionBlocker extends StatelessWidget {
  const TutorialInteractionBlocker({
    super.key,
    required this.targetRect,
    required this.enabled,
    this.highlightShape = const TutorialHighlightShape.rect(),
    this.onTargetTap,
    this.onOutsideTap,
  });

  final Rect targetRect;
  final bool enabled;
  final TutorialHighlightShape highlightShape;
  final VoidCallback? onTargetTap;
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
          return _ShapeInteractionBarrier(
            targetRect: clamped,
            highlightShape: highlightShape,
            onTargetTap: onTargetTap,
            onOutsideTap: onOutsideTap,
          );
        }

        return _ShapeInteractionBarrier(
          targetRect: clamped,
          highlightShape: highlightShape,
          onTargetTap: onTargetTap,
          onOutsideTap: onOutsideTap,
        );
      },
    );
  }
}

class _ShapeInteractionBarrier extends LeafRenderObjectWidget {
  const _ShapeInteractionBarrier({
    required this.targetRect,
    required this.highlightShape,
    this.onTargetTap,
    this.onOutsideTap,
  });

  final Rect targetRect;
  final TutorialHighlightShape highlightShape;
  final VoidCallback? onTargetTap;
  final VoidCallback? onOutsideTap;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderShapeInteractionBarrier(
      targetRect: targetRect,
      highlightShape: highlightShape,
      textDirection: Directionality.maybeOf(context) ?? TextDirection.ltr,
      onTargetTap: onTargetTap,
      onOutsideTap: onOutsideTap,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant _RenderShapeInteractionBarrier renderObject,
  ) {
    renderObject
      ..targetRect = targetRect
      ..highlightShape = highlightShape
      ..textDirection = Directionality.maybeOf(context) ?? TextDirection.ltr
      ..onTargetTap = onTargetTap
      ..onOutsideTap = onOutsideTap;
  }
}

class _RenderShapeInteractionBarrier extends RenderBox {
  _RenderShapeInteractionBarrier({
    required Rect targetRect,
    required TutorialHighlightShape highlightShape,
    required TextDirection textDirection,
    VoidCallback? onTargetTap,
    VoidCallback? onOutsideTap,
  })  : _targetRect = targetRect,
        _highlightShape = highlightShape,
        _textDirection = textDirection,
        _onTargetTap = onTargetTap,
        _onOutsideTap = onOutsideTap;

  Rect _targetRect;
  TutorialHighlightShape _highlightShape;
  TextDirection _textDirection;
  VoidCallback? _onTargetTap;
  VoidCallback? _onOutsideTap;

  set targetRect(Rect value) {
    if (_targetRect == value) {
      return;
    }
    _targetRect = value;
    markNeedsPaint();
  }

  set highlightShape(TutorialHighlightShape value) {
    if (_highlightShape == value) {
      return;
    }
    _highlightShape = value;
    markNeedsPaint();
  }

  set textDirection(TextDirection value) {
    if (_textDirection == value) {
      return;
    }
    _textDirection = value;
    markNeedsPaint();
  }

  set onTargetTap(VoidCallback? value) {
    _onTargetTap = value;
  }

  set onOutsideTap(VoidCallback? value) {
    _onOutsideTap = value;
  }

  bool _isInsideTarget(Offset position) {
    if (_targetRect.isEmpty) {
      return false;
    }
    return _highlightShape.contains(
      position,
      _targetRect,
      textDirection: _textDirection,
    );
  }

  @override
  void performLayout() {
    size = constraints.biggest;
  }

  @override
  bool hitTestSelf(Offset position) {
    final bool insideTarget = _isInsideTarget(position);
    if (insideTarget) {
      return _onTargetTap != null;
    }

    return true;
  }

  @override
  void handleEvent(PointerEvent event, covariant BoxHitTestEntry entry) {
    if (event is! PointerUpEvent) {
      return;
    }

    final bool insideTarget = _isInsideTarget(event.localPosition);
    if (insideTarget) {
      _onTargetTap?.call();
    } else {
      _onOutsideTap?.call();
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {}
}
