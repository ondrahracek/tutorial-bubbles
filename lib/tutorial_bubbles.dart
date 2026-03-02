library tutorial_bubbles;

import 'package:flutter/widgets.dart';

/// A simple widget that displays the given [child].
///
/// This is a placeholder for the tutorial bubbles API and will
/// evolve as more PRD features are implemented.
class TutorialBubble extends StatelessWidget {
  const TutorialBubble({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return child;
  }
}

