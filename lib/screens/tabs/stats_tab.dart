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
  bool _showMovingAvg = true;
  int _maWindow = 5;

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

    final scores = rounds.map((r) => (BowlingScoring.totalScore(r) ?? BowlingScoring.rawPinTotal(r)).toDouble()).toList();
    List<double> movingAvg(List<double> data, int window) {
      if (data.isEmpty) return [];
      final out = <double>[];
      for (var i = 0; i < data.length; i++) {
        final start = (i - window + 1) < 0 ? 0 : (i - window + 1);
        final slice = data.sublist(start, i + 1);
        out.add(slice.reduce((a, b) => a + b) / slice.length);
      }
      return out;
    }
    final maScores = _showMovingAvg ? movingAvg(scores, _maWindow) : <double>[];

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
                Text('スコア推移', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 180,
                        child: LineChart(
                          LineChartData(
                            minY: 0,
                            maxY: 300,
                            lineBarsData: [
                              LineChartBarData(
                                spots: List.generate(scores.length, (i) => FlSpot(i.toDouble(), scores[i])),
                                isCurved: false,
                                barWidth: 2,
                                color: scheme.primary,
                                dotData: FlDotData(show: false),
                              ),
                              if (_showMovingAvg)
                                LineChartBarData(
                                  spots: List.generate(maScores.length, (i) => FlSpot(i.toDouble(), maScores[i])),
                                  isCurved: true,
                                  barWidth: 2.5,
                                  color: Colors.deepOrange,
                                  dotData: FlDotData(show: false),
                                ),
                            ],
                            titlesData: FlTitlesData(
                              bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, m) {
                                final idx = v.toInt();
                                if (idx < 0 || idx >= rounds.length) return const SizedBox.shrink();
                                if (rounds.length > 6 && idx % (rounds.length ~/ 5 + 1) != 0) return const SizedBox.shrink();
                                final d = rounds[idx].date;
                                return Text('${d.month}/${d.day}', style: const TextStyle(fontSize: 10));
                              })),
                              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 36)),
                            ),
                            gridData: FlGridData(show: true),
                            borderData: FlBorderData(show: false),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      children: [
                        Row(children: [const Text('移動平均'), Switch(value: _showMovingAvg, onChanged: (v) => setState(() => _showMovingAvg = v))]),
                        if (_showMovingAvg)
                          SizedBox(
                            width: 120,
                            child: Row(children: [const Text('窓'), Expanded(child: Slider(value: _maWindow.toDouble(), min: 2, max: 10, divisions: 8, label: '$_maWindow', onChanged: (v) => setState(() => _maWindow = v.toInt())))])
                          ),
                      ],
                    )
                  ],
                ),
                const SizedBox(height: 16),
                Text('スコア分布', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 160,
                  child: Builder(builder: (ctx) {
                    final buckets = List<int>.filled(6, 0);
                    for (final s in scores) {
                      final idx = (s / 50).clamp(0, 5).toInt();
                      buckets[idx]++;
                    }
                    final maxCount = buckets.isEmpty ? 1 : buckets.reduce((a, b) => a > b ? a : b);
                    return BarChart(
                      BarChartData(
                        maxY: (maxCount + 1).toDouble(),
                        barGroups: List.generate(6, (i) => BarChartGroupData(x: i, barRods: [BarChartRodData(toY: buckets[i].toDouble(), width: 18, color: scheme.primary)])),
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, m) {
                            final i = v.toInt();
                            final range = '${i * 50}-${i * 50 + 49}';
                            return Text(range, style: const TextStyle(fontSize: 10));
                          })),
                          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28)),
                        ),
                        borderData: FlBorderData(show: false),
                        gridData: FlGridData(show: true),
                      ),
                    );
                  }),
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
