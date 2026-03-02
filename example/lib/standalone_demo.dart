import 'package:flutter/material.dart';
import 'package:tutorial_bubbles/tutorial_bubbles.dart';

/// Standalone spotlight demo: single bubble pointing at a target,
/// no TutorialEngine or controller.
class StandaloneDemoPage extends StatefulWidget {
  const StandaloneDemoPage({super.key});

  @override
  State<StandaloneDemoPage> createState() => _StandaloneDemoPageState();
}

class _StandaloneDemoPageState extends State<StandaloneDemoPage> {
  final GlobalKey _targetKey = GlobalKey();
  final GlobalKey _overlayKey = GlobalKey();

  Rect? _targetRect;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateTargetRect());
  }

  void _updateTargetRect() {
    final targetContext = _targetKey.currentContext;
    final overlayContext = _overlayKey.currentContext;

    if (targetContext == null || overlayContext == null) return;

    final targetBox = targetContext.findRenderObject() as RenderBox?;
    final overlayBox = overlayContext.findRenderObject() as RenderBox?;

    if (targetBox == null || overlayBox == null) return;

    final topLeft =
        targetBox.localToGlobal(Offset.zero, ancestor: overlayBox);
    final size = targetBox.size;

    setState(() => _targetRect = topLeft & size);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Standalone Spotlight')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            key: _overlayKey,
            children: [
              Center(
                child: ElevatedButton(
                  key: _targetKey,
                  onPressed: () {},
                  child: const Text('Target button'),
                ),
              ),
              if (_targetRect != null)
                Positioned.fill(
                  child: TutorialBubbleOverlay(
                    targetRect: _targetRect!,
                    preferredSide: TutorialBubbleSide.top,
                    bubbleHaloEnabled: true,
                    bubbleHaloColor: const Color(0x8042A5F5),
                    backgroundGradient: const LinearGradient(
                      colors: <Color>[
                        Color(0xFF42A5F5),
                        Color(0xFFAB47BC),
                      ],
                    ),
                    child: const TutorialTextBubble(
                      text: 'Tap this button to get started',
                      textColor: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
