import 'package:flutter/material.dart';
import 'package:tutorial_bubbles/tutorial_bubbles.dart';

class RectTargetHost extends StatefulWidget {
  const RectTargetHost({super.key});

  @override
  State<RectTargetHost> createState() => RectTargetHostState();
}

class RectTargetHostState extends State<RectTargetHost> {
  late Rect targetRect = const Rect.fromLTWH(32, 48, 96, 40);

  late final TutorialEngineController controller = TutorialEngineController(
    steps: [
      TutorialStep(
        target: TutorialTarget.rect((context) => targetRect),
        bubbleBuilder: (context) =>
            const TutorialTextBubble(text: 'Rect target'),
      ),
    ],
  );

  void updateTargetRect(Rect rect) {
    setState(() {
      targetRect = rect;
    });
  }

  @override
  Widget build(BuildContext context) {
    return TutorialEngine(
      controller: controller,
      child: const SizedBox.expand(),
    );
  }
}

class BeforeShowHost extends StatefulWidget {
  const BeforeShowHost({
    super.key,
    required this.controller,
    required this.targetKey,
  });

  final TutorialEngineController controller;
  final GlobalKey targetKey;

  @override
  State<BeforeShowHost> createState() => BeforeShowHostState();
}

class BeforeShowHostState extends State<BeforeShowHost> {
  bool _showTarget = false;

  void showTarget() {
    if (!mounted) {
      return;
    }
    setState(() {
      _showTarget = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return TutorialEngine(
      controller: widget.controller,
      child: Center(
        child: _showTarget
            ? SizedBox(
                key: widget.targetKey,
                width: 80,
                height: 40,
                child: const ColoredBox(color: Colors.blue),
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}
