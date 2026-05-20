import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/bowling_repository.dart';
import '../../models/bowling.dart';
import '../../models/bowling_meta.dart';
import '../../services/bowling_coach.dart';
import '../../services/game_filter_service.dart';

class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key, required this.onRefresh, required this.onGoGames});

  final VoidCallback onRefresh;
  final VoidCallback onGoGames;

  @override
  Widget build(BuildContext context) {
    final repo = BowlingRepository.instance;
    final rounds = GameFilterService.instance.apply(repo.rounds, GameSearchFilter(period: StatsPeriod.last30Days));
    final scheme = Theme.of(context).colorScheme;
    final fmt = DateFormat('M/d');

    return Scaffold(
      appBar: AppBar(title: const Text('ホーム'), centerTitle: false),
      body: rounds.isEmpty
          ? _EmptyHome(onGoGames: onGoGames)
          : RefreshIndicator(
              onRefresh: () async => onRefresh(),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _HeroStats(rounds: rounds, scheme: scheme),
                  const SizedBox(height: 20),
                  if (rounds.length >= 2) ...[
                    Text('直近30日の推移', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 160,
                      child: LineChart(
                        LineChartData(
                          gridData: FlGridData(show: true, drawVerticalLine: false),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 32)),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (v, m) {
                                  final i = v.toInt();
                                  if (i < 0 || i >= rounds.length) return const SizedBox.shrink();
                                  return Text(fmt.format(rounds[rounds.length - 1 - i].date), style: const TextStyle(fontSize: 9));
                                },
                              ),
                            ),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          ),
                          borderData: FlBorderData(show: false),
                          lineBarsData: [
                            LineChartBarData(
                              spots: List.generate(
                                rounds.length,
                                (i) => FlSpot(
                                  i.toDouble(),
                                  (BowlingStats.roundTotal(rounds[rounds.length - 1 - i]) ?? 0).toDouble(),
                                ),
                              ),
                              isCurved: true,
                              color: scheme.primary,
                              barWidth: 3,
                              dotData: const FlDotData(show: true),
                            ),
                          ],
                          minY: 0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  Text('クイック分析', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  _QuickInsightCard(rounds: rounds),
                  const SizedBox(height: 12),
                  Text('最近のゲーム', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...rounds.take(5).map((r) => _RecentGameTile(round: r, repo: repo)),
                ],
              ),
            ),
    );
  }
}

class _EmptyHome extends StatelessWidget {
  const _EmptyHome({required this.onGoGames});

  final VoidCallback onGoGames;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sports_score, size: 72, color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            const Text('スコアを記録して分析を始めましょう', textAlign: TextAlign.center, style: TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text(
              '手入力・写真スキャンのどちらでも登録できます',
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(onPressed: onGoGames, icon: const Icon(Icons.add), label: const Text('ゲームを追加')),
          ],
        ),
      ),
    );
  }
}

class _HeroStats extends StatelessWidget {
  const _HeroStats({required this.rounds, required this.scheme});

  final List<RoundData> rounds;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final avg = BowlingStats.averageScore(rounds);
    final hi = BowlingStats.highGame(rounds);
    final lo = BowlingStats.lowGame(rounds);
    final games = rounds.length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(colors: [scheme.primary, scheme.tertiary]),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('直近30日', style: TextStyle(color: scheme.onPrimary.withValues(alpha: 0.85))),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                avg.toStringAsFixed(1),
                style: TextStyle(fontSize: 44, fontWeight: FontWeight.w900, color: scheme.onPrimary, height: 1),
              ),
              const SizedBox(width: 8),
              Text('AVG', style: TextStyle(color: scheme.onPrimary.withValues(alpha: 0.9), fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _pill('HIGH', hi?.toString() ?? '—'),
              const SizedBox(width: 8),
              _pill('LOW', lo?.toString() ?? '—'),
              const SizedBox(width: 8),
              _pill('G', '$games'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pill(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(label, style: TextStyle(fontSize: 10, color: scheme.onPrimary.withValues(alpha: 0.8))),
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: scheme.onPrimary)),
          ],
        ),
      ),
    );
  }
}

class _QuickInsightCard extends StatelessWidget {
  const _QuickInsightCard({required this.rounds});

  final List<RoundData> rounds;

  @override
  Widget build(BuildContext context) {
    final report = BowlingCoach.instance.analyze(rounds);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.auto_awesome, size: 22),
            const SizedBox(width: 10),
            Expanded(child: Text(report.summary, style: const TextStyle(height: 1.4))),
          ],
        ),
      ),
    );
  }
}

class _RecentGameTile extends StatelessWidget {
  const _RecentGameTile({required this.round, required this.repo});

  final RoundData round;
  final BowlingRepository repo;

  @override
  Widget build(BuildContext context) {
    final total = BowlingScoring.totalScore(round);
    final alley = repo.alleyById(round.alleyId);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(total?.toString() ?? '?', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ),
        title: Text(DateFormat('yyyy/M/d HH:mm').format(round.date)),
        subtitle: Text([if (alley != null) alley.name, if (round.source == 'scan') '写真'].whereType<String>().join(' · ')),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
