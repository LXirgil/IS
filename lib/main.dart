import 'package:flutter/material.dart';
import 'models/bowling.dart';
import 'dart:math';
import 'package:fl_chart/fl_chart.dart';

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
      home: const BowlingDashboardPage(),
    );
  }
}

class BowlingDashboardPage extends StatefulWidget {
  const BowlingDashboardPage({super.key});

  @override
  State<BowlingDashboardPage> createState() => _BowlingDashboardPageState();
}

class _BowlingDashboardPageState extends State<BowlingDashboardPage> {
  final List<RoundData> _rounds = [];

  @override
  void initState() {
    super.initState();
    _seedSampleRounds();
  }

  void _seedSampleRounds() {
    final rnd = Random(42);
    for (int r = 0; r < 5; r++) {
      final round = RoundData(id: 'sample-${r + 1}');
      for (var f in round.frames) {
        final first = rnd.nextInt(11);
        f.throws.add(ThrowData(pinsKnocked: first, pinsLeft: _calcPinsLeft(first)));
        if (first < 10) {
          final second = rnd.nextInt(11 - first);
          f.throws.add(ThrowData(pinsKnocked: second, pinsLeft: _calcPinsLeft(first + second)));
        }
      }
      _rounds.add(round);
    }
  }

  List<int> _calcPinsLeft(int knocked) {
    if (knocked >= 10) return <int>[];
    final left = <int>[];
    for (var i = 1; i <= 10 - knocked; i++) {
      left.add(i);
    }
    return left;
  }

  void _addEmptyRound() {
    setState(() {
      _rounds.insert(0, RoundData(id: 'round-${DateTime.now().millisecondsSinceEpoch}'));
    });
  }

  @override
  Widget build(BuildContext context) {
    final avg = BowlingStats.averageScore(_rounds).toStringAsFixed(1);
    final strikeRate = '${(BowlingStats.strikeRate(_rounds) * 100).toStringAsFixed(1)}%';
    final spareRate = '${(BowlingStats.spareRate(_rounds) * 100).toStringAsFixed(1)}%';
    final totals = _rounds.map((r) => BowlingStats.roundTotal(r).toDouble()).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('AI ボウリングマスター')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: Colors.indigo.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _statTile('平均スコア', avg),
                    _statTile('ストライク率', strikeRate),
                    _statTile('スペア率', spareRate),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (totals.isNotEmpty) ...[
              const Text('スコア推移', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SizedBox(
                height: 160,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(show: true, drawVerticalLine: false),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, interval: 10)),
                        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: List.generate(totals.length, (i) => FlSpot(i.toDouble(), totals[i])),
                          isCurved: true,
                          color: Colors.indigo,
                          barWidth: 3,
                          dotData: FlDotData(show: true),
                        ),
                      ],
                      minY: 0,
                      maxY: (totals.reduce((a, b) => a > b ? a : b) + 10),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            const Text('直近のラウンド', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: _rounds.isEmpty
                  ? const Center(child: Text('ラウンドがありません。+ボタンで追加してください。'))
                  : ListView.builder(
                      itemCount: _rounds.length,
                      itemBuilder: (c, i) {
                        final r = _rounds[i];
                        final total = BowlingStats.roundTotal(r);
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: ListTile(
                            title: Text('ラウンド ${r.id}'),
                            subtitle: Text('日付: ${r.date.toLocal().toString().split(".").first}'),
                            trailing: Text('$total 点', style: const TextStyle(fontWeight: FontWeight.bold)),
                            onTap: () => _showRoundDetail(r),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addEmptyRound,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _statTile(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }

  void _showRoundDetail(RoundData r) {
    showModalBottomSheet(context: context, builder: (c) {
      return Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ラウンド ${r.id}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('日付: ${r.date.toLocal().toString().split(".").first}'),
            const SizedBox(height: 12),
            SizedBox(
              height: 240,
              child: ListView.builder(
                itemCount: r.frames.length,
                itemBuilder: (context, idx) {
                  final f = r.frames[idx];
                  return ListTile(
                    title: Text('フレーム ${f.frameNumber}'),
                    subtitle: Text('ピン: ${f.totalPinsKnocked}  投球: ${f.throws.map((t) => t.pinsKnocked).join(', ')}'),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('閉じる')),
          ],
        ),
      );
    });
  }
}
