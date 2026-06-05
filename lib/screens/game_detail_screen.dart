import 'package:flutter/material.dart';

import '../data/bowling_repository.dart';
import '../models/bowling.dart';
import '../services/share_service.dart';
import '../widgets/bowling_score_sheet.dart';
import 'manual_score_entry_screen.dart';
import 'score_sheet_import_screen.dart';

class GameDetailScreen extends StatelessWidget {
  const GameDetailScreen({super.key, required this.roundId, required this.onChanged});

  final String roundId;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final repo = BowlingRepository.instance;
    final round = repo.rounds.firstWhere((r) => r.id == roundId);
    final ball = repo.ballById(round.ballId);
    final alley = repo.alleyById(round.alleyId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ゲーム詳細'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () => ShareService.instance.shareGameSummary(round),
          ),
          PopupMenuButton<String>(
            onSelected: (v) async {
              if (v == 'delete') {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (c) => AlertDialog(
                    title: const Text('削除しますか？'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('キャンセル')),
                      FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('削除')),
                    ],
                  ),
                );
                if (ok == true) {
                  repo.deleteRound(roundId);
                  onChanged();
                  if (context.mounted) Navigator.pop(context);
                }
              }
            },
            itemBuilder: (_) => [const PopupMenuItem(value: 'delete', child: Text('削除'))],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (ball != null || alley != null)
            Wrap(
              spacing: 8,
              children: [
                if (ball != null) Chip(avatar: const Icon(Icons.sports_baseball, size: 18), label: Text(ball.name)),
                if (alley != null) Chip(avatar: const Icon(Icons.place_outlined, size: 18), label: Text(alley.name)),
              ],
            ),
          if (round.note != null) ...[
            const SizedBox(height: 8),
            Text(round.note!, style: Theme.of(context).textTheme.bodyMedium),
          ],
          const SizedBox(height: 16),
          BowlingScoreSheet(round: round),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final r = await Navigator.of(context).push<RoundData>(
                      MaterialPageRoute(builder: (_) => ManualScoreEntryScreen(existing: round)),
                    );
                    if (r != null) {
                      await repo.upsertRound(r);
                      onChanged();
                    }
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('編集'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final r = await Navigator.of(context).push<RoundData>(
                      MaterialPageRoute(builder: (_) => ScoreSheetImportScreen(existingRound: round)),
                    );
                    if (r != null) {
                      r.source = 'scan';
                      await repo.upsertRound(r);
                      onChanged();
                    }
                  },
                  icon: const Icon(Icons.document_scanner_outlined),
                  label: const Text('写真'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
