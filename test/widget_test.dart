import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sample/main.dart';

void main() {
  testWidgets('App loads and shows list page', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const IdeaStreamApp());

    // Verify that the app title is shown
    expect(find.text('IdeaStream'), findsOneWidget);

    // Verify that the FAB is present
    expect(find.byIcon(Icons.add), findsOneWidget);

    // Verify that initial ideas are displayed
    expect(find.text('新しいアプリのUI案'), findsOneWidget);
    expect(find.text('ランチのアイデア'), findsOneWidget);
  });
}
