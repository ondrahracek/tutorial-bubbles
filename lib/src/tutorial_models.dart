import 'dart:async';

import 'package:flutter/widgets.dart';

import 'enums.dart';
import 'tutorial_controller.dart';
import 'tutorial_visuals.dart';

typedef TutorialRectResolver = Rect Function(BuildContext context);
typedef TutorialBeforeShow = Future<void> Function(
  BuildContext context,
  TutorialEngineController controller,
);
typedef TutorialStepCallback = FutureOr<void> Function(BuildContext context);

abstract class TutorialTarget {
  const TutorialTarget();

  const factory TutorialTarget.key(GlobalKey key) = KeyTutorialTarget;
  const factory TutorialTarget.rect(TutorialRectResolver resolver) =
      RectTutorialTarget;
}

class KeyTutorialTarget extends TutorialTarget {
  const KeyTutorialTarget(this.key);

  final GlobalKey key;
}

class RectTutorialTarget extends TutorialTarget {
  const RectTutorialTarget(this.resolver);

  final TutorialRectResolver resolver;
}

class TutorialStepBehavior {
  const TutorialStepBehavior({
    this.advanceOnBubbleTap,
    this.advanceOnOverlayTap,
    this.advanceOnTargetTap,
    this.allowTargetTap = true,
    this.blockOutsideTarget = true,
    this.onTargetTap,
    this.onOverlayTap,
  });

  final bool? advanceOnBubbleTap;
  final bool? advanceOnOverlayTap;
  final bool? advanceOnTargetTap;
  final bool allowTargetTap;
  final bool blockOutsideTarget;
  final TutorialStepCallback? onTargetTap;
  final TutorialStepCallback? onOverlayTap;
}

enum TutorialSaveStrategy {
  everyStep,
  checkpointsOnly,
  manual,
}

enum TutorialCompletionPersistencePolicy {
  completedOnly,
  completedOrSkipped,
  always,
}

class TutorialPersistence {
  const TutorialPersistence({
    required this.id,
    this.saveStrategy = TutorialSaveStrategy.everyStep,
    this.checkpoints,
    this.clearOnComplete = true,
    this.completedKey,
    this.completionPersistencePolicy =
        TutorialCompletionPersistencePolicy.completedOnly,
  });

  final String id;
  final TutorialSaveStrategy saveStrategy;
  final Set<int>? checkpoints;
  final bool clearOnComplete;
  final String? completedKey;
  final TutorialCompletionPersistencePolicy completionPersistencePolicy;

  String get effectiveCompletedKey => completedKey ?? '${id}_completed';
}

/// Immutable description of a single tutorial step.
class TutorialStep {
  TutorialStep({
    TutorialTarget? target,
    GlobalKey? targetKey,
    required this.bubbleBuilder,
    this.visuals,
    this.behavior,
    this.beforeShow,
    this.preferredSide,
    this.id,
  })  : assert(
          target != null || targetKey != null,
          'TutorialStep requires either target or targetKey.',
        ),
        assert(
          target == null || targetKey == null,
          'TutorialStep target and targetKey are mutually exclusive.',
        ),
        target = target ?? TutorialTarget.key(targetKey!);

  final TutorialTarget target;
  final WidgetBuilder bubbleBuilder;
  final TutorialVisuals? visuals;
  final TutorialStepBehavior? behavior;
  final TutorialBeforeShow? beforeShow;
  final TutorialBubbleSide? preferredSide;
  final String? id;

  @Deprecated('Use target instead.')
  GlobalKey get targetKey {
    final currentTarget = target;
    if (currentTarget is! KeyTutorialTarget) {
      throw StateError(
          'This tutorial step uses a rect target instead of a GlobalKey target.');
    }
    return currentTarget.key;
  }
}
