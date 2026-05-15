import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ai_bowling_master/main.dart';

void main() {
  testWidgets('App loads and shows list page', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const AIBowlingMasterApp());

    // Verify that the app title is shown
    expect(find.text('AI ボウリングマスター'), findsOneWidget);

    // Verify that the FAB is present
    expect(find.byIcon(Icons.add), findsOneWidget);

    // Verify that sample rounds are displayed (we seeded rounds)
    expect(find.textContaining('ラウンド sample-1'), findsOneWidget);
  });
}
