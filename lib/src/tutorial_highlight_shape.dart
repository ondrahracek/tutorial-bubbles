import 'package:flutter/widgets.dart';

enum TutorialHighlightShapeType { rect, roundedRect, oval }

/// Describes the visible shape of the highlighted target region.
class TutorialHighlightShape {
  const TutorialHighlightShape.rect()
      : type = TutorialHighlightShapeType.rect,
        borderRadius = BorderRadius.zero;

  const TutorialHighlightShape.roundedRect({
    this.borderRadius = BorderRadius.zero,
  }) : type = TutorialHighlightShapeType.roundedRect;

  const TutorialHighlightShape.oval()
      : type = TutorialHighlightShapeType.oval,
        borderRadius = BorderRadius.zero;

  final TutorialHighlightShapeType type;
  final BorderRadius borderRadius;

  Path createPath(Rect rect, {TextDirection textDirection = TextDirection.ltr}) {
    switch (type) {
      case TutorialHighlightShapeType.rect:
        return Path()..addRect(rect);
      case TutorialHighlightShapeType.roundedRect:
        return Path()
          ..addRRect(borderRadius.resolve(textDirection).toRRect(rect));
      case TutorialHighlightShapeType.oval:
        return Path()..addOval(rect);
    }
  }

  bool contains(
    Offset point,
    Rect rect, {
    TextDirection textDirection = TextDirection.ltr,
  }) {
    return createPath(rect, textDirection: textDirection).contains(point);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is TutorialHighlightShape &&
        other.type == type &&
        other.borderRadius == borderRadius;
  }

  @override
  int get hashCode => Object.hash(type, borderRadius);
}
