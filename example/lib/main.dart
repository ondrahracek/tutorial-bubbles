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
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  late final TutorialKeys _tutorialKeys;
  late final TutorialEngineController _tutorialController;
  late final ExampleTutorialServices _tutorialServices;

  @override
  void initState() {
    super.initState();
    _tutorialKeys = TutorialKeys();
    _tutorialServices = ExampleTutorialServices(
      navigateToDetails: _navigateToDetails,
      ensureHomeVisible: _ensureHomeVisible,
      syntheticSummaryRect: _syntheticSummaryRect,
    );
    _tutorialController = createTutorialController(_tutorialKeys, _tutorialServices);
  }

  Future<void> _navigateToDetails(BuildContext context) async {
    final navigator = _navigatorKey.currentState;
    if (navigator == null) {
      return;
    }
    final currentRoute = ModalRoute.of(_navigatorKey.currentContext ?? context)?.settings.name;
    if (currentRoute != '/tutorial/details') {
      await navigator.pushNamed<void>('/tutorial/details');
    }
  }

  Future<void> _ensureHomeVisible(BuildContext context, GlobalKey key) async {
    final targetContext = key.currentContext;
    if (targetContext == null) {
      return;
    }
    await Scrollable.ensureVisible(
      targetContext,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      alignment: 0.2,
    );
    await Future<void>.delayed(const Duration(milliseconds: 120));
  }

  Rect _syntheticSummaryRect(BuildContext context) {
    final panelContext = _tutorialKeys.syntheticPanel.currentContext;
    final overlayBox = context.findRenderObject() as RenderBox?;
    final panelBox = panelContext?.findRenderObject() as RenderBox?;
    if (panelBox == null || overlayBox == null) {
      return Rect.zero;
    }
    final panelTopLeft =
        panelBox.localToGlobal(Offset.zero, ancestor: overlayBox);
    final bandTop = panelTopLeft.dy + 96;
    return Rect.fromLTWH(panelTopLeft.dx + 24, bandTop, panelBox.size.width - 48, 96);
  }

  Future<void> _resetTutorialPersistence() async {
    await TutorialProgressStorage.clear(tutorialPersistenceId);
    await TutorialProgressStorage.clearCompleted(tutorialCompletedKey);
    _tutorialController.finish();
    _tutorialController.jumpTo(0);
    _scaffoldMessengerKey.currentState?.showSnackBar(
      const SnackBar(content: Text('Feature tour progress reset.')),
    );
  }

  void _startFeatureTour() {
    _tutorialController.start();
    _navigatorKey.currentState?.pushNamed('/tutorial');
  }

  void _onTutorialComplete(TutorialCompletionReason reason) {
    final String message;
    if (reason == TutorialCompletionReason.completed) {
      message = 'Feature tour completed and stored.';
    } else if (reason == TutorialCompletionReason.skipped) {
      message = 'Feature tour skipped.';
    } else {
      message = 'Feature tour finished manually.';
    }
    _scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      scaffoldMessengerKey: _scaffoldMessengerKey,
      title: 'Tutorial Bubbles Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0F766E)),
        useMaterial3: true,
      ),
      builder: (context, child) {
        return TutorialEngine(
          controller: _tutorialController,
          persistence: const TutorialPersistence(
            id: tutorialPersistenceId,
            completedKey: tutorialCompletedKey,
            clearOnComplete: true,
          ),
          globalVisuals: const TutorialVisuals(
            bubbleBackgroundGradient: LinearGradient(
              colors: [Color(0xFF111827), Color(0xFF0F766E)],
            ),
            bubbleCornerRadius: 28,
            overlayColor: Color(0xC414172A),
            targetHaloEnabled: true,
            textStyle: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          onComplete: _onTutorialComplete,
          child: TutorialScope(
            controller: _tutorialController,
            keys: _tutorialKeys,
            services: _tutorialServices,
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
      initialRoute: '/',
      routes: {
        '/': (context) => _HomePage(
              onStandalone: () => Navigator.of(context).pushNamed<void>('/standalone'),
              onFeatureTour: _startFeatureTour,
              onResetPersistence: _resetTutorialPersistence,
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
    required this.onFeatureTour,
    required this.onResetPersistence,
  });

  final VoidCallback onStandalone;
  final VoidCallback onFeatureTour;
  final VoidCallback onResetPersistence;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tutorial Bubbles Example')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Explore standalone overlays, a cross-screen feature tour, and persistence reset controls.',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                FilledButton.icon(
                  onPressed: onStandalone,
                  icon: const Icon(Icons.lightbulb_outline),
                  label: const Text('Standalone spotlight'),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: onFeatureTour,
                  icon: const Icon(Icons.tour_rounded),
                  label: const Text('Feature tour'),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: onResetPersistence,
                  icon: const Icon(Icons.restart_alt_rounded),
                  label: const Text('Reset tutorial persistence'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
