import 'package:flutter/material.dart';
import 'package:tutorial_bubbles/tutorial_bubbles.dart';

class StandaloneDemoPage extends StatefulWidget {
  const StandaloneDemoPage({super.key});

  @override
  State<StandaloneDemoPage> createState() => _StandaloneDemoPageState();
}

class _StandaloneDemoPageState extends State<StandaloneDemoPage> {
  final GlobalKey _targetKey = GlobalKey();
  final GlobalKey _overlayKey = GlobalKey();

  Rect? _targetRect;
  TutorialBubbleSide _preferredSide = TutorialBubbleSide.top;
  bool _ovalShape = false;
  double _cornerRadius = 28;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateTargetRect());
  }

  void _updateTargetRect() {
    final targetContext = _targetKey.currentContext;
    final overlayContext = _overlayKey.currentContext;

    if (targetContext == null || overlayContext == null) {
      return;
    }

    final targetBox = targetContext.findRenderObject() as RenderBox?;
    final overlayBox = overlayContext.findRenderObject() as RenderBox?;

    if (targetBox == null || overlayBox == null) {
      return;
    }

    final topLeft =
        targetBox.localToGlobal(Offset.zero, ancestor: overlayBox);
    setState(() {
      _targetRect = topLeft & targetBox.size;
    });
  }

  @override
  Widget build(BuildContext context) {
    final highlightShape = _ovalShape
        ? const TutorialHighlightShape.oval()
        : TutorialHighlightShape.roundedRect(
            borderRadius: BorderRadius.circular(_cornerRadius),
          );

    return Scaffold(
      appBar: AppBar(title: const Text('Standalone spotlight')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _updateTargetRect());
          return Stack(
            key: _overlayKey,
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'This route demonstrates manual Rect measurement with TutorialBubbleOverlay.',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        DropdownButton<TutorialBubbleSide>(
                          value: _preferredSide,
                          onChanged: (value) {
                            if (value == null) {
                              return;
                            }
                            setState(() {
                              _preferredSide = value;
                            });
                          },
                          items: const [
                            DropdownMenuItem(
                              value: TutorialBubbleSide.top,
                              child: Text('Bubble top'),
                            ),
                            DropdownMenuItem(
                              value: TutorialBubbleSide.bottom,
                              child: Text('Bubble bottom'),
                            ),
                            DropdownMenuItem(
                              value: TutorialBubbleSide.left,
                              child: Text('Bubble left'),
                            ),
                            DropdownMenuItem(
                              value: TutorialBubbleSide.right,
                              child: Text('Bubble right'),
                            ),
                          ],
                        ),
                        FilterChip(
                          label: const Text('Oval cutout'),
                          selected: _ovalShape,
                          onSelected: (value) {
                            setState(() {
                              _ovalShape = value;
                            });
                          },
                        ),
                        SizedBox(
                          width: 220,
                          child: Column(
                            children: [
                              const Text('Bubble roundness'),
                              Slider(
                                value: _cornerRadius,
                                min: 12,
                                max: 40,
                                divisions: 7,
                                label: _cornerRadius.round().toString(),
                                onChanged: (value) {
                                  setState(() {
                                    _cornerRadius = value;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Center(
                      child: FilledButton.icon(
                        key: _targetKey,
                        onPressed: () {},
                        icon: const Icon(Icons.ads_click),
                        label: const Text('Standalone target button'),
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
              ),
              if (_targetRect != null)
                Positioned.fill(
                  child: TutorialBubbleOverlay(
                    targetRect: _targetRect!,
                    preferredSide: _preferredSide,
                    bubbleCornerRadius: _cornerRadius,
                    bubbleHaloEnabled: true,
                    bubbleHaloColor: const Color(0x8038BDF8),
                    targetHaloEnabled: true,
                    targetHaloColor: const Color(0xB3FFFFFF),
                    targetHaloBlurRadius: 22,
                    targetHaloStrokeWidth: 5,
                    targetShineEnabled: true,
                    targetShineColor: const Color(0x80FFFFFF),
                    targetShineBlurRadius: 18,
                    highlightShape: highlightShape,
                    backgroundGradient: const LinearGradient(
                      colors: <Color>[
                        Color(0xFF0F766E),
                        Color(0xFF1D4ED8),
                      ],
                    ),
                    child: const TutorialTextContent(
                      text: 'Manual overlay mode gives you complete control over the measured rect.',
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
