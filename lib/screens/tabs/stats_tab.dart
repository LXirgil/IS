import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../data/bowling_repository.dart';
import '../../models/bowling.dart';
import '../../models/bowling_meta.dart';
import '../../services/bowling_coach.dart';
import '../../services/game_filter_service.dart';
import '../search_filter_screen.dart';

class StatsTab extends StatefulWidget {
  const StatsTab({super.key, required this.onRefresh});

  final VoidCallback onRefresh;

  @override
  State<StatsTab> createState() => _StatsTabState();
}

class _StatsTabState extends State<StatsTab> {
  GameSearchFilter _filter = GameSearchFilter();

  List<RoundData> get _rounds =>
      GameFilterService.instance.apply(BowlingRepository.instance.rounds, _filter);

  Future<void> _openFilter() async {
    final next = await Navigator.of(context).push<GameSearchFilter>(
      MaterialPageRoute(builder: (_) => SearchFilterScreen(initial: _filter)),
    );
    if (next != null) setState(() => _filter = next);
  }

  @override
  Widget build(BuildContext context) {
    final rounds = _rounds;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('分析'),
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: _filter.isActive,
              child: const Icon(Icons.filter_list),
            ),
            onPressed: _openFilter,
          ),
        ],
      ),
      body: rounds.isEmpty
          ? const Center(child: Text('条件に合うゲームがありません'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Wrap(
                  spacing: 8,
                  children: [
                    FilterChip(
                      label: Text(_filter.period.label),
                      selected: true,
                      onSelected: (_) => _openFilter(),
                    ),
                    if (_filter.isActive)
                      ActionChip(label: const Text('フィルター解除'), onPressed: () => setState(() => _filter = GameSearchFilter())),
                  ],
                ),
                const SizedBox(height: 16),
                _RateGrid(rounds: rounds),
                const SizedBox(height: 20),
                Text('ストライク / スペア / オープン', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 180,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 36,
                      sections: [
                        PieChartSectionData(
                          value: BowlingStats.strikeRate(rounds) * 100,
                          title: 'ST',
                          color: Colors.deepOrange,
                          radius: 48,
                          titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        PieChartSectionData(
                          value: BowlingStats.spareRate(rounds) * 100,
                          title: 'SP',
                          color: Colors.teal,
                          radius: 44,
                          titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        PieChartSectionData(
                          value: BowlingStats.openFrameRate(rounds) * 100,
                          title: 'OP',
                          color: scheme.outline,
                          radius: 40,
                          titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text('ピン残り傾向', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 200,
                  child: BarChart(
                    BarChartData(
                      maxY: (BowlingStats.pinLeaveCounts(rounds).values.fold<int>(0, (a, b) => a > b ? a : b) + 2).toDouble(),
                      barGroups: [
                        for (var p = 1; p <= 10; p++)
                          BarChartGroupData(
                            x: p,
                            barRods: [
                              BarChartRodData(
                                toY: (BowlingStats.pinLeaveCounts(rounds)[p] ?? 0).toDouble(),
                                width: 12,
                                color: scheme.primary,
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                              ),
                            ],
                          ),
                      ],
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (v, m) => Text('${v.toInt()}', style: const TextStyle(fontSize: 10)),
                          ),
                        ),
                        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      gridData: FlGridData(show: true, drawVerticalLine: false),
                      borderData: FlBorderData(show: false),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text('AIコーチ所見', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Text(BowlingCoach.instance.analyze(rounds).summary),
                  ),
                ),
              ],
            ),
    );
  }
}

class _RateGrid extends StatelessWidget {
  const _RateGrid({required this.rounds});

  final List<RoundData> rounds;

  @override
  Widget build(BuildContext context) {
    final items = [
      ('平均', BowlingStats.averageScore(rounds).toStringAsFixed(1)),
      ('ハイ', '${BowlingStats.highGame(rounds) ?? "—"}'),
      ('ロー', '${BowlingStats.lowGame(rounds) ?? "—"}'),
      ('ST%', '${(BowlingStats.strikeRate(rounds) * 100).toStringAsFixed(0)}%'),
      ('SP%', '${(BowlingStats.spareRate(rounds) * 100).toStringAsFixed(0)}%'),
      ('ガター', '${(BowlingStats.gutterRate(rounds) * 100).toStringAsFixed(1)}%'),
    ];
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 1.4,
      children: items
          .map(
            (e) => Card(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(e.$1, style: Theme.of(context).textTheme.labelSmall),
                    Text(e.$2, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}
