# tutorial_bubbles

Add guided tutorial bubbles and spotlights to Flutter apps.

`tutorial_bubbles` helps you highlight widgets or virtual screen regions, point to them with a bubble, and build onboarding flows without rewriting your UI.

## Why use it

- Highlight keyed widgets or virtual `Rect` targets
- Show a one-off spotlight or a full multi-step tutorial
- Use solid or gradient bubbles
- Add arrow, glow, and target highlight effects
- Support rounded or oval targets
- Continue tutorials across screens
- Save, resume, and mark tutorials complete
- Prepare steps asynchronously before measuring targets
- Override behavior and placement per step

## Installation

```yaml
dependencies:
  tutorial_bubbles: ^0.1.0
```

Then run:

```bash
flutter pub get
```

## Quick start

There are two main ways to use the package:

1. `TutorialBubbleOverlay` for a single spotlight
2. `TutorialEngine` for a multi-step tutorial

## Single spotlight

Use this when you want to highlight one widget and show one bubble.

```dart
import 'package:flutter/material.dart';
import 'package:tutorial_bubbles/tutorial_bubbles.dart';

class SpotlightExample extends StatefulWidget {
  const SpotlightExample({super.key});

  @override
  State<SpotlightExample> createState() => _SpotlightExampleState();
}

class _SpotlightExampleState extends State<SpotlightExample> {
  final GlobalKey _overlayKey = GlobalKey();
  final GlobalKey _targetKey = GlobalKey();
  Rect? _targetRect;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureTarget());
  }

  void _measureTarget() {
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

    final topLeft = targetBox.localToGlobal(Offset.zero, ancestor: overlayBox);
    setState(() {
      _targetRect = topLeft & targetBox.size;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _measureTarget());

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
                    highlightShape: const TutorialHighlightShape.roundedRect(
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                    ),
                    backgroundGradient: const LinearGradient(
                      colors: <Color>[
                        Color(0xFF42A5F5),
                        Color(0xFFAB47BC),
                      ],
                    ),
                    bubbleHaloEnabled: true,
                    targetHaloEnabled: true,
                    child: const TutorialTextContent(
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
```

## Multi-step tutorial

Use this when you want onboarding or guided flows.

```dart
import 'package:flutter/material.dart';
import 'package:tutorial_bubbles/tutorial_bubbles.dart';

class TutorialExample extends StatefulWidget {
  const TutorialExample({super.key});

  @override
  State<TutorialExample> createState() => _TutorialExampleState();
}

class _TutorialExampleState extends State<TutorialExample> {
  final GlobalKey _firstKey = GlobalKey();
  final GlobalKey _secondKey = GlobalKey();

  late final TutorialEngineController _controller = TutorialEngineController(
    steps: [
      TutorialStep(
        target: TutorialTarget.key(_firstKey),
        id: 'first_action',
        bubbleBuilder: (context) => const TutorialTextContent(
          text: 'Tap here first',
          textColor: Colors.white,
        ),
      ),
      TutorialStep(
        target: TutorialTarget.key(_secondKey),
        id: 'second_action',
        preferredSide: TutorialBubbleSide.top,
        beforeShow: (context, controller) async {
          await Scrollable.ensureVisible(_secondKey.currentContext!);
        },
        behavior: const TutorialStepBehavior(
          advanceOnBubbleTap: true,
        ),
        bubbleBuilder: (context) => const TutorialTextContent(
          text: 'Now look at this action',
          textColor: Colors.white,
        ),
        visuals: const TutorialVisuals(
          arrowEnabled: false,
        ),
      ),
    ],
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.start();
    });
  }

  @override
  Widget build(BuildContext context) {
    return TutorialEngine(
      controller: _controller,
      persistence: const TutorialPersistence(id: 'tutorial_example'),
      onComplete: (reason) {
        debugPrint('Tutorial finished: $reason');
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Tutorial demo')),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Center(
              child: ElevatedButton(
                key: _firstKey,
                onPressed: () => _controller.advance(),
                child: const Text('First target'),
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: OutlinedButton(
                key: _secondKey,
                onPressed: () {},
                child: const Text('Second target'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

### Virtual or painted targets

Use `TutorialTarget.rect(...)` when the tutorial should point to a synthetic area instead of a keyed widget.

```dart
TutorialStep(
  id: 'chart_hotspot',
  target: TutorialTarget.rect((context) {
    return const Rect.fromLTWH(120, 220, 160, 72);
  }),
  preferredSide: TutorialBubbleSide.bottom,
  bubbleBuilder: (context) => const TutorialTextContent(
    text: 'This summary band is painted directly on the chart.',
  ),
)
```

## Common customization

### Bubble look

```dart
const TutorialVisuals(
  bubbleCornerRadius: 24,
  bubbleBackgroundGradient: LinearGradient(
    colors: <Color>[Color(0xFF42A5F5), Color(0xFFAB47BC)],
  ),
  bubbleHaloEnabled: true,
)
```

### Arrow

```dart
const TutorialVisuals(
  arrowEnabled: true,
  arrowHeadLength: 10,
  arrowHaloEnabled: true,
)
```

Or directly on the overlay:

```dart
TutorialBubbleOverlay(
  targetRect: targetRect,
  arrowEnabled: true,
  arrowGradient: const LinearGradient(
    colors: <Color>[Color(0xFF42A5F5), Color(0xFFAB47BC)],
  ),
  child: const TutorialTextContent(text: 'Example'),
)
```

### Target highlight shape

```dart
const TutorialHighlightShape.rect()
const TutorialHighlightShape.roundedRect(
  borderRadius: BorderRadius.all(Radius.circular(20)),
)
const TutorialHighlightShape.oval()
```

### Target glow

```dart
const TutorialVisuals(
  targetHaloEnabled: true,
  targetHaloColor: Color(0xB3FFFFFF),
  targetShineEnabled: true,
  targetShineColor: Color(0x80FFFFFF),
)
```

### Global defaults with per-step overrides

```dart
TutorialEngine(
  controller: controller,
  globalVisuals: const TutorialVisuals(
    overlayColor: Color(0xB3000000),
    bubbleBackgroundGradient: LinearGradient(
      colors: <Color>[Color(0xFF42A5F5), Color(0xFFAB47BC)],
    ),
    targetHaloEnabled: true,
    textStyle: TextStyle(
      color: Color(0xFFFFFFFF),
      fontSize: 16,
      fontWeight: FontWeight.w600,
    ),
  ),
  child: child,
)
```

### Step preparation with `beforeShow`

```dart
TutorialStep(
  target: TutorialTarget.key(filterChipKey),
  beforeShow: (context, controller) async {
    await Scrollable.ensureVisible(filterChipKey.currentContext!);
    await Future<void>.delayed(const Duration(milliseconds: 150));
  },
  bubbleBuilder: (context) => const TutorialTextContent(
    text: 'This chip may start offscreen, so we scroll first.',
  ),
)
```

### Per-step interaction policy

```dart
TutorialStep(
  target: TutorialTarget.key(profileButtonKey),
  behavior: TutorialStepBehavior(
    allowTargetTap: false,
    blockOutsideTarget: true,
    onOverlayTap: (context) {
      debugPrint('Overlay tapped');
    },
  ),
  bubbleBuilder: (context) => const TutorialTextContent(
    text: 'Only the bubble should advance this step.',
  ),
)
```

## Main API

### `TutorialBubbleOverlay`

Use for a one-off spotlight.

Most important options:

- `targetRect`
- `child`
- `preferredSide`
- `overlayColor`
- `backgroundColor`
- `backgroundGradient`
- `bubbleCornerRadius`
- `padding`
- `highlightShape`
- `allowTargetTap`
- `targetHaloEnabled`
- `targetShineEnabled`
- `arrowEnabled`
- `arrowColor`
- `arrowGradient`
- `blockOutsideTarget`
- `onTargetTap`
- `onBackgroundTap`

### `TutorialEngine`

Use for multi-step tutorials.

Main options:

- `controller`
- `child`
- `persistence`
- `advanceOnBubbleTap`
- `advanceOnOverlayTap`
- `globalVisuals`
- `persistenceId`
- `checkpointSteps`
- `persistence`
- `onComplete`

### `TutorialEngineController`

Controls tutorial flow.

Main methods:

- `start()`
- `advance()`
- `skip()`
- `goBack()`
- `finish()`
- `jumpTo(index)`

### `TutorialStep`

Defines a single step.

- `target`
- `bubbleBuilder`
- `visuals`
- `beforeShow`
- `preferredSide`
- `behavior`
- `id`

### `TutorialTarget`

Target types:

- `TutorialTarget.key(GlobalKey)`
- `TutorialTarget.rect((context) => Rect)`

### `TutorialStepBehavior`

Behavior fields:

- `advanceOnBubbleTap`
- `advanceOnOverlayTap`
- `allowTargetTap`
- `blockOutsideTarget`
- `onTargetTap`
- `onOverlayTap`

### `TutorialPersistence`

Persistence fields:

- `id`
- `saveStrategy`
- `checkpoints`
- `clearOnComplete`
- `completedKey`

### `TutorialVisuals`

Shared or per-step visual settings.

Common fields:

- `bubbleBackgroundColor`
- `bubbleBackgroundGradient`
- `bubbleCornerRadius`
- `overlayColor`
- `arrowEnabled`
- `arrowColor`
- `arrowGradient`
- `arrowHeadLength`
- `bubbleHaloEnabled`
- `targetHaloEnabled`
- `targetShineEnabled`
- `highlightShape`
- `arrowHaloEnabled`
- `textStyle`

### `TutorialTextContent`

Recommended text widget for overlay and engine usage.

### `TutorialTextBubble`

Convenience text bubble when you want a self-contained bubble widget.

### `TutorialBubble`

Reusable bubble container for custom content.

## Interaction behavior

By default, the spotlight keeps the highlighted target interactive and blocks taps outside it.

You can react to taps like this:

```dart
TutorialBubbleOverlay(
  targetRect: targetRect,
  onTargetTap: () {
    debugPrint('Target tapped');
  },
  onBackgroundTap: () {
    debugPrint('Background tapped');
  },
  child: const TutorialTextContent(text: 'Tap the highlighted control'),
)
```

In engine mode:

- engine-level `advanceOnBubbleTap` and `advanceOnOverlayTap` still work
- per-step behavior overrides are available through `TutorialStep.behavior`

## Persistence

Tutorial progress can be saved automatically.

Save on every step change:

```dart
TutorialEngine(
  controller: controller,
  persistence: const TutorialPersistence(
    id: 'main_onboarding',
  ),
  child: child,
)
```

Save only at selected checkpoints:

```dart
TutorialEngine(
  controller: controller,
  persistence: const TutorialPersistence(
    id: 'main_onboarding',
    saveStrategy: TutorialSaveStrategy.checkpointsOnly,
    checkpoints: {0, 2, 4},
  ),
  child: child,
)
```

Mark a tutorial completed forever while still keeping resume separate from completion:

```dart
TutorialEngine(
  controller: controller,
  persistence: const TutorialPersistence(
    id: 'main_onboarding',
    clearOnComplete: true,
  ),
  child: child,
)
```

## Works across screens

To let the tutorial follow navigation, place `TutorialEngine` above the app's routed content:

```dart
MaterialApp(
  builder: (context, child) {
    return TutorialEngine(
      controller: controller,
      child: child ?? const SizedBox.shrink(),
    );
  },
  home: const FirstScreen(),
)
```

## Tips

- Use `TutorialTextContent` inside overlays and step builders
- Use `TutorialHighlightShape.roundedRect(...)` for rounded buttons and cards
- Use `TutorialBubbleSide.automatic` when you want the package to choose the best side
- Put shared styling in `globalVisuals`, then override only special steps
- Use `beforeShow` for scrolling, navigation settling, and delayed layouts

## Notes

- The package can target widgets by `GlobalKey` or authored `Rect` resolvers
- It works well with buttons, text, icons, cards, and custom widgets
- Some widgets may paint shadows outside their visible bounds; use highlight shape and glow settings to get the cleanest result for your UI

## Example app

The repository includes an example app under `example/`.

Run it with:

```bash
cd example
flutter pub get
flutter run
```

## License

MIT. See [LICENSE](LICENSE).
