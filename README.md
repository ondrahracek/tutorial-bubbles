# tutorial_bubbles

Add guided tutorial bubbles and spotlights to Flutter apps.

`tutorial_bubbles` helps you highlight any widget, point to it with a bubble, and build onboarding flows without rewriting your UI.

## Why use it

- Highlight any widget with a `GlobalKey`
- Show a one-off spotlight or a full multi-step tutorial
- Use solid or gradient bubbles
- Add arrow, glow, and target highlight effects
- Support rounded or oval targets
- Continue tutorials across screens
- Save and resume progress

## Installation

```yaml
dependencies:
  tutorial_bubbles: ^0.0.1
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
        targetKey: _firstKey,
        bubbleBuilder: (context) => const TutorialTextContent(
          text: 'Tap here first',
          textColor: Colors.white,
        ),
      ),
      TutorialStep(
        targetKey: _secondKey,
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
      advanceOnBubbleTap: true,
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

## Common customization

### Bubble look

```dart
const TutorialVisuals(
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
- `padding`
- `highlightShape`
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
- `advanceOnBubbleTap`
- `advanceOnOverlayTap`
- `globalVisuals`
- `persistenceId`
- `checkpointSteps`
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

- `targetKey`
- `bubbleBuilder`
- `visuals`

### `TutorialVisuals`

Shared or per-step visual settings.

Common fields:

- `bubbleBackgroundColor`
- `bubbleBackgroundGradient`
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

- `advanceOnBubbleTap: true` advances when the bubble is tapped
- `advanceOnOverlayTap: true` advances when the dimmed background is tapped

## Persistence

Tutorial progress can be saved automatically.

Save on every step change:

```dart
TutorialEngine(
  controller: controller,
  persistenceId: 'main_onboarding',
  child: child,
)
```

Save only at selected checkpoints:

```dart
TutorialEngine(
  controller: controller,
  persistenceId: 'main_onboarding',
  checkpointSteps: {0, 2, 4},
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

## Notes

- The package targets widgets by layout using `GlobalKey`
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
