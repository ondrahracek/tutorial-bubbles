import 'package:flutter/material.dart';
import 'package:tutorial_bubbles/tutorial_bubbles.dart';

void main() {
  runApp(const TutorialBubblesExampleApp());
}

class TutorialBubblesExampleApp extends StatelessWidget {
  const TutorialBubblesExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Tutorial Bubbles Example',
      home: _TutorialBubbleDemoPage(),
    );
  }
}

class _TutorialBubbleDemoPage extends StatefulWidget {
  const _TutorialBubbleDemoPage();

  @override
  State<_TutorialBubbleDemoPage> createState() =>
      _TutorialBubbleDemoPageState();
}

class _TutorialBubbleDemoPageState extends State<_TutorialBubbleDemoPage> {
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
    final size = targetBox.size;

    setState(() {
      _targetRect = topLeft & size;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tutorial Bubbles Example'),
      ),
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
                    child: const Text('Tap this button to get started'),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

