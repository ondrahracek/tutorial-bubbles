// Bubble widgets for tutorial content display.

import 'package:flutter/widgets.dart';

/// Implemented by widgets that can provide bubble content without drawing
/// their own outer bubble chrome.
abstract class TutorialBubbleContent {
  Widget buildBubbleContent(BuildContext context);
}

/// A simple bubble widget that wraps the given [child] with a
/// configurable background.
class TutorialBubble extends StatelessWidget {
  const TutorialBubble({
    super.key,
    required this.child,
    this.backgroundColor,
    this.backgroundGradient,
    this.borderColor,
    this.borderWidth = 0,
    this.haloEnabled = false,
    this.haloColor,
    this.haloBlurRadius = 16,
    this.haloSpreadRadius = 2,
    this.enableTapScaleAnimation = false,
    this.onTap,
    this.cornerRadius = 12,
  });

  final Widget child;
  final Color? backgroundColor;
  final Gradient? backgroundGradient;
  final Color? borderColor;

  /// Width of the optional border around the bubble.
  ///
  /// A value of 0 (the default) disables the border. When the border is
  /// visible, its default color is slightly darker than the bubble background,
  /// and callers can override the color via [borderColor].
  final double borderWidth;

  /// Whether to draw a glow/halo around the bubble.
  ///
  /// When enabled, a soft shadow is rendered around the bubble using
  /// [haloColor], [haloBlurRadius], and [haloSpreadRadius].
  final bool haloEnabled;

  /// Optional color for the halo glow.
  ///
  /// When null, a color derived from the bubble background is used.
  final Color? haloColor;

  /// Blur radius for the halo glow.
  final double haloBlurRadius;

  /// Spread radius for the halo glow.
  final double haloSpreadRadius;

  /// Whether tapping the bubble should trigger a spring-like
  /// scale animation.
  final bool enableTapScaleAnimation;

  /// Optional tap callback invoked when the bubble is tapped.
  ///
  /// When [enableTapScaleAnimation] is true, the callback is invoked
  /// and the scale animation plays.
  final VoidCallback? onTap;

  /// Corner radius applied to the bubble background.
  ///
  /// The default value of 12 gives the bubble a soft, rounded,
  /// bubble-like appearance. Callers can adjust this to customize
  /// how round the bubble corners appear.
  final double cornerRadius;

  static const Color _defaultBackgroundColor = Color(0xFF303030);

  @override
  Widget build(BuildContext context) {
    return _TutorialBubbleBody(
      backgroundColor: backgroundColor,
      backgroundGradient: backgroundGradient,
      borderColor: borderColor,
      borderWidth: borderWidth,
      haloEnabled: haloEnabled,
      haloColor: haloColor,
      haloBlurRadius: haloBlurRadius,
      haloSpreadRadius: haloSpreadRadius,
      enableTapScaleAnimation: enableTapScaleAnimation,
      onTap: onTap,
      cornerRadius: cornerRadius,
      child: child,
    );
  }
}

class _TutorialBubbleBody extends StatefulWidget {
  const _TutorialBubbleBody({
    required this.child,
    required this.backgroundColor,
    required this.backgroundGradient,
    required this.borderColor,
    required this.borderWidth,
    required this.haloEnabled,
    required this.haloColor,
    required this.haloBlurRadius,
    required this.haloSpreadRadius,
    required this.enableTapScaleAnimation,
    required this.onTap,
    required this.cornerRadius,
  });

  final Widget child;
  final Color? backgroundColor;
  final Gradient? backgroundGradient;
  final Color? borderColor;
  final double borderWidth;
  final bool haloEnabled;
  final Color? haloColor;
  final double haloBlurRadius;
  final double haloSpreadRadius;
  final bool enableTapScaleAnimation;
  final VoidCallback? onTap;
  final double cornerRadius;

  @override
  State<_TutorialBubbleBody> createState() => _TutorialBubbleBodyState();
}

class _TutorialBubbleBodyState extends State<_TutorialBubbleBody>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  Animation<double>? _scaleAnimation;

  void _ensureController() {
    if (_controller != null) {
      return;
    }

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
      value: 1.0,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller!,
      curve: Curves.elasticOut,
    );
  }

  void _handleTap() {
    widget.onTap?.call();

    if (!widget.enableTapScaleAnimation) {
      return;
    }

    _ensureController();

    _controller!
      ..stop()
      ..value = 0.9
      ..animateTo(
        1.0,
        duration: const Duration(milliseconds: 260),
        curve: Curves.elasticOut,
      );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color defaultBackground =
        widget.backgroundColor ?? TutorialBubble._defaultBackgroundColor;

    final Color haloFallbackColor =
        widget.backgroundGradient == null
            ? defaultBackground
            : TutorialBubble._defaultBackgroundColor;

    final List<BoxShadow>? boxShadow =
        (widget.haloEnabled || widget.haloColor != null)
            ? <BoxShadow>[
                BoxShadow(
                  color: widget.haloColor ?? haloFallbackColor,
                  blurRadius: widget.haloBlurRadius,
                  spreadRadius: widget.haloSpreadRadius,
                ),
              ]
            : null;

    Border? border;
    if (widget.borderWidth > 0) {
      final Color base = widget.backgroundGradient == null
          ? defaultBackground
          : TutorialBubble._defaultBackgroundColor;
      final Color effectiveBorderColor =
          widget.borderColor ?? _darkerColor(base);
      border = Border.all(
        color: effectiveBorderColor,
        width: widget.borderWidth,
      );
    }

    final decoration = BoxDecoration(
      color: widget.backgroundGradient == null ? defaultBackground : null,
      gradient: widget.backgroundGradient,
      borderRadius: BorderRadius.circular(widget.cornerRadius),
      border: border,
      boxShadow: boxShadow,
    );

    Widget result = DecoratedBox(
      decoration: decoration,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        child: widget.child,
      ),
    );

    if (widget.onTap != null || widget.enableTapScaleAnimation) {
      result = GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _handleTap,
        child: result,
      );
    }

    if (widget.enableTapScaleAnimation) {
      _ensureController();

      result = ScaleTransition(
        scale: _scaleAnimation!,
        child: result,
      );
    }

    return result;
  }

  Color _darkerColor(Color color) {
    const double factor = 0.85;
    int scale(double channel) =>
        ((channel * factor) * 255.0).round() & 0xff;
    final int alpha = (color.a * 255.0).round() & 0xff;
    return Color.fromARGB(
      alpha,
      scale(color.r),
      scale(color.g),
      scale(color.b),
    );
  }
}

/// A convenience bubble widget for text content with configurable styling.
///
/// This composes [TutorialBubble] and [Text] so callers can configure text
/// appearance without building their own child tree.
class TutorialTextBubble extends StatelessWidget implements TutorialBubbleContent {
  const TutorialTextBubble({
    super.key,
    required this.text,
    this.textColor,
    this.fontSize,
    this.fontFamily,
    this.fontWeight,
    this.textStyle,
    this.backgroundColor,
    this.backgroundGradient,
  });

  /// The text content shown inside the bubble.
  final String text;

  /// Optional text color override.
  final Color? textColor;

  /// Optional font size override.
  final double? fontSize;

  /// Optional font family override.
  final String? fontFamily;

  /// Optional font weight override.
  final FontWeight? fontWeight;

  /// Optional complete [TextStyle] override.
  ///
  /// When provided, this style takes precedence over the individual text
  /// properties such as [textColor], [fontSize], [fontFamily], and
  /// [fontWeight].
  final TextStyle? textStyle;

  /// Optional override for the bubble background color.
  final Color? backgroundColor;

  /// Optional override for the bubble background gradient.
  ///
  /// When provided, this takes precedence over [backgroundColor].
  final Gradient? backgroundGradient;

  /// Returns the text-only content used inside a bubble container.
  TutorialTextContent toBubbleContent() {
    return TutorialTextContent(
      text: text,
      textColor: textColor,
      fontSize: fontSize,
      fontFamily: fontFamily,
      fontWeight: fontWeight,
      textStyle: textStyle,
    );
  }

  @override
  Widget buildBubbleContent(BuildContext context) => toBubbleContent();

  @override
  Widget build(BuildContext context) {
    return TutorialBubble(
      backgroundColor: backgroundColor,
      backgroundGradient: backgroundGradient,
      child: toBubbleContent(),
    );
  }
}

/// Text-only bubble content for use inside [TutorialBubbleOverlay].
class TutorialTextContent extends StatelessWidget {
  const TutorialTextContent({
    super.key,
    required this.text,
    this.textColor,
    this.fontSize,
    this.fontFamily,
    this.fontWeight,
    this.textStyle,
  });

  final String text;
  final Color? textColor;
  final double? fontSize;
  final String? fontFamily;
  final FontWeight? fontWeight;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final baseStyle = DefaultTextStyle.of(context)
        .style
        .copyWith(decoration: TextDecoration.none);

    final TextStyle effectiveStyle = textStyle != null
        ? baseStyle.merge(textStyle)
        : baseStyle.copyWith(
            color: textColor,
            fontSize: fontSize,
            fontFamily: fontFamily,
            fontWeight: fontWeight,
          );

    return Text(
      text,
      style: effectiveStyle,
    );
  }
}
