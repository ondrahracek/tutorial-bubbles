import 'package:flutter/material.dart';
import 'package:tutorial_bubbles/tutorial_bubbles.dart';

import 'standalone_demo.dart';
import 'tutorial_demo.dart';

void main() {
  runApp(const TutorialBubblesExampleApp());
}

class TutorialBubblesExampleApp extends StatefulWidget {
  const TutorialBubblesExampleApp({super.key});

  @override
  State<TutorialBubblesExampleApp> createState() =>
      _TutorialBubblesExampleAppState();
}

class _TutorialBubblesExampleAppState extends State<TutorialBubblesExampleApp> {
  final GlobalKey<ScaffoldMessengerState> _scaffoldKey =
      GlobalKey<ScaffoldMessengerState>();
  late final TutorialKeys _tutorialKeys;
  late final TutorialEngineController _tutorialController;

  @override
  void initState() {
    super.initState();
    _tutorialKeys = TutorialKeys();
    _tutorialController = createTutorialController(_tutorialKeys);
  }

  void _onTutorialComplete(TutorialCompletionReason reason) {
    final message = reason == TutorialCompletionReason.completed
        ? 'Tutorial completed!'
        : reason == TutorialCompletionReason.skipped
            ? 'Tutorial skipped'
            : 'Tutorial finished';
    _scaffoldKey.currentState?.showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scaffoldMessengerKey: _scaffoldKey,
      title: 'Tutorial Bubbles Example',
      builder: (context, child) {
        return TutorialEngine(
          controller: _tutorialController,
          advanceOnBubbleTap: true,
          advanceOnOverlayTap: true,
          persistenceId: 'example_onboarding',
          checkpointSteps: const {2, 4},
          globalVisuals: const TutorialVisuals(
            bubbleBackgroundColor: Color(0xFF303030),
            overlayColor: Color(0xB3000000),
          ),
          onComplete: _onTutorialComplete,
          child: TutorialScope(
            controller: _tutorialController,
            keys: _tutorialKeys,
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
      initialRoute: '/',
      routes: {
        '/': (context) => _HomePage(
              onStandalone: () =>
                  Navigator.of(context).pushNamed<void>('/standalone'),
              onFullTutorial: () {
                _tutorialController.start();
                Navigator.of(context).pushNamed<void>('/tutorial');
              },
            ),
        '/standalone': (context) => const StandaloneDemoPage(),
        '/tutorial': (context) => const TutorialFlowHomePage(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/tutorial/details') {
          return MaterialPageRoute<void>(
            builder: (context) => const TutorialFlowDetailsPage(),
            settings: settings,
          );
        }
        return null;
      },
    );
  }
}

class _HomePage extends StatelessWidget {
  const _HomePage({
    required this.onStandalone,
    required this.onFullTutorial,
  });

  final VoidCallback onStandalone;
  final VoidCallback onFullTutorial;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tutorial Bubbles Example')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: onStandalone,
              icon: const Icon(Icons.lightbulb_outline),
              label: const Text('Standalone spotlight'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onFullTutorial,
              icon: const Icon(Icons.school),
              label: const Text('Full tutorial'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

