// Configuration and data models for tutorial bubbles.

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Immutable configuration for visual parameters used by the tutorial engine.
///
/// These values can be provided globally to [TutorialEngine] and optionally
/// overridden per [TutorialStep]. When both a global and per-step value are
/// provided, the per-step value wins.
class TutorialVisuals {
  const TutorialVisuals({
    this.bubbleBackgroundColor,
    this.bubbleBackgroundGradient,
    this.overlayColor,
    this.arrowEnabled,
    this.bubbleHaloEnabled,
    this.bubbleHaloColor,
    this.targetHaloEnabled,
    this.targetHaloColor,
    this.arrowHaloEnabled,
    this.arrowHaloColor,
    this.textStyle,
  });

  /// Background color applied to the bubble when no gradient is used.
  final Color? bubbleBackgroundColor;

  /// Gradient applied to the bubble background.
  ///
  /// When provided, this takes precedence over [bubbleBackgroundColor].
  final Gradient? bubbleBackgroundGradient;

  /// Color of the dimmed overlay that surrounds the target and bubble.
  final Color? overlayColor;

  /// Whether the arrow connecting the bubble toward the target is visible.
  final bool? arrowEnabled;

  /// Whether the bubble should render a halo/glow.
  final bool? bubbleHaloEnabled;

  /// Optional color for the bubble halo.
  final Color? bubbleHaloColor;

  /// Whether the target should render a halo/glow.
  final bool? targetHaloEnabled;

  /// Optional color for the target halo.
  final Color? targetHaloColor;

  /// Whether the arrow should render a halo/glow.
  final bool? arrowHaloEnabled;

  /// Optional color for the arrow halo.
  final Color? arrowHaloColor;

  /// Optional text style applied to bubble content.
  ///
  /// This is applied via [DefaultTextStyle.merge] so that it can provide
  /// a consistent baseline across all steps while still allowing widgets
  /// such as [TutorialTextBubble] to override specific fields when needed.
  final TextStyle? textStyle;

  /// Returns a new [TutorialVisuals] where non-null fields from [overrides]
  /// replace the corresponding fields in this instance.
  TutorialVisuals merge(TutorialVisuals? overrides) {
    if (overrides == null) {
      return this;
    }

    return TutorialVisuals(
      bubbleBackgroundColor:
          overrides.bubbleBackgroundColor ?? bubbleBackgroundColor,
      bubbleBackgroundGradient:
          overrides.bubbleBackgroundGradient ?? bubbleBackgroundGradient,
      overlayColor: overrides.overlayColor ?? overlayColor,
      arrowEnabled: overrides.arrowEnabled ?? arrowEnabled,
      bubbleHaloEnabled: overrides.bubbleHaloEnabled ?? bubbleHaloEnabled,
      bubbleHaloColor: overrides.bubbleHaloColor ?? bubbleHaloColor,
      targetHaloEnabled: overrides.targetHaloEnabled ?? targetHaloEnabled,
      targetHaloColor: overrides.targetHaloColor ?? targetHaloColor,
      arrowHaloEnabled: overrides.arrowHaloEnabled ?? arrowHaloEnabled,
      arrowHaloColor: overrides.arrowHaloColor ?? arrowHaloColor,
      textStyle: overrides.textStyle ?? textStyle,
    );
  }
}

/// Simple key-value storage for persisting tutorial progress across app restarts.
///
/// This implementation uses [SharedPreferences] under the hood so callers do not
/// need to provide their own persistence layer. Progress is stored as the
/// zero-based index of the last active step for a given tutorial identifier.
class TutorialProgressStorage {
  TutorialProgressStorage._();

  static const String _keyPrefix = 'tutorial_bubbles_progress_';

  static String _storageKey(String tutorialId) =>
      '$_keyPrefix$tutorialId';

  /// Reads the persisted zero-based step index for the given [tutorialId].
  ///
  /// Returns null when no progress has been saved yet.
  static Future<int?> readIndex(String tutorialId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_storageKey(tutorialId));
  }

  /// Persists the given zero-based [stepIndex] for the provided [tutorialId].
  static Future<void> writeIndex(String tutorialId, int stepIndex) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_storageKey(tutorialId), stepIndex);
  }

  /// Clears any saved progress for the provided [tutorialId].
  static Future<void> clear(String tutorialId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey(tutorialId));
  }
}

/// Immutable description of a single tutorial step.
///
/// Each step identifies a target widget by [targetKey] and provides
/// [bubbleBuilder] to build the bubble content for that step. Visual
/// parameters can optionally be customized per-step via [visuals].
class TutorialStep {
  const TutorialStep({
    required this.targetKey,
    required this.bubbleBuilder,
    this.visuals,
  });

  /// Key of the widget that should be highlighted for this step.
  ///
  /// The engine uses this key to locate the widget and compute its
  /// layout rectangle for the bubble and overlay.
  final GlobalKey targetKey;

  /// Builder used to create the bubble contents for this step.
  final WidgetBuilder bubbleBuilder;

  /// Optional per-step overrides for visual parameters.
  ///
  /// When provided together with [TutorialEngine.globalVisuals], any
  /// non-null fields here override the corresponding global defaults.
  final TutorialVisuals? visuals;
}
