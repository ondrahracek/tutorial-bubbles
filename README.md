# tutorial_bubbles

A Flutter package for guided tutorial bubbles that highlight widgets in your app. Supports both a standalone spotlight and a multi-step tutorial engine with persistence.

## Features

- **Standalone spotlight** — Show a single bubble pointing at any widget without an engine
- **Multi-step tutorial engine** — Define ordered steps, advance/skip/finish/goBack programmatically
- **Configurable visuals** — Solid or gradient bubble, halo effects, arrow between bubble and target, dimmed overlay
- **Flexible positioning** — Bubble placement on top/bottom/left/right or automatic (most space)
- **Cross-screen flow** — Steps can target widgets on different routes; overlay sits above Navigator
- **Progress persistence** — Save and resume tutorial progress across app restarts (SharedPreferences)
- **Non-invasive** — Target any Flutter widget with a `GlobalKey`; no changes to the widget itself

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  tutorial_bubbles: ^0.0.1
```

Then run `flutter pub get`.

## Usage

### Standalone spotlight

Wrap your content in a `Stack` and overlay `TutorialBubbleOverlay` when you have a target rect:

```dart
final targetKey = GlobalKey();

Stack(
  children: [
    Center(
      child: ElevatedButton(
        key: targetKey,
        onPressed: () {},
        child: const Text('Target'),
      ),
    ),
    if (targetRect != null)
      Positioned.fill(
        child: TutorialBubbleOverlay(
          targetRect: targetRect!,
          preferredSide: TutorialBubbleSide.top,
          highlightShape: const TutorialHighlightShape.roundedRect(
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
          child: const TutorialTextContent(
            text: 'Tap this button to get started',
            textColor: Colors.white,
          ),
        ),
      ),
  ],
)
```

Measure the target rect with `RenderBox.localToGlobal` in a `postFrameCallback`. See the `example/` app for the full pattern.

### Multi-step tutorial engine

Define steps, wrap your app with `TutorialEngine`, and control flow with `TutorialEngineController`:

```dart
final step1Key = GlobalKey();
final controller = TutorialEngineController(
  steps: [
    TutorialStep(
      targetKey: step1Key,
      bubbleBuilder: (context) => const TutorialTextContent(text: 'First step'),
    ),
    // Add more steps...
  ],
);

MaterialApp(
  builder: (context, child) => TutorialEngine(
    controller: controller,
    advanceOnBubbleTap: true,
    persistenceId: 'onboarding',
    onComplete: (reason) => debugPrint('Tutorial ended: $reason'),
    child: child ?? const SizedBox.shrink(),
  ),
  home: MyHomePage(step1Key: step1Key),
);

// Start when ready
controller.start();
```

- **`advance()`** — Move to next step (or finish on last step)
- **`skip()`** — Skip current step
- **`finish()`** — End tutorial early
- **`goBack()`** — Return to previous step
- **`persistenceId`** — Saves progress across restarts
- **`checkpointSteps`** — Save only at specific step indices

## Example app

Run the example to see a standalone bubble in action:

```bash
cd example
flutter pub get
flutter run
```

## License

MIT. See [LICENSE](LICENSE) for details.
