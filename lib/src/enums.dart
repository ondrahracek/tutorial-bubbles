// Core enum definitions for tutorial bubbles.

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
