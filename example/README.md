# tutorial_bubbles_example

Example app for the `tutorial_bubbles` package.

## What it demonstrates

- `Standalone spotlight` shows manual `Rect` measurement with `TutorialBubbleOverlay`
- `Feature tour` shows the engine-driven flow with:
  - `TutorialTarget.key(...)`
  - `TutorialTarget.rect(...)`
  - `beforeShow`
  - per-step `preferredSide`
  - per-step `TutorialStepBehavior`
  - cross-screen navigation
  - `advanceOnTargetTap` for safe route-driven progression
  - `TutorialPersistence`
- `Reset tutorial persistence` clears saved progress and the completed flag

## Run the example

```bash
flutter pub get
flutter run
```

## Run the example tests

```bash
flutter test
```

## Manual visual QA checklist

- Launch `Standalone spotlight` and verify the bubble updates when changing side, shape, and roundness
- Launch `Feature tour` and verify:
  - the first step highlights the welcome button
  - the scroll chip step animates into view before the bubble appears
  - the synthetic summary band highlights a painted region instead of a child widget
  - the details navigation step follows the route transition
  - repeated taps on the navigation step do not stack multiple details routes
  - the blocked-target step prevents target activation while the background control still works
  - the final step can complete the tutorial and suppress it on the next launch until reset
