import 'package:flutter/material.dart';

import '../data/bowling_repository.dart';
import '../services/bowling_coach.dart';

class AICoachPage extends StatelessWidget {
  const AICoachPage({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = BowlingRepository.instance;
    final rounds = repo.rounds.where((r) => r.hasScoreData).toList();
    final report = BowlingCoach.instance.analyze(rounds);

    return Scaffold(
      appBar: AppBar(title: const Text('AIコーチ（詳細）')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('サマリー', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Card(child: Padding(padding: const EdgeInsets.all(12), child: Text(report.summary))),
              const SizedBox(height: 12),
              Text('注力ポイント', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ...report.focusAreas.map((f) => ListTile(leading: const Icon(Icons.flag), title: Text(f))),
              const SizedBox(height: 12),
              Text('推奨ドリル', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ...report.drills.map((d) => ListTile(leading: const Icon(Icons.fitness_center), title: Text(d))),
              const SizedBox(height: 12),
              Text('メトリクス', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: report.metricsSnapshot.entries
                        .map((e) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Text('${e.key}: ${e.value}')))
                        .toList(),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: () {
                  showDialog<void>(
                    context: context,
                    builder: (c) => AlertDialog(
                      title: const Text('簡易AIアドバイス'),
                      content: const Text('詳細モデル連携は未構成です。将来的に動画解析やサーバー推論でパーソナライズを行います。'),
                      actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('閉じる'))],
                    ),
                  );
                },
                icon: const Icon(Icons.smart_toy_outlined),
                label: const Text('より詳しいAIアドバイス（将来）'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
