## 0.1.1

- Add `TutorialCompletionPersistencePolicy` so apps can control whether `skip()` and `finish()` permanently suppress a tutorial.
- Keep `completedOnly` as the default behavior for backward compatibility.

## 0.1.0

- Add `TutorialTarget` with `key` and `rect` target support for virtual or painted tutorial regions.
- Add per-step `beforeShow`, `preferredSide`, `behavior`, and optional step `id` support.
- Add richer `TutorialPersistence` with save strategies and completed-flag handling.
- Add `bubbleCornerRadius` to `TutorialVisuals` and engine overlay plumbing.
- Update README and examples for the new tutorial engine API.

## 0.0.1

- Initial release of `tutorial_bubbles`.

