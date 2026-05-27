import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/bowling_repository.dart';
import '../../models/bowling.dart';
import '../game_detail_screen.dart';
import '../manual_score_entry_screen.dart';
import '../score_sheet_import_screen.dart';
import '../../services/share_service.dart';

class GamesTab extends StatelessWidget {
  const GamesTab({super.key, required this.onRefresh});

  final VoidCallback onRefresh;

  Future<void> _addManual(BuildContext context) async {
    final result = await Navigator.of(context).push<RoundData>(
      MaterialPageRoute(builder: (_) => const ManualScoreEntryScreen()),
    );
    if (result != null) {
      BowlingRepository.instance.upsertRound(result);
      onRefresh();
    }
  }

  Future<void> _addScan(BuildContext context) async {
    final result = await Navigator.of(context).push<RoundData>(
      MaterialPageRoute(builder: (_) => const ScoreSheetImportScreen()),
    );
    if (result != null) {
      result.source = 'scan';
      BowlingRepository.instance.upsertRound(result);
      onRefresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = BowlingRepository.instance;
    final rounds = repo.rounds.where((r) => r.hasScoreData).toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    return Scaffold(
      appBar: AppBar(title: const Text('ゲーム')),
      body: rounds.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('まだゲームがありません'),
                  const SizedBox(height: 16),
                  FilledButton.icon(onPressed: () => _addManual(context), icon: const Icon(Icons.edit), label: const Text('手入力')),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(onPressed: () => _addScan(context), icon: const Icon(Icons.document_scanner_outlined), label: const Text('写真から登録')),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () async => onRefresh(),
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: rounds.length,
                itemBuilder: (context, i) {
                  final r = rounds[i];
                  final total = BowlingScoring.totalScore(r);
                  final ball = repo.ballById(r.ballId);
                  final alley = repo.alleyById(r.alleyId);
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      onTap: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => GameDetailScreen(roundId: r.id, onChanged: onRefresh)),
                        );
                        onRefresh();
                      },
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                        child: Text(
                          total?.toString() ?? '—',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary, fontSize: 13),
                        ),
                      ),
                      title: Text(DateFormat('yyyy年M月d日').format(r.date)),
                      subtitle: Text(
                        [
                          if (alley != null) alley.name,
                          if (ball != null) ball.name,
                          r.source == 'scan' ? '写真' : '手入力',
                        ].join(' · '),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'このゲームをエクスポート',
                            icon: const Icon(Icons.share_outlined),
                            onPressed: () async {
                              await ShareService.instance.shareRoundAsFile(r);
                            },
                          ),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.small(
            heroTag: 'scan',
            onPressed: () => _addScan(context),
            child: const Icon(Icons.document_scanner_outlined),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.extended(
            heroTag: 'manual',
            onPressed: () => _addManual(context),
            icon: const Icon(Icons.edit_outlined),
            label: const Text('手入力'),
          ),
        ],
      ),
    );
  }
}
