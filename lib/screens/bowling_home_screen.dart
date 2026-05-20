import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/bowling.dart';
import '../services/bowling_coach.dart';
import '../widgets/bowling_score_sheet.dart';
import 'score_sheet_import_screen.dart';

class BowlingHomeScreen extends StatefulWidget {
  const BowlingHomeScreen({super.key});

  @override
  State<BowlingHomeScreen> createState() => _BowlingHomeScreenState();
}

class _BowlingHomeScreenState extends State<BowlingHomeScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final List<RoundData> _rounds = [];
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  RoundData? get _selected =>
      _rounds.isEmpty ? null : _rounds[_selectedIndex.clamp(0, _rounds.length - 1)];

  Future<void> _openImport({RoundData? existing}) async {
    final result = await Navigator.of(context).push<RoundData>(
      MaterialPageRoute(builder: (_) => ScoreSheetImportScreen(existingRound: existing)),
    );
    if (result == null || !mounted) return;

    setState(() {
      final idx = _rounds.indexWhere((r) => r.id == result.id);
      if (idx >= 0) {
        _rounds[idx] = result;
        _selectedIndex = idx;
      } else {
        _rounds.insert(0, result);
        _selectedIndex = 0;
      }
    });
  }

  void _deleteSelected() {
    if (_rounds.isEmpty) return;
    setState(() {
      _rounds.removeAt(_selectedIndex);
      if (_selectedIndex >= _rounds.length) {
        _selectedIndex = (_rounds.length - 1).clamp(0, 1 << 30);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI ボウリングマスター'),
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          tabs: const [
            Tab(text: '概要', icon: Icon(Icons.dashboard_outlined)),
            Tab(text: 'スコア表', icon: Icon(Icons.grid_on_outlined)),
            Tab(text: '分析', icon: Icon(Icons.insights_outlined)),
            Tab(text: 'AIコーチ', icon: Icon(Icons.psychology_outlined)),
          ],
        ),
        actions: [
          if (_selected != null)
            IconButton(
              tooltip: 'スコア表を再登録',
              onPressed: () => _openImport(existing: _selected),
              icon: const Icon(Icons.edit_document),
            ),
          IconButton(
            tooltip: '削除',
            onPressed: _rounds.isEmpty ? null : _deleteSelected,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _OverviewTab(
            rounds: _rounds,
            selectedIndex: _selectedIndex,
            onSelect: (i) => setState(() => _selectedIndex = i),
            onOpenScore: () => _tabs.animateTo(1),
            onImport: _openImport,
          ),
          _ScoreTab(
            rounds: _rounds,
            selectedIndex: _selectedIndex,
            onSelect: (i) => setState(() => _selectedIndex = i),
            selected: _selected,
            onImport: _openImport,
          ),
          _AnalyticsTab(rounds: _rounds, scheme: scheme, onImport: _openImport),
          _CoachTab(rounds: _rounds, scheme: scheme, onImport: _openImport),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openImport(),
        icon: const Icon(Icons.add_a_photo_outlined),
        label: const Text('スコア表を登録'),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onImport, this.message});

  final VoidCallback onImport;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.document_scanner_outlined, size: 72, color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)),
            const SizedBox(height: 20),
            Text(
              message ?? 'スコア表の写真を登録してください',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '撮影またはアルバムから選び、OCRで読み取って分析します',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onImport,
              icon: const Icon(Icons.add_a_photo_outlined),
              label: const Text('スコア表を登録'),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundPicker extends StatelessWidget {
  const _RoundPicker({
    required this.rounds,
    required this.selectedIndex,
    required this.onSelect,
  });

  final List<RoundData> rounds;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: rounds.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final r = rounds[i];
          return ChoiceChip(
            label: Text(r.displayLabel, style: const TextStyle(fontSize: 12)),
            selected: i == selectedIndex,
            onSelected: (_) => onSelect(i),
          );
        },
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({
    required this.rounds,
    required this.selectedIndex,
    required this.onSelect,
    required this.onOpenScore,
    required this.onImport,
  });

  final List<RoundData> rounds;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onOpenScore;
  final Future<void> Function({RoundData? existing}) onImport;

  @override
  Widget build(BuildContext context) {
    if (rounds.isEmpty) {
      return _EmptyState(onImport: () => onImport());
    }

    final scheme = Theme.of(context).colorScheme;
    final avg = BowlingStats.averageScore(rounds);
    final strike = BowlingStats.strikeRate(rounds);
    final spare = BowlingStats.spareRate(rounds);
    final spareConv = BowlingStats.spareConversionRate(rounds);
    final gutter = BowlingStats.gutterRate(rounds);

    final totals = rounds
        .map((r) => (BowlingStats.roundTotal(r) ?? BowlingScoring.rawPinTotal(r)).toDouble())
        .toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _RoundPicker(rounds: rounds, selectedIndex: selectedIndex, onSelect: onSelect),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _BigStatCard(title: '平均スコア', value: avg.toStringAsFixed(1), icon: Icons.sports_score, color: scheme.primary),
            _BigStatCard(
              title: 'ストライク率',
              value: '${(strike * 100).toStringAsFixed(1)}%',
              icon: Icons.flash_on,
              color: Colors.deepOrange,
            ),
            _BigStatCard(
              title: 'スペア率',
              value: '${(spare * 100).toStringAsFixed(1)}%',
              subtitle: '成功率 ${(spareConv * 100).toStringAsFixed(0)}%',
              icon: Icons.adjust,
              color: Colors.teal,
            ),
            _BigStatCard(
              title: 'ガター率',
              value: '${(gutter * 100).toStringAsFixed(1)}%',
              icon: Icons.horizontal_rule,
              color: scheme.error,
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (totals.isNotEmpty) ...[
          Text('スコア推移', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true, drawVerticalLine: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 36)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, m) => Text('${v.toInt() + 1}', style: const TextStyle(fontSize: 10)),
                    ),
                  ),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(totals.length, (i) => FlSpot(i.toDouble(), totals[i])),
                    isCurved: true,
                    color: scheme.primary,
                    barWidth: 3,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(show: true, color: scheme.primary.withValues(alpha: 0.08)),
                  ),
                ],
                minY: 0,
                maxY: (totals.reduce((a, b) => a > b ? a : b) + 20).clamp(120, 300),
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
        FilledButton.tonalIcon(onPressed: onOpenScore, icon: const Icon(Icons.grid_on), label: const Text('スコア表タブを開く')),
      ],
    );
  }
}

class _BigStatCard extends StatelessWidget {
  const _BigStatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final w = (MediaQuery.sizeOf(context).width - 52) / 2;
    return SizedBox(
      width: w.clamp(140, 220),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 22),
                  const SizedBox(width: 8),
                  Expanded(child: Text(title, style: Theme.of(context).textTheme.labelLarge)),
                ],
              ),
              const SizedBox(height: 10),
              Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ScoreTab extends StatelessWidget {
  const _ScoreTab({
    required this.rounds,
    required this.selectedIndex,
    required this.onSelect,
    required this.selected,
    required this.onImport,
  });

  final List<RoundData> rounds;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final RoundData? selected;
  final Future<void> Function({RoundData? existing}) onImport;

  @override
  Widget build(BuildContext context) {
    if (rounds.isEmpty) {
      return _EmptyState(onImport: () => onImport());
    }
    if (selected == null || !selected!.hasScoreData) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _RoundPicker(rounds: rounds, selectedIndex: selectedIndex, onSelect: onSelect),
          const SizedBox(height: 24),
          _EmptyState(
            onImport: () => onImport(existing: selected),
            message: 'このラウンドにはスコアがありません\n写真から登録してください',
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _RoundPicker(rounds: rounds, selectedIndex: selectedIndex, onSelect: onSelect),
        const SizedBox(height: 16),
        BowlingScoreSheet(round: selected!),
      ],
    );
  }
}

class _AnalyticsTab extends StatelessWidget {
  const _AnalyticsTab({required this.rounds, required this.scheme, required this.onImport});

  final List<RoundData> rounds;
  final ColorScheme scheme;
  final Future<void> Function({RoundData? existing}) onImport;

  @override
  Widget build(BuildContext context) {
    if (rounds.isEmpty) {
      return _EmptyState(onImport: () => onImport());
    }
    final pinCounts = BowlingStats.pinLeaveCounts(rounds);
    final maxPin = pinCounts.values.fold<int>(0, (a, b) => a > b ? a : b);
    final leaves = BowlingStats.leavePatternCounts(rounds);
    final topLeaves = leaves.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('ピン別残り回数', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        SizedBox(
          height: 220,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: (maxPin + 2).toDouble(),
              barGroups: [
                for (var p = 1; p <= 10; p++)
                  BarChartGroupData(
                    x: p,
                    barRods: [
                      BarChartRodData(
                        toY: (pinCounts[p] ?? 0).toDouble(),
                        width: 14,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        color: scheme.primary,
                      ),
                    ],
                  ),
              ],
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (v, m) => Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text('${v.toInt()}', style: const TextStyle(fontSize: 11)),
                    ),
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
        const SizedBox(height: 24),
        Text('代表的なリーヴ', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (topLeaves.isEmpty)
          Text('データ不足（スコア表登録後に表示）', style: TextStyle(color: scheme.onSurfaceVariant))
        else
          ...topLeaves.take(12).map(
                (e) => ListTile(
                  leading: CircleAvatar(radius: 16, child: Text('${e.value}', style: const TextStyle(fontSize: 11))),
                  title: Text(LeavePatternNames.describe(e.key)),
                ),
              ),
      ],
    );
  }
}

class _CoachTab extends StatelessWidget {
  const _CoachTab({required this.rounds, required this.scheme, required this.onImport});

  final List<RoundData> rounds;
  final ColorScheme scheme;
  final Future<void> Function({RoundData? existing}) onImport;

  @override
  Widget build(BuildContext context) {
    if (rounds.isEmpty) {
      return _EmptyState(onImport: () => onImport());
    }
    final report = BowlingCoach.instance.analyze(rounds);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          color: scheme.primaryContainer.withValues(alpha: 0.35),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.auto_awesome, color: scheme.primary, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('AI分析サマリー', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(report.summary, style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.45)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        ...report.metricsSnapshot.entries.map(
          (e) => ListTile(title: Text(e.key), trailing: Text(e.value, style: const TextStyle(fontWeight: FontWeight.w600))),
        ),
        const SizedBox(height: 8),
        Text('フォーカス', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
        ...report.focusAreas.map(
          (t) => ListTile(
            leading: const Icon(Icons.flag_outlined),
            title: Text(t),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        const SizedBox(height: 8),
        Text('推奨ドリル', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
        ...report.drills.map(
          (t) => ListTile(leading: Icon(Icons.fitness_center, color: scheme.secondary), title: Text(t)),
        ),
        const SizedBox(height: 16),
        Text(
          '※ 登録したスコア表データを端末内で集計した指導です。',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
