import 'package:flutter/material.dart';

import '../data/bowling_repository.dart';
import '../models/bowling.dart';
import '../models/bowling_meta.dart';

/// リーグ管理・順位表（簡易版）
class LeagueScreen extends StatefulWidget {
  const LeagueScreen({super.key, required this.onChanged});

  final VoidCallback onChanged;

  @override
  State<LeagueScreen> createState() => _LeagueScreenState();
}

class _LeagueScreenState extends State<LeagueScreen> {
  Future<void> _create() async {
    final name = TextEditingController();
    final desc = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('リーグ作成'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: name, decoration: const InputDecoration(labelText: 'リーグ名 *')),
            TextField(controller: desc, decoration: const InputDecoration(labelText: '説明')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('キャンセル')),
          FilledButton(onPressed: () => Navigator.pop(c, name.text.trim().isNotEmpty), child: const Text('作成')),
        ],
      ),
    );
    if (ok != true) return;
    BowlingRepository.instance.upsertLeague(
      BowlingLeague(
        id: 'league-${DateTime.now().millisecondsSinceEpoch}',
        name: name.text.trim(),
        description: desc.text.trim().isEmpty ? null : desc.text.trim(),
      ),
    );
    widget.onChanged();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final repo = BowlingRepository.instance;
    return Scaffold(
      appBar: AppBar(title: const Text('リーグ')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _create,
        icon: const Icon(Icons.add),
        label: const Text('リーグ作成'),
      ),
      body: repo.leagues.isEmpty
          ? const Center(child: Text('リーグを作成してゲームを紐づけましょう'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: repo.leagues.length,
              itemBuilder: (context, i) {
                final league = repo.leagues[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ExpansionTile(
                    title: Text(league.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(league.description ?? '${league.roundIds.length} ゲーム'),
                    children: [
                      _LeagueStandings(league: league),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: _AddGameToLeague(
                          league: league,
                          onAdded: () {
                            widget.onChanged();
                            setState(() {});
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class _LeagueStandings extends StatelessWidget {
  const _LeagueStandings({required this.league});

  final BowlingLeague league;

  @override
  Widget build(BuildContext context) {
    final repo = BowlingRepository.instance;
    final games = repo.roundsForLeague(league)
      ..sort((a, b) => (BowlingScoring.totalScore(b) ?? 0).compareTo(BowlingScoring.totalScore(a) ?? 0));

    if (games.isEmpty) {
      return const Padding(padding: EdgeInsets.all(16), child: Text('ゲーム未登録'));
    }

    final avg = BowlingStats.averageScore(games);
    return Column(
      children: [
        ListTile(
          dense: true,
          title: Text('リーグ平均: ${avg.toStringAsFixed(1)}', style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
        for (var rank = 0; rank < games.length; rank++)
          ListTile(
            dense: true,
            leading: CircleAvatar(radius: 14, child: Text('${rank + 1}', style: const TextStyle(fontSize: 12))),
            title: Text('${games[rank].date.month}/${games[rank].date.day}'),
            trailing: Text(
              '${BowlingScoring.totalScore(games[rank]) ?? "—"}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
      ],
    );
  }
}

class _AddGameToLeague extends StatelessWidget {
  const _AddGameToLeague({required this.league, required this.onAdded});

  final BowlingLeague league;
  final VoidCallback onAdded;

  @override
  Widget build(BuildContext context) {
    final repo = BowlingRepository.instance;
    final available = repo.rounds.where((r) => r.hasScoreData && !league.roundIds.contains(r.id)).toList();
    if (available.isEmpty) {
      return const Text('追加できるゲームがありません', textAlign: TextAlign.center);
    }
    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(labelText: 'ゲームをリーグに追加', border: OutlineInputBorder()),
      items: available.map((r) => DropdownMenuItem(value: r.id, child: Text(r.displayLabel))).toList(),
      onChanged: (id) {
        if (id != null && !league.roundIds.contains(id)) {
          league.roundIds.add(id);
          repo.upsertLeague(league);
          onAdded();
        }
      },
    );
  }
}
