import 'package:flutter_test/flutter_test.dart';

import 'package:tutorial_bubbles_example/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const TutorialBubblesExampleApp());

    expect(find.text('Tutorial Bubbles Example'), findsOneWidget);
    expect(find.text('Standalone spotlight'), findsOneWidget);
    expect(find.text('Full tutorial'), findsOneWidget);
  });
}
