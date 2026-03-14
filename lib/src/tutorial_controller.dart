// Controller for managing tutorial step navigation.

import 'package:flutter/widgets.dart';

import 'enums.dart';
import 'tutorial_models.dart';

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
