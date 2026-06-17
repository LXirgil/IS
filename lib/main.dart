import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'services/cloud_sync_service.dart';

import 'screens/app_shell.dart';
import 'screens/flutter_map_page.dart';
import 'screens/ai_coach_page.dart';
import 'data/bowling_repository.dart';
import 'services/auto_backup.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  var firebaseAvailable = false;
  if (!kIsWeb) {
    try {
      await Firebase.initializeApp();
      firebaseAvailable = true;
    } catch (e, st) {
      // Firebase not configured on native platform (?) — continue in guest/local mode.
      // ignore: avoid_print
      print('Firebase.initializeApp() failed: $e\n$st');
    }
  } else {
    // Running on web: skip initialize here to avoid missing FirebaseOptions causing app crash.
    // If you have generated `DefaultFirebaseOptions` for web, replace this logic to initialize.
    // ignore: avoid_print
    print('kIsWeb true — skipping Firebase.initializeApp() (no web config)');
  }
  await BowlingRepository.instance.ensureLoaded();
  // start auto backup (immediate + daily) only on native platforms
  if (!kIsWeb) {
    AutoBackupService.instance.start();
  }
  // start cloud sync (listens to auth changes) only when Firebase is available
  if (firebaseAvailable) {
    CloudSyncService.instance.start();
  }
  runApp(const AIBowlingMasterApp());
}

class AIBowlingMasterApp extends StatelessWidget {
  const AIBowlingMasterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI ボウリングマスター',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.brown, brightness: Brightness.light),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFFBF7F0),
        cardColor: const Color(0xFFF4EEE6),
        dialogBackgroundColor: const Color(0xFFF4EEE6),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF6B4C3B),
          foregroundColor: Color(0xFFF7EDE2),
          elevation: 0,
          centerTitle: false,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: const Color(0xFF79604E),
          indicatorColor: const Color(0xFFB08A6E),
          labelTextStyle: WidgetStatePropertyAll(TextStyle(color: Color(0xFFF7EDE2))),
        ),
      ),
      home: const AppShell(),
      routes: {
        '/map': (context) => const FlutterMapPage(),
        '/ai_coach': (context) => const AICoachPage(),
      },
    );
  }
}

// Login flow removed: app starts directly at AppShell.
