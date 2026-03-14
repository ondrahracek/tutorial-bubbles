// Main tutorial engine widget that orchestrates the tutorial overlay.

import 'dart:async';

import 'package:flutter/widgets.dart';

import 'enums.dart';
import 'tutorial_bubble_overlay.dart';
import 'tutorial_controller.dart';
import 'tutorial_highlight_shape.dart';
import 'tutorial_models.dart';
import 'tutorial_visuals.dart';

/// Widget that renders a tutorial overlay for the current [TutorialStep].
///
/// This widget composes the same visual primitives used in standalone
/// spotlight mode: it measures the current step's [TutorialStep.target]
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
    this.persistence,
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

  /// Optional persistence policy for saving tutorial progress.
  final TutorialPersistence? persistence;

  /// Optional identifier used to persist and restore tutorial progress.
  ///
  /// Deprecated compatibility shortcut for simple persistence.
  ///
  /// Prefer [persistence] for new code.
  final String? persistenceId;

  /// Deprecated compatibility shortcut for checkpoint persistence.
  ///
  /// Prefer [persistence] for new code.
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
  bool _isPersistedCompleted = false;
  bool _isPreparingStep = false;
  int _stepPreparationGeneration = 0;
  int _activeTargetTapToken = 0;
  bool _isHandlingTargetTap = false;

  TutorialEngineController get _controller => widget.controller;

  TutorialPersistence? get _effectivePersistence {
    final persistence = widget.persistence;
    if (persistence != null) {
      return persistence;
    }

    final persistenceId = widget.persistenceId;
    if (persistenceId == null) {
      return null;
    }

    final checkpoints = widget.checkpointSteps;
    return TutorialPersistence(
      id: persistenceId,
      saveStrategy: checkpoints == null
          ? TutorialSaveStrategy.everyStep
          : TutorialSaveStrategy.checkpointsOnly,
      checkpoints: checkpoints,
    );
  }

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
    _controller.isStartedListenable.addListener(_handleStartedChanged);
    _controller.isFinishedListenable.addListener(_handleFinishedChanged);
    _maybeLoadPersistedProgress();
  }

  @override
  void didUpdateWidget(TutorialEngine oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.currentIndexListenable
          .removeListener(_handleStepChanged);
      oldWidget.controller.isStartedListenable
          .removeListener(_handleStartedChanged);
      oldWidget.controller.isFinishedListenable
          .removeListener(_handleFinishedChanged);
      _controller.currentIndexListenable.addListener(_handleStepChanged);
      _controller.isStartedListenable.addListener(_handleStartedChanged);
      _controller.isFinishedListenable.addListener(_handleFinishedChanged);
      _triggerStepPreparation();
    }

    if (oldWidget.persistence != widget.persistence ||
        oldWidget.persistenceId != widget.persistenceId ||
        oldWidget.checkpointSteps != widget.checkpointSteps) {
      _hasLoadedPersistedProgress = false;
      _isPersistedCompleted = false;
      _maybeLoadPersistedProgress();
    }
  }

  @override
  void dispose() {
    _resetTargetTapHandling();
    _controller.currentIndexListenable.removeListener(_handleStepChanged);
    _controller.isStartedListenable.removeListener(_handleStartedChanged);
    _controller.isFinishedListenable.removeListener(_handleFinishedChanged);
    super.dispose();
  }

  void _handleStartedChanged() {
    if (!mounted) return;
    setState(() {});
    _triggerStepPreparation();
  }

  void _handleStepChanged() {
    if (!mounted) return;
    _resetTargetTapHandling();
    _persistProgressIfNeeded();
    _triggerStepPreparation();
  }

  void _handleFinishedChanged() {
    if (!mounted) return;
    _clearPersistedProgressIfNeeded();
    _writeCompletedFlagIfNeeded();
    _resetTargetTapHandling();
    final onComplete = widget.onComplete;
    final reason =
        _controller.lastCompletionReason ?? TutorialCompletionReason.completed;
    setState(() {
      _currentTargetRect = null;
      _isPreparingStep = false;
    });
    onComplete?.call(reason);
  }

  void _triggerStepPreparation() {
    final generation = ++_stepPreparationGeneration;

    if (!mounted) {
      return;
    }

    setState(() {
      _currentTargetRect = null;
      _isPreparingStep = _controller.isStarted &&
          !_controller.isFinished &&
          !_isPersistedCompleted;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || generation != _stepPreparationGeneration) {
        return;
      }
      unawaited(_prepareCurrentStep(generation));
    });
  }

  Future<void> _prepareCurrentStep(int generation) async {
    if (!_controller.isStarted ||
        _controller.isFinished ||
        _isPersistedCompleted) {
      if (mounted && generation == _stepPreparationGeneration) {
        setState(() {
          _isPreparingStep = false;
        });
      }
      return;
    }

    final beforeShow = _controller.currentStep.beforeShow;
    if (beforeShow != null) {
      await beforeShow(context, _controller);
      if (!mounted || generation != _stepPreparationGeneration) {
        return;
      }
    }

    if (!mounted || generation != _stepPreparationGeneration) {
      return;
    }

    setState(() {
      _isPreparingStep = false;
    });
    _updateTargetRect(generation: generation);
  }

  void _maybeLoadPersistedProgress() {
    final persistence = _effectivePersistence;
    if (persistence == null || _hasLoadedPersistedProgress) {
      return;
    }
    _hasLoadedPersistedProgress = true;

    unawaited(() async {
      final isCompleted = await TutorialProgressStorage.readCompleted(
        persistence.effectiveCompletedKey,
      );
      if (!mounted) {
        return;
      }
      if (isCompleted) {
        setState(() {
          _isPersistedCompleted = true;
        });
        return;
      }

      final savedIndex =
          await TutorialProgressStorage.readIndex(persistence.id);
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
    final persistence = _effectivePersistence;
    if (persistence == null ||
        _controller.isFinished ||
        _isPersistedCompleted ||
        persistence.saveStrategy == TutorialSaveStrategy.manual) {
      return;
    }
    if (persistence.saveStrategy == TutorialSaveStrategy.checkpointsOnly) {
      final checkpoints = persistence.checkpoints;
      if (checkpoints == null ||
          !checkpoints.contains(_controller.currentIndex)) {
        return;
      }
    }
    unawaited(TutorialProgressStorage.writeIndex(
      persistence.id,
      _controller.currentIndex,
    ));
  }

  void _clearPersistedProgressIfNeeded() {
    final persistence = _effectivePersistence;
    if (persistence == null || !persistence.clearOnComplete) {
      return;
    }
    unawaited(TutorialProgressStorage.clear(persistence.id));
  }

  void _writeCompletedFlagIfNeeded() {
    final persistence = _effectivePersistence;
    if (persistence == null) {
      return;
    }
    if (_controller.lastCompletionReason ==
        TutorialCompletionReason.completed) {
      _isPersistedCompleted = true;
      unawaited(TutorialProgressStorage.writeCompleted(
        persistence.effectiveCompletedKey,
        true,
      ));
    }
  }

  Future<void> _handleOverlayTap() async {
    final behavior = _controller.currentStep.behavior;
    await behavior?.onOverlayTap?.call(context);
    if (!mounted || _controller.isFinished) {
      return;
    }
    if ((behavior?.advanceOnOverlayTap ?? widget.advanceOnOverlayTap)) {
      _controller.advance();
    }
  }

  void _resetTargetTapHandling() {
    _activeTargetTapToken += 1;
    _isHandlingTargetTap = false;
  }

  Future<void> _handleTargetTap() async {
    if (_isHandlingTargetTap || _controller.isFinished) {
      return;
    }

    final behavior = _controller.currentStep.behavior;
    final step = _controller.currentStep;
    final stepIndex = _controller.currentIndex;
    final token = ++_activeTargetTapToken;
    _isHandlingTargetTap = true;

    await behavior?.onTargetTap?.call(context);

    if (!mounted ||
        _controller.isFinished ||
        token != _activeTargetTapToken ||
        _controller.currentIndex != stepIndex ||
        !identical(_controller.currentStep, step)) {
      if (token == _activeTargetTapToken) {
        _isHandlingTargetTap = false;
      }
      return;
    }

    _isHandlingTargetTap = false;
    if (behavior?.advanceOnTargetTap ?? false) {
      _controller.advance();
    }
  }

  Future<void> _handleBubbleTap() async {
    final behavior = _controller.currentStep.behavior;
    if ((behavior?.advanceOnBubbleTap ?? widget.advanceOnBubbleTap) &&
        !_controller.isFinished) {
      _controller.advance();
    }
  }

  void _scheduleTargetRectUpdateRetry(int generation) {
    if (!mounted ||
        _controller.isFinished ||
        _pendingTargetRectUpdate ||
        generation != _stepPreparationGeneration) {
      return;
    }
    _pendingTargetRectUpdate = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _updateTargetRect(generation: generation);
    });
  }

  bool _isValidRect(Rect rect) {
    return rect.width > 0 &&
        rect.height > 0 &&
        rect.left.isFinite &&
        rect.top.isFinite &&
        rect.right.isFinite &&
        rect.bottom.isFinite;
  }

  Rect? _resolveTargetRect() {
    final target = _controller.currentStep.target;
    if (target is KeyTutorialTarget) {
      final targetContext = target.key.currentContext;
      final overlayContext = _overlayKey.currentContext;

      if (targetContext == null || overlayContext == null) {
        return null;
      }

      final targetBox = targetContext.findRenderObject() as RenderBox?;
      final overlayBox = overlayContext.findRenderObject() as RenderBox?;

      if (targetBox == null || overlayBox == null) {
        return null;
      }

      final topLeft =
          targetBox.localToGlobal(Offset.zero, ancestor: overlayBox);
      return topLeft & targetBox.size;
    }

    if (target is RectTutorialTarget) {
      final overlayContext = _overlayKey.currentContext;
      if (overlayContext == null) {
        return null;
      }
      return target.resolver(overlayContext);
    }

    return null;
  }

  void _updateTargetRect({int? generation}) {
    _pendingTargetRectUpdate = false;

    if (generation != null && generation != _stepPreparationGeneration) {
      return;
    }

    if (_controller.isFinished) {
      if (_currentTargetRect != null) {
        setState(() {
          _currentTargetRect = null;
        });
      }
      return;
    }

    final nextRect = _resolveTargetRect();
    if (nextRect == null || !_isValidRect(nextRect)) {
      _scheduleTargetRectUpdateRetry(generation ?? _stepPreparationGeneration);
      return;
    }

    if (_currentTargetRect != nextRect) {
      setState(() {
        _currentTargetRect = nextRect;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final stepBehavior = _controller.currentStep.behavior;
    final advanceOnBubbleTap =
        stepBehavior?.advanceOnBubbleTap ?? widget.advanceOnBubbleTap;
    final blockOutsideTarget = stepBehavior?.blockOutsideTarget ?? true;
    final allowTargetTap = stepBehavior?.allowTargetTap ?? true;
    final hasTargetTapHandler = stepBehavior?.onTargetTap != null;
    final advanceOnTargetTap = stepBehavior?.advanceOnTargetTap ?? false;
    final hasOverlayTapHandler = stepBehavior?.onOverlayTap != null;
    final advanceOnOverlayTap =
        stepBehavior?.advanceOnOverlayTap ?? widget.advanceOnOverlayTap;
    final bool showOverlay = _controller.isStarted &&
        !_controller.isFinished &&
        !_isPersistedCompleted &&
        !_isPreparingStep &&
        _currentTargetRect != null;

    final visuals = _resolveVisuals();

    if (_controller.isStarted && !_controller.isFinished && !_isPreparingStep) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _updateTargetRect();
        }
      });
    }

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
                  preferredSide: _controller.currentStep.preferredSide ??
                      TutorialBubbleSide.automatic,
                  overlayColor:
                      visuals?.overlayColor ?? const Color(0xB3000000),
                  backgroundColor: visuals?.bubbleBackgroundColor,
                  backgroundGradient: visuals?.bubbleBackgroundGradient,
                  bubbleCornerRadius: visuals?.bubbleCornerRadius ?? 12,
                  targetHaloEnabled: visuals?.targetHaloEnabled ?? false,
                  targetHaloColor: visuals?.targetHaloColor,
                  targetShineEnabled: visuals?.targetShineEnabled ?? false,
                  targetShineColor: visuals?.targetShineColor,
                  targetShineBlurRadius: visuals?.targetShineBlurRadius ?? 18,
                  highlightShape: visuals?.highlightShape ??
                      const TutorialHighlightShape.rect(),
                  bubbleHaloEnabled: visuals?.bubbleHaloEnabled ?? false,
                  bubbleHaloColor: visuals?.bubbleHaloColor,
                  arrowEnabled: visuals?.arrowEnabled ?? true,
                  arrowColor: visuals?.arrowColor ?? const Color(0xFFFFFFFF),
                  arrowGradient: visuals?.arrowGradient,
                  arrowHeadLength: visuals?.arrowHeadLength ?? 10,
                  arrowHaloEnabled: visuals?.arrowHaloEnabled ?? false,
                  arrowHaloColor: visuals?.arrowHaloColor,
                  blockOutsideTarget: blockOutsideTarget,
                  allowTargetTap: allowTargetTap,
                  onTargetTap: (hasTargetTapHandler || advanceOnTargetTap)
                      ? () {
                          unawaited(_handleTargetTap());
                        }
                      : null,
                  onBackgroundTap: (advanceOnOverlayTap || hasOverlayTapHandler)
                      ? () {
                          unawaited(_handleOverlayTap());
                        }
                      : null,
                  child: Builder(
                    builder: (context) {
                      final bubble =
                          _controller.currentStep.bubbleBuilder(context);
                      Widget styledBubble = bubble;

                      if (visuals?.textStyle != null) {
                        styledBubble = DefaultTextStyle.merge(
                          style: visuals!.textStyle!,
                          child: styledBubble,
                        );
                      }

                      if (!advanceOnBubbleTap) {
                        return styledBubble;
                      }
                      return GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: () {
                          unawaited(_handleBubbleTap());
                        },
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
