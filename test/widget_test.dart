import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ai_bowling_master/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App loads with navigation shell', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const AIBowlingMasterApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('ホーム'), findsWidgets);
    expect(find.text('ゲーム'), findsWidgets);
    expect(find.textContaining('sample'), findsNothing);
  });
}
