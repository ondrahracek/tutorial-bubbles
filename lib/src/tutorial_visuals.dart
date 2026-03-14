// Configuration and data models for tutorial bubbles.

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'tutorial_highlight_shape.dart';

/// Immutable configuration for visual parameters used by the tutorial engine.
///
/// These values can be provided globally to [TutorialEngine] and optionally
/// overridden per [TutorialStep]. When both a global and per-step value are
/// provided, the per-step value wins.
class TutorialVisuals {
  const TutorialVisuals({
    this.bubbleBackgroundColor,
    this.bubbleBackgroundGradient,
    this.bubbleCornerRadius,
    this.overlayColor,
    this.arrowEnabled,
    this.arrowColor,
    this.arrowGradient,
    this.arrowHeadLength,
    this.bubbleHaloEnabled,
    this.bubbleHaloColor,
    this.targetHaloEnabled,
    this.targetHaloColor,
    this.targetShineEnabled,
    this.targetShineColor,
    this.targetShineBlurRadius,
    this.highlightShape,
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

  /// Corner radius applied to the rendered tutorial bubble.
  final double? bubbleCornerRadius;

  /// Color of the dimmed overlay that surrounds the target and bubble.
  final Color? overlayColor;

  /// Whether the arrow connecting the bubble toward the target is visible.
  final bool? arrowEnabled;

  /// Solid color used when drawing the arrow stroke.
  final Color? arrowColor;

  /// Gradient used when drawing the arrow stroke.
  final Gradient? arrowGradient;

  /// Length of each arrowhead segment.
  final double? arrowHeadLength;

  /// Whether the bubble should render a halo/glow.
  final bool? bubbleHaloEnabled;

  /// Optional color for the bubble halo.
  final Color? bubbleHaloColor;

  /// Whether the target should render a halo/glow.
  final bool? targetHaloEnabled;

  /// Optional color for the target halo.
  final Color? targetHaloColor;

  /// Whether the target should render an interior shine.
  final bool? targetShineEnabled;

  /// Optional color for the target shine.
  final Color? targetShineColor;

  /// Blur radius for the target shine.
  final double? targetShineBlurRadius;

  /// Shape used for the highlighted target cutout and halo.
  final TutorialHighlightShape? highlightShape;

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
      bubbleCornerRadius: overrides.bubbleCornerRadius ?? bubbleCornerRadius,
      overlayColor: overrides.overlayColor ?? overlayColor,
      arrowEnabled: overrides.arrowEnabled ?? arrowEnabled,
      arrowColor: overrides.arrowColor ?? arrowColor,
      arrowGradient: overrides.arrowGradient ?? arrowGradient,
      arrowHeadLength: overrides.arrowHeadLength ?? arrowHeadLength,
      bubbleHaloEnabled: overrides.bubbleHaloEnabled ?? bubbleHaloEnabled,
      bubbleHaloColor: overrides.bubbleHaloColor ?? bubbleHaloColor,
      targetHaloEnabled: overrides.targetHaloEnabled ?? targetHaloEnabled,
      targetHaloColor: overrides.targetHaloColor ?? targetHaloColor,
      targetShineEnabled: overrides.targetShineEnabled ?? targetShineEnabled,
      targetShineColor: overrides.targetShineColor ?? targetShineColor,
      targetShineBlurRadius:
          overrides.targetShineBlurRadius ?? targetShineBlurRadius,
      highlightShape: overrides.highlightShape ?? highlightShape,
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

  static String _storageKey(String tutorialId) => '$_keyPrefix$tutorialId';

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

  static Future<bool> readCompleted(String completedKey) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_storageKey(completedKey)) ?? false;
  }

  static Future<void> writeCompleted(String completedKey, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_storageKey(completedKey), value);
  }

  static Future<void> clearCompleted(String completedKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey(completedKey));
  }
}
