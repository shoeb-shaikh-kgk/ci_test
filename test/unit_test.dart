import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_ci/main.dart';

void main() {
  testWidgets('Counter increments test', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    await tester
        .tap(find.byKey(const Key('increment_button'))); // Use find.byKey here
    await tester.pump();

    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}
