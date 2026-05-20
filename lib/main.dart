import 'package:flutter/material.dart';

import 'screens/app_shell.dart';

void main() {
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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const AppShell(),
    );
  }
}
