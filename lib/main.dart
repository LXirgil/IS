import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/cloud_sync_service.dart';
import 'services/auth_service.dart';

import 'screens/app_shell.dart';
import 'screens/flutter_map_page.dart';
import 'screens/ai_coach_page.dart';
import 'data/bowling_repository.dart';
import 'services/auto_backup.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await BowlingRepository.instance.ensureLoaded();
  // start auto backup (immediate + daily)
  AutoBackupService.instance.start();
  // start cloud sync (listens to auth changes)
  CloudSyncService.instance.start();
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
