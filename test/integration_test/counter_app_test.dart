import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:test_ci/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Integration test', (WidgetTester tester) async {
    app.main();

    await tester.pumpAndSettle();

    expect(find.text('Counter Value:'), findsOneWidget);

    await tester
        .tap(find.byKey(const Key('increment_button'))); // Use the unique key
    await tester.pumpAndSettle();

    expect(find.text('Counter Value:'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);

    await tester.tap(
        find.byKey(const Key('second_screen_button'))); // Use the unique key
    await tester.pumpAndSettle();

    expect(find.text('This is the Second Screen!'), findsOneWidget);

    await tester
        .tap(find.byKey(const Key('back_button'))); // Use the unique key
    await tester.pumpAndSettle();

    expect(find.text('Counter Value:'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
  });
}
