// Tutorial Bubbles - A Flutter package for creating guided tutorials with
// overlay bubbles.
//
// This library provides widgets and controllers for creating guided user
// tutorials that highlight UI elements with styled bubbles and dimming
// overlays.
//
// For more details, see the README.
//
// Example usage:
//
// ```dart
// import 'package:tutorial_bubbles/tutorial_bubbles.dart';
//
// final controller = TutorialEngineController(
//   steps: [
//     TutorialStep(
//       targetKey: myButtonKey,
//       bubbleBuilder: (context) => TutorialTextContent(
//         text: 'Click this button to proceed',
//       ),
//     ),
//   ],
// );
//
// TutorialEngine(
//   controller: controller,
//   child: MyApp(),
// )
// ```

library tutorial_bubbles;

export 'src/enums.dart';
export 'src/tutorial_visuals.dart';
export 'src/tutorial_bubble.dart';
export 'src/tutorial_bubble_overlay.dart';
export 'src/tutorial_controller.dart';
export 'src/tutorial_engine.dart';
export 'src/tutorial_highlight_shape.dart';
