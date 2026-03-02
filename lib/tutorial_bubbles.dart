library tutorial_bubbles;

import 'package:flutter/widgets.dart';

/// A simple bubble widget that wraps the given [child] with a
/// configurable background.
class TutorialBubble extends StatelessWidget {
  const TutorialBubble({
    super.key,
    required this.child,
    this.backgroundColor,
  });

  final Widget child;
  final Color? backgroundColor;

  static const Color _defaultBackgroundColor = Color(0xFF303030);

  @override
  Widget build(BuildContext context) {
    final color = backgroundColor ?? _defaultBackgroundColor;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
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

