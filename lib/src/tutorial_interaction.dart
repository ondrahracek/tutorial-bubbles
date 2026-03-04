// Interaction blocking widgets for tutorial overlays.

import 'package:flutter/widgets.dart';

/// Widget that blocks interactions outside the highlighted target region.
///
/// Creates absorbing regions around the target rectangle to prevent taps
/// from reaching the underlying content, while optionally allowing taps
/// on the target itself or on the background area.
class TutorialInteractionBlocker extends StatelessWidget {
  const TutorialInteractionBlocker({
    super.key,
    required this.targetRect,
    required this.enabled,
    this.onTargetTap,
    this.onOutsideTap,
  });

  final Rect targetRect;
  final bool enabled;
  final VoidCallback? onTargetTap;
  final VoidCallback? onOutsideTap;

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final Size size = constraints.biggest;
        if (size.isEmpty) {
          return const SizedBox.shrink();
        }

        final double left = targetRect.left.clamp(0.0, size.width);
        final double right = targetRect.right.clamp(0.0, size.width);
        final double top = targetRect.top.clamp(0.0, size.height);
        final double bottom = targetRect.bottom.clamp(0.0, size.height);

        final Rect clamped = Rect.fromLTRB(left, top, right, bottom);

        if (clamped.isEmpty) {
          return _AbsorbingRegion(onTap: onOutsideTap);
        }

        return Stack(
          children: [
            Positioned(
              left: 0,
              top: 0,
              right: 0,
              height: clamped.top,
              child: _AbsorbingRegion(onTap: onOutsideTap),
            ),
            Positioned(
              left: 0,
              top: clamped.bottom,
              right: 0,
              bottom: 0,
              child: _AbsorbingRegion(onTap: onOutsideTap),
            ),
            Positioned(
              left: 0,
              top: clamped.top,
              width: clamped.left,
              height: clamped.height,
              child: _AbsorbingRegion(onTap: onOutsideTap),
            ),
            Positioned(
              left: clamped.right,
              top: clamped.top,
              right: 0,
              height: clamped.height,
              child: _AbsorbingRegion(onTap: onOutsideTap),
            ),
            if (onTargetTap != null)
              Positioned(
                left: clamped.left,
                top: clamped.top,
                width: clamped.width,
                height: clamped.height,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onTargetTap,
                  child: const SizedBox.expand(),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// A region that absorbs pointer events or invokes a callback on tap.
///
/// When [onTap] is null, this widget absorbs all pointer events without
/// propagating them. When [onTap] is provided, it forwards taps to the
/// callback while still blocking propagation to underlying widgets.
class _AbsorbingRegion extends StatelessWidget {
  const _AbsorbingRegion({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    if (onTap == null) {
      return const AbsorbPointer(
        child: SizedBox.expand(
          child: ColoredBox(
            color: Color(0x00000000),
          ),
        ),
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: const SizedBox.expand(
        child: ColoredBox(
          color: Color(0x00000000),
        ),
      ),
    );
  }
}
