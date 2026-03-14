import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tutorial_bubbles/tutorial_bubbles.dart';
import 'package:tutorial_bubbles_example/main.dart';
import 'package:tutorial_bubbles_example/tutorial_demo.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('home page shows the refreshed demo menu', (tester) async {
    await tester.pumpWidget(const TutorialBubblesExampleApp());

    expect(find.text('Tutorial Bubbles Example'), findsOneWidget);
    expect(find.text('Standalone spotlight'), findsOneWidget);
    expect(find.text('Feature tour'), findsOneWidget);
    expect(find.text('Reset tutorial persistence'), findsOneWidget);
  });

  testWidgets('feature tour starts from the home page and shows the first step',
      (tester) async {
    await tester.pumpWidget(const TutorialBubblesExampleApp());

    await tester.tap(find.text('Feature tour'));
    await tester.pumpAndSettle();

    expect(find.text('Feature Tour'), findsOneWidget);
    expect(
      find.text('Start here. This first step uses a keyed widget target.'),
      findsOneWidget,
    );
  });

  testWidgets('beforeShow step scrolls the deferred chip into the flow',
      (tester) async {
    await tester.pumpWidget(const TutorialBubblesExampleApp());

    await tester.tap(find.text('Feature tour'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Welcome button'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Placement demo'));
    await tester.pumpAndSettle();

    expect(
      find.text('This step scrolls into view with beforeShow before measuring.'),
      findsOneWidget,
    );
    expect(find.text('Filter chip target'), findsOneWidget);
  });

  testWidgets('feature tour navigates to details from the highlighted step',
      (tester) async {
    await tester.pumpWidget(const TutorialBubblesExampleApp());

    await tester.tap(find.text('Feature tour'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Welcome button'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Placement demo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Filter chip target'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Painted summary band'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open details'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.text('Details showcase'), findsOneWidget);
    expect(find.text('Details header target'), findsOneWidget);
  });

  testWidgets('reset tutorial persistence clears resume and completion state',
      (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'tutorial_progress_$tutorialPersistenceId': 4,
      'tutorial_progress_$tutorialCompletedKey': true,
    });

    await tester.pumpWidget(const TutorialBubblesExampleApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Reset tutorial persistence'));
    await tester.pumpAndSettle();

    expect(await TutorialProgressStorage.readIndex(tutorialPersistenceId), isNull);
    expect(
      await TutorialProgressStorage.readCompleted(tutorialCompletedKey),
      isFalse,
    );
  });
}
