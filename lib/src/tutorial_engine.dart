// Main tutorial engine widget that orchestrates the tutorial overlay.

import 'dart:async';

import 'package:flutter/widgets.dart';

import 'enums.dart';
import 'tutorial_bubble_overlay.dart';
import 'tutorial_controller.dart';
import 'tutorial_highlight_shape.dart';
import 'tutorial_visuals.dart';

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
                  targetShineEnabled: visuals?.targetShineEnabled ?? false,
                  targetShineColor: visuals?.targetShineColor,
                  targetShineBlurRadius: visuals?.targetShineBlurRadius ?? 18,
                  highlightShape:
                      visuals?.highlightShape ?? const TutorialHighlightShape.rect(),
                  bubbleHaloEnabled: visuals?.bubbleHaloEnabled ?? false,
                  bubbleHaloColor: visuals?.bubbleHaloColor,
                  arrowEnabled: visuals?.arrowEnabled ?? true,
                  arrowColor: visuals?.arrowColor ?? const Color(0xFFFFFFFF),
                  arrowGradient: visuals?.arrowGradient,
                  arrowHeadLength: visuals?.arrowHeadLength ?? 10,
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
