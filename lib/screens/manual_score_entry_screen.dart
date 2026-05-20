import 'package:flutter/material.dart';

import '../data/bowling_repository.dart';
import '../models/bowling.dart';
import '../services/manual_score_controller.dart';
import '../widgets/bowling_score_sheet.dart';

/// フレームごとの手入力（ボスクの「シンプルなスコア入力」相当）
class ManualScoreEntryScreen extends StatefulWidget {
  const ManualScoreEntryScreen({super.key, this.existing});

  final RoundData? existing;

  @override
  State<ManualScoreEntryScreen> createState() => _ManualScoreEntryScreenState();
}

class _ManualScoreEntryScreenState extends State<ManualScoreEntryScreen> {
  late RoundData _round;
  final _controller = ManualScoreController();
  final _noteController = TextEditingController();
  String? _ballId;
  String? _alleyId;

  @override
  void initState() {
    super.initState();
    _round = widget.existing ?? RoundData(id: 'round-${DateTime.now().millisecondsSinceEpoch}', source: 'manual');
    _ballId = _round.ballId;
    _alleyId = _round.alleyId;
    _noteController.text = _round.note ?? '';
    if (_round.hasScoreData) {
      _controller.rolls.addAll(BowlingScoring.expandRolls(_round));
    }
    _syncRound();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _syncRound() {
    _round.clearThrows();
    if (_controller.rolls.isNotEmpty) {
      applyPinRollsToRound(_round, List.from(_controller.rolls));
    }
  }

  void _onPin(int pins) {
    setState(() {
      _controller.add(pins);
      _syncRound();
    });
  }

  void _undo() {
    setState(() {
      _controller.undo();
      _syncRound();
    });
  }

  void _save() {
    if (!_round.hasScoreData) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('1投以上入力してください')));
      return;
    }
    _round.ballId = _ballId;
    _round.alleyId = _alleyId;
    _round.note = _noteController.text.trim().isEmpty ? null : _noteController.text.trim();
    _round.source = 'manual';
    Navigator.of(context).pop(_round);
  }

  @override
  Widget build(BuildContext context) {
    final repo = BowlingRepository.instance;
    final scheme = Theme.of(context).colorScheme;
    final maxPin = _controller.maxPinsForNextRoll;

    return Scaffold(
      appBar: AppBar(
        title: const Text('スコア入力'),
        actions: [TextButton(onPressed: _save, child: const Text('保存'))],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String?>(
                  value: _ballId,
                  decoration: const InputDecoration(labelText: 'ボール', border: OutlineInputBorder()),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('未選択')),
                    ...repo.balls.map((b) => DropdownMenuItem(value: b.id, child: Text(b.name))),
                  ],
                  onChanged: (v) => setState(() => _ballId = v),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String?>(
                  value: _alleyId,
                  decoration: const InputDecoration(labelText: 'ボウリング場', border: OutlineInputBorder()),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('未選択')),
                    ...repo.alleys.map((a) => DropdownMenuItem(value: a.id, child: Text(a.name))),
                  ],
                  onChanged: (v) => setState(() => _alleyId = v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _noteController,
            decoration: const InputDecoration(labelText: 'メモ', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          if (_round.hasScoreData) BowlingScoreSheet(round: _round, showImage: false),
          const SizedBox(height: 16),
          Text(
            'フレーム ${_controller.currentFrame} · 次は0〜$maxPin本',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var p = 0; p <= 9; p++)
                _PinButton(
                  label: p == 0 ? '−' : '$p',
                  enabled: _controller.canAdd(p),
                  onTap: () => _onPin(p),
                ),
              _PinButton(
                label: 'X',
                enabled: _controller.canAdd(10),
                accent: Colors.deepOrange,
                onTap: () => _onPin(10),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              OutlinedButton.icon(onPressed: _controller.rolls.isEmpty ? null : _undo, icon: const Icon(Icons.undo), label: const Text('戻す')),
              const Spacer(),
              if (_controller.isComplete)
                Chip(label: const Text('ゲーム完了'), backgroundColor: scheme.primaryContainer),
            ],
          ),
        ],
      ),
    );
  }
}

class _PinButton extends StatelessWidget {
  const _PinButton({required this.label, required this.enabled, required this.onTap, this.accent});

  final String label;
  final bool enabled;
  final VoidCallback onTap;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      height: 52,
      child: FilledButton(
        onPressed: enabled ? onTap : null,
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          padding: EdgeInsets.zero,
        ),
        child: Text(label, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
