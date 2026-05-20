import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/bowling_repository.dart';
import '../../models/bowling.dart';
import '../../models/bowling_meta.dart';

class GearTab extends StatelessWidget {
  const GearTab({super.key, required this.onRefresh});

  final VoidCallback onRefresh;

  Future<void> _addBall(BuildContext context) async {
    final nameController = TextEditingController();
    final brandController = TextEditingController();
    final weightController = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('マイボール追加'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: '名前 *')),
            TextField(controller: brandController, decoration: const InputDecoration(labelText: 'ブランド')),
            TextField(controller: weightController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '重量 (lbs)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('キャンセル')),
          FilledButton(
            onPressed: () => Navigator.pop(c, nameController.text.trim().isNotEmpty),
            child: const Text('追加'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final ball = BowlingBall(
      id: 'ball-${DateTime.now().millisecondsSinceEpoch}',
      name: nameController.text.trim(),
      brand: brandController.text.trim().isEmpty ? null : brandController.text.trim(),
      weight: int.tryParse(weightController.text),
    );
    BowlingRepository.instance.upsertBall(ball);
    onRefresh();
  }

  @override
  Widget build(BuildContext context) {
    final repo = BowlingRepository.instance;
    return Scaffold(
      appBar: AppBar(title: const Text('マイボール')),
      body: repo.balls.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('ボールを登録して球別成績を追跡'),
                  const SizedBox(height: 16),
                  FilledButton.icon(onPressed: () => _addBall(context), icon: const Icon(Icons.add), label: const Text('ボール追加')),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: repo.balls.length,
              itemBuilder: (context, i) {
                final ball = repo.balls[i];
                final games = repo.roundsForBall(ball.id);
                final avg = games.isEmpty ? 0.0 : BowlingStats.averageScore(games);
                final hi = BowlingStats.highGame(games);
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Color(ball.colorValue).withValues(alpha: 0.3),
                      child: Icon(Icons.sports_baseball, color: Color(ball.colorValue)),
                    ),
                    title: Text(ball.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      [
                        if (ball.brand != null) ball.brand,
                        if (ball.weight != null) '${ball.weight}lbs',
                        if (ball.lastMaintenance != null) 'メンテ: ${DateFormat('y/M/d').format(ball.lastMaintenance!)}',
                      ].whereType<String>().join(' · '),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('AVG ${avg.toStringAsFixed(1)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text('${games.length}G · HI ${hi ?? "—"}', style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                    onLongPress: () async {
                      final del = await showDialog<bool>(
                        context: context,
                        builder: (c) => AlertDialog(
                          title: Text('${ball.name} を削除？'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('キャンセル')),
                            FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('削除')),
                          ],
                        ),
                      );
                      if (del == true) {
                        repo.deleteBall(ball.id);
                        onRefresh();
                      }
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addBall(context),
        icon: const Icon(Icons.add),
        label: const Text('ボール追加'),
      ),
    );
  }
}
