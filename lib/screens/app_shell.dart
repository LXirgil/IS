import 'package:flutter/material.dart';

import '../data/bowling_repository.dart';
import 'tabs/dashboard_tab.dart';
import 'tabs/games_tab.dart';
import 'tabs/gear_tab.dart';
import 'tabs/more_tab.dart';
import 'tabs/stats_tab.dart';

/// メインナビゲーション（ボスク相当機能をオリジナル5タブ構成で提供）
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    // ignore: avoid_print
    print('AppShell.initState: start loading repository');
    _load();
  }

  Future<void> _load() async {
    // ignore: avoid_print
    print('AppShell._load: ensuring repository loaded');
    await BowlingRepository.instance.ensureLoaded();
    // ignore: avoid_print
    print('AppShell._load: repository loaded');
    if (mounted) setState(() => _loading = false);
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final tabs = [
      DashboardTab(onRefresh: _refresh, onGoGames: () => setState(() => _index = 1)),
      GamesTab(onRefresh: _refresh),
      StatsTab(onRefresh: _refresh),
      GearTab(onRefresh: _refresh),
      MoreTab(onRefresh: _refresh),
    ];

    return Scaffold(
      body: tabs[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'ホーム'),
          NavigationDestination(icon: Icon(Icons.sports_score_outlined), selectedIcon: Icon(Icons.sports_score), label: 'ゲーム'),
          NavigationDestination(icon: Icon(Icons.insights_outlined), selectedIcon: Icon(Icons.insights), label: '分析'),
          NavigationDestination(icon: Icon(Icons.sports_baseball_outlined), selectedIcon: Icon(Icons.sports_baseball), label: 'ボール'),
          NavigationDestination(icon: Icon(Icons.more_horiz), selectedIcon: Icon(Icons.more_horiz), label: 'その他'),
        ],
      ),
    );
  }

  // App-level titles are provided by each tab's AppBar now.
}
