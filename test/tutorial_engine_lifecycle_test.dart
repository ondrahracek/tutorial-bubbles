import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tutorial_bubbles/tutorial_bubbles.dart';

void main() {
  group('TutorialEngine lifecycle', () {
    testWidgets('does not show overlay before controller.start is called', (tester) async {
      final targetKey = GlobalKey();
      final controller = TutorialEngineController(
        steps: [
          TutorialStep(
            targetKey: targetKey,
            bubbleBuilder: (context) => const Text('Step 1'),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: TutorialEngine(
            controller: controller,
            child: Center(
              child: ElevatedButton(
                key: targetKey,
                onPressed: () {},
                child: const Text('Target'),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(controller.isStarted, isFalse);
      expect(find.byType(TutorialBubbleOverlay), findsNothing);
      expect(find.text('Step 1'), findsNothing);
    });

    testWidgets('shows overlay after controller.start is called', (tester) async {
      final targetKey = GlobalKey();
      final controller = TutorialEngineController(
        steps: [
          TutorialStep(
            targetKey: targetKey,
            bubbleBuilder: (context) => const Text('Step 1'),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: TutorialEngine(
            controller: controller,
            child: Center(
              child: ElevatedButton(
                key: targetKey,
                onPressed: () {},
                child: const Text('Target'),
              ),
            ),
          ),
        ),
      );

      controller.start();
      await tester.pumpAndSettle();

      expect(find.byType(TutorialBubbleOverlay), findsOneWidget);
      expect(find.text('Step 1'), findsOneWidget);
    });

    testWidgets('replacing the controller detaches old listeners and follows the new controller',
        (tester) async {
      final firstKey = GlobalKey();
      final secondKey = GlobalKey();
      final firstController = TutorialEngineController(
        steps: [
          TutorialStep(
            targetKey: firstKey,
            bubbleBuilder: (context) => const Text('Old controller step'),
          ),
        ],
      );
      final secondController = TutorialEngineController(
        steps: [
          TutorialStep(
            targetKey: secondKey,
            bubbleBuilder: (context) => const Text('New controller step'),
          ),
        ],
      );

      final hostKey = GlobalKey<_ControllerSwapHostState>();

      await tester.pumpWidget(
        MaterialApp(
          home: ControllerSwapHost(
            key: hostKey,
            controller: firstController,
            firstKey: firstKey,
            secondKey: secondKey,
          ),
        ),
      );

      firstController.start();
      await tester.pumpAndSettle();
      expect(find.text('Old controller step'), findsOneWidget);

      hostKey.currentState!.replaceController(secondController);
      secondController.start();
      await tester.pumpAndSettle();

      expect(find.text('Old controller step'), findsNothing);
      expect(find.text('New controller step'), findsOneWidget);

      firstController.finish();
      await tester.pumpAndSettle();
      expect(find.text('New controller step'), findsOneWidget);
    });

    testWidgets('persisted progress is clamped to the last valid step index', (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'tutorial_bubbles_progress_clamped-engine': 99,
      });

      final targetKey = GlobalKey();
      final controller = TutorialEngineController(
        steps: [
          TutorialStep(
            targetKey: targetKey,
            bubbleBuilder: (context) => const Text('Step 1'),
          ),
          TutorialStep(
            targetKey: targetKey,
            bubbleBuilder: (context) => const Text('Step 2'),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: TutorialEngine(
            controller: controller,
            persistenceId: 'clamped-engine',
            child: Center(
              child: ElevatedButton(
                key: targetKey,
                onPressed: () {},
                child: const Text('Target'),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(controller.currentIndex, 1);
    });
  });
}

class ControllerSwapHost extends StatefulWidget {
  const ControllerSwapHost({
    super.key,
    required this.controller,
    required this.firstKey,
    required this.secondKey,
  });

  final TutorialEngineController controller;
  final GlobalKey firstKey;
  final GlobalKey secondKey;

  @override
  State<ControllerSwapHost> createState() => _ControllerSwapHostState();
}

class _ControllerSwapHostState extends State<ControllerSwapHost> {
  late TutorialEngineController _controller = widget.controller;

  void replaceController(TutorialEngineController controller) {
    setState(() {
      _controller = controller;
    });
  }

  @override
  Widget build(BuildContext context) {
    return TutorialEngine(
      controller: _controller,
      child: Column(
        children: [
          ElevatedButton(
            key: widget.firstKey,
            onPressed: () {},
            child: const Text('First target'),
          ),
          ElevatedButton(
            key: widget.secondKey,
            onPressed: () {},
            child: const Text('Second target'),
          ),
        ],
      ),
    );
  }
}
