import 'package:flutter/material.dart';
import 'package:tutorial_bubbles/tutorial_bubbles.dart';

/// Keys for tutorial steps. Created once and shared across routes.
class TutorialKeys {
  TutorialKeys()
      : step0 = GlobalKey(),
        step1 = GlobalKey(),
        step2 = GlobalKey(),
        step3 = GlobalKey(),
        step4 = GlobalKey(),
        step5 = GlobalKey();

  final GlobalKey step0;
  final GlobalKey step1;
  final GlobalKey step2;
  final GlobalKey step3;
  final GlobalKey step4;
  final GlobalKey step5;
}

/// Creates the tutorial controller with steps spanning home and details screens.
TutorialEngineController createTutorialController(TutorialKeys keys) {
  return TutorialEngineController(
    steps: [
      TutorialStep(
        targetKey: keys.step0,
        bubbleBuilder: (context) => const TutorialTextBubble(
          text: 'Tap here to start the tutorial flow',
          textColor: Colors.white,
          fontSize: 16,
        ),
      ),
      TutorialStep(
        targetKey: keys.step1,
        bubbleBuilder: (context) => const TutorialTextBubble(
          text: 'This uses a solid color (global default)',
          textColor: Colors.white,
          fontSize: 16,
        ),
      ),
      TutorialStep(
        targetKey: keys.step2,
        bubbleBuilder: (context) => const TutorialTextBubble(
          text: 'Tap to go to the next screen — the tutorial follows',
          textColor: Colors.white,
          fontSize: 16,
        ),
        visuals: const TutorialVisuals(
          bubbleBackgroundGradient: LinearGradient(
            colors: [Color(0xFF42A5F5), Color(0xFFAB47BC)],
          ),
          bubbleHaloEnabled: true,
        ),
      ),
      TutorialStep(
        targetKey: keys.step3,
        bubbleBuilder: (context) => const TutorialTextBubble(
          text: 'You navigated! The overlay spans multiple screens',
          textColor: Colors.white,
          fontSize: 16,
        ),
        visuals: const TutorialVisuals(
          bubbleBackgroundColor: Color(0xFF2E7D32),
          targetHaloEnabled: true,
        ),
      ),
      TutorialStep(
        targetKey: keys.step4,
        bubbleBuilder: (context) => const TutorialTextBubble(
          text: 'Per-step override: arrow disabled for this step',
          textColor: Colors.white,
          fontSize: 16,
        ),
        visuals: const TutorialVisuals(
          arrowEnabled: false,
          bubbleBackgroundColor: Color(0xFF6A1B9A),
        ),
      ),
      TutorialStep(
        targetKey: keys.step5,
        bubbleBuilder: (context) => const TutorialTextBubble(
          text: 'Final step! Tap target or use Skip/Finish below',
          textColor: Colors.white,
          fontSize: 16,
        ),
      ),
    ],
  );
}

/// Home screen for the full tutorial flow. Steps 0–2 target widgets here.
class TutorialFlowHomePage extends StatelessWidget {
  const TutorialFlowHomePage({super.key});

  void _onGoToDetails(BuildContext context, TutorialEngineController controller) {
    Navigator.of(context).pushNamed<void>('/tutorial/details');
    controller.advance();
  }

  @override
  Widget build(BuildContext context) {
    final scope = TutorialScope.of(context);
    final controller = scope.controller;
    final keys = scope.keys;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Full Tutorial'),
        actions: const [TutorialControlBar()],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              key: keys.step0,
              onPressed: () => controller.advance(),
              child: const Text('Start tutorial'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              key: keys.step1,
              onPressed: () => controller.advance(),
              child: const Text('Settings'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              key: keys.step2,
              onPressed: () => _onGoToDetails(context, controller),
              child: const Text('Go to details'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Details screen. Steps 3–5 target widgets here.
class TutorialFlowDetailsPage extends StatelessWidget {
  const TutorialFlowDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final keys = TutorialScope.of(context).keys;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Details'),
        actions: const [TutorialControlBar()],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              key: keys.step3,
              height: 48,
              child: const Center(child: Text('Step 3 target')),
            ),
            const SizedBox(height: 24),
            Container(
              key: keys.step4,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('Step 4 target'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              key: keys.step5,
              onPressed: () => TutorialScope.of(context).controller.advance(),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Control bar for Skip, Back, Finish. Uses controller from [TutorialScope].
class TutorialControlBar extends StatelessWidget {
  const TutorialControlBar({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = TutorialScope.of(context).controller;
    return ValueListenableBuilder<bool>(
      valueListenable: controller.isFinishedListenable,
      builder: (context, isFinished, _) {
        if (isFinished) return const SizedBox.shrink();
        return ValueListenableBuilder<int>(
          valueListenable: controller.currentIndexListenable,
          builder: (context, index, _) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${index + 1}/${controller.totalSteps}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: index > 0 ? controller.goBack : null,
                    child: const Text('Back'),
                  ),
                  TextButton(
                    onPressed: controller.skip,
                    child: const Text('Skip'),
                  ),
                  TextButton(
                    onPressed: controller.finish,
                    child: const Text('Finish'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

/// InheritedWidget to provide the tutorial controller and keys.
class TutorialScope extends InheritedWidget {
  const TutorialScope({
    super.key,
    required this.controller,
    required this.keys,
    required super.child,
  });

  final TutorialEngineController controller;
  final TutorialKeys keys;

  static TutorialScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<TutorialScope>();
    assert(scope != null);
    return scope!;
  }

  @override
  bool updateShouldNotify(TutorialScope old) =>
      controller != old.controller || keys != old.keys;
}
