import 'package:flutter/material.dart';
import 'package:tutorial_bubbles/tutorial_bubbles.dart';

const String tutorialPersistenceId = 'example_feature_tour';
const String tutorialCompletedKey = 'example_feature_tour_completed';

class TutorialKeys {
  TutorialKeys()
      : welcomeButton = GlobalKey(),
        insightsCard = GlobalKey(),
        scrollChip = GlobalKey(),
        placementCard = GlobalKey(),
        openDetailsButton = GlobalKey(),
        detailsHeader = GlobalKey(),
        blockedTarget = GlobalKey(),
        finishButton = GlobalKey(),
        homeScrollView = GlobalKey(),
        syntheticPanel = GlobalKey();

  final GlobalKey welcomeButton;
  final GlobalKey insightsCard;
  final GlobalKey scrollChip;
  final GlobalKey placementCard;
  final GlobalKey openDetailsButton;
  final GlobalKey detailsHeader;
  final GlobalKey blockedTarget;
  final GlobalKey finishButton;
  final GlobalKey homeScrollView;
  final GlobalKey syntheticPanel;
}

class ExampleTutorialServices {
  const ExampleTutorialServices({
    required this.navigateToDetails,
    required this.ensureHomeVisible,
    required this.syntheticSummaryRect,
  });

  final Future<void> Function(BuildContext context) navigateToDetails;
  final Future<void> Function(BuildContext context, GlobalKey key) ensureHomeVisible;
  final Rect Function(BuildContext context) syntheticSummaryRect;
}

TutorialEngineController createTutorialController(
  TutorialKeys keys,
  ExampleTutorialServices services,
) {
  return TutorialEngineController(
    steps: [
      TutorialStep(
        id: 'welcome_button',
        target: TutorialTarget.key(keys.welcomeButton),
        behavior: const TutorialStepBehavior(advanceOnBubbleTap: true),
        bubbleBuilder: (context) => const TutorialTextContent(
          text: 'Start here. This first step uses a keyed widget target.',
          textColor: Colors.white,
          fontSize: 16,
        ),
      ),
      TutorialStep(
        id: 'insight_card',
        target: TutorialTarget.key(keys.insightsCard),
        preferredSide: TutorialBubbleSide.right,
        behavior: const TutorialStepBehavior(advanceOnBubbleTap: true),
        bubbleBuilder: (context) => const TutorialTextContent(
          text: 'This card forces a right-side bubble for authored placement.',
          textColor: Colors.white,
        ),
        visuals: const TutorialVisuals(
          bubbleBackgroundGradient: LinearGradient(
            colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
          ),
          bubbleCornerRadius: 28,
          bubbleHaloEnabled: true,
        ),
      ),
      TutorialStep(
        id: 'scroll_to_chip',
        target: TutorialTarget.key(keys.scrollChip),
        beforeShow: (context, controller) async {
          await services.ensureHomeVisible(context, keys.scrollChip);
        },
        behavior: const TutorialStepBehavior(advanceOnBubbleTap: true),
        bubbleBuilder: (context) => const TutorialTextContent(
          text: 'This step scrolls into view with beforeShow before measuring.',
          textColor: Colors.white,
        ),
      ),
      TutorialStep(
        id: 'synthetic_summary_band',
        target: TutorialTarget.rect(services.syntheticSummaryRect),
        preferredSide: TutorialBubbleSide.top,
        beforeShow: (context, controller) async {
          await services.ensureHomeVisible(context, keys.syntheticPanel);
        },
        behavior: const TutorialStepBehavior(advanceOnBubbleTap: true),
        bubbleBuilder: (context) => const TutorialTextContent(
          text: 'This highlight uses TutorialTarget.rect for a painted summary band.',
          textColor: Colors.white,
        ),
        visuals: const TutorialVisuals(
          targetHaloEnabled: true,
          bubbleCornerRadius: 30,
        ),
      ),
      TutorialStep(
        id: 'open_details',
        target: TutorialTarget.key(keys.openDetailsButton),
        beforeShow: (context, controller) async {
          await services.ensureHomeVisible(context, keys.openDetailsButton);
        },
        behavior: TutorialStepBehavior(
          advanceOnBubbleTap: false,
          allowTargetTap: true,
          onTargetTap: (context) async {
            await services.navigateToDetails(context);
          },
        ),
        bubbleBuilder: (context) => const TutorialTextContent(
          text: 'Tap the highlighted button. The tutorial follows the route change.',
          textColor: Colors.white,
        ),
      ),
      TutorialStep(
        id: 'details_header',
        target: TutorialTarget.key(keys.detailsHeader),
        beforeShow: (context, controller) async {
          await Future<void>.delayed(const Duration(milliseconds: 180));
        },
        behavior: const TutorialStepBehavior(advanceOnBubbleTap: true),
        bubbleBuilder: (context) => const TutorialTextContent(
          text: 'We are now on the details screen. beforeShow waits for the transition to settle.',
          textColor: Colors.white,
        ),
        visuals: const TutorialVisuals(
          bubbleBackgroundColor: Color(0xFF1D4ED8),
          targetHaloEnabled: true,
        ),
      ),
      TutorialStep(
        id: 'blocked_target',
        target: TutorialTarget.key(keys.blockedTarget),
        behavior: TutorialStepBehavior(
          allowTargetTap: false,
          blockOutsideTarget: false,
          advanceOnOverlayTap: true,
          onOverlayTap: (context) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Overlay tap handled for this step.'),
              ),
            );
          },
        ),
        bubbleBuilder: (context) => const TutorialTextContent(
          text: 'This target is intentionally blocked. Outside controls still work.',
          textColor: Colors.white,
        ),
        visuals: const TutorialVisuals(
          bubbleBackgroundColor: Color(0xFF7C2D12),
          bubbleCornerRadius: 32,
        ),
      ),
      TutorialStep(
        id: 'details_finish',
        target: TutorialTarget.key(keys.finishButton),
        behavior: const TutorialStepBehavior(advanceOnBubbleTap: true),
        bubbleBuilder: (context) => const TutorialTextContent(
          text: 'Finish the tour here. Completion is saved separately from resume progress.',
          textColor: Colors.white,
        ),
      ),
    ],
  );
}

class TutorialFlowHomePage extends StatelessWidget {
  const TutorialFlowHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = TutorialScope.of(context);
    final controller = scope.controller;
    final keys = scope.keys;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Feature Tour'),
        actions: const [TutorialControlBar()],
      ),
      body: CustomScrollView(
        key: keys.homeScrollView,
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    runSpacing: 16,
                    spacing: 16,
                    children: [
                      FilledButton.icon(
                        key: keys.welcomeButton,
                        onPressed: controller.advance,
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: const Text('Welcome button'),
                      ),
                      OutlinedButton.icon(
                        key: keys.openDetailsButton,
                        onPressed: () => scope.services.navigateToDetails(context),
                        icon: const Icon(Icons.open_in_new),
                        label: const Text('Open details'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _DemoMetricCard(
                          key: keys.insightsCard,
                          title: 'Placement demo',
                          subtitle: 'Forced right-side bubble placement',
                          value: '+18%',
                          color: const Color(0xFFDCFCE7),
                          onTap: controller.advance,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: _DemoMetricCard(
                          title: 'Ambient controls',
                          subtitle: 'Background interaction step later',
                          value: 'Live',
                          color: Color(0xFFE0F2FE),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _SyntheticSummaryPanel(
                    key: keys.syntheticPanel,
                    onTap: controller.advance,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Scroll down to find the deferred chip target.',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 600),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: ActionChip(
                      key: keys.scrollChip,
                      avatar: const Icon(Icons.tune, size: 18),
                      label: const Text('Filter chip target'),
                      onPressed: controller.advance,
                    ),
                  ),
                  const SizedBox(height: 600),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TutorialFlowDetailsPage extends StatefulWidget {
  const TutorialFlowDetailsPage({super.key});

  @override
  State<TutorialFlowDetailsPage> createState() => _TutorialFlowDetailsPageState();
}

class _TutorialFlowDetailsPageState extends State<TutorialFlowDetailsPage> {
  int _backgroundTapCount = 0;
  int _blockedTapCount = 0;

  @override
  Widget build(BuildContext context) {
    final scope = TutorialScope.of(context);
    final controller = scope.controller;
    final keys = scope.keys;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Details showcase'),
        actions: const [TutorialControlBar()],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              key: keys.detailsHeader,
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFDBEAFE),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Text(
                'Details header target',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.tonal(
              onPressed: () {
                setState(() {
                  _backgroundTapCount += 1;
                });
              },
              child: Text('Background control taps: $_backgroundTapCount'),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              key: keys.blockedTarget,
              onPressed: () {
                setState(() {
                  _blockedTapCount += 1;
                });
              },
              icon: const Icon(Icons.lock_outline),
              label: Text('Blocked target taps: $_blockedTapCount'),
            ),
            const SizedBox(height: 16),
            Text(
              'During the blocked-target step, this button should not increment while the background control still can.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const Spacer(),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                key: keys.finishButton,
                onPressed: controller.advance,
                icon: const Icon(Icons.flag_rounded),
                label: const Text('Finish feature tour'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TutorialControlBar extends StatelessWidget {
  const TutorialControlBar({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = TutorialScope.of(context).controller;
    return ValueListenableBuilder<bool>(
      valueListenable: controller.isFinishedListenable,
      builder: (context, isFinished, _) {
        if (isFinished) {
          return const SizedBox.shrink();
        }
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

class TutorialScope extends InheritedWidget {
  const TutorialScope({
    super.key,
    required this.controller,
    required this.keys,
    required this.services,
    required super.child,
  });

  final TutorialEngineController controller;
  final TutorialKeys keys;
  final ExampleTutorialServices services;

  static TutorialScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<TutorialScope>();
    assert(scope != null);
    return scope!;
  }

  @override
  bool updateShouldNotify(TutorialScope old) {
    return controller != old.controller ||
        keys != old.keys ||
        services != old.services;
  }
}

class _DemoMetricCard extends StatelessWidget {
  const _DemoMetricCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.color,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final String value;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 16),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SyntheticSummaryPanel extends StatelessWidget {
  const _SyntheticSummaryPanel({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(28),
      child: Ink(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF172554), Color(0xFF0F766E)],
          ),
          borderRadius: BorderRadius.circular(28),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(28),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Synthetic target panel',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'The highlighted summary band is resolved by rect, not by targeting a child widget directly.',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: 20),
                Container(
                  height: 96,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'Painted summary band',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
