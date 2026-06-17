import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  final FocusNode _keyboardFocus = FocusNode();
  final List<String> _inputLog = [];

  void _addLog(String entry) {
    setState(() {
      _inputLog.insert(0, entry);
      if (_inputLog.length > 8) _inputLog.removeLast();
    });
  }

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) FocusScope.of(context).requestFocus(_keyboardFocus);
    });
  }

  @override
  void dispose() {
    _noteController.dispose();
    _keyboardFocus.dispose();
    super.dispose();
  }

  void _handleKey(RawKeyEvent ev) {
    if (ev is! RawKeyDownEvent) return;
    final key = ev.logicalKey.keyLabel;
    if (key.isEmpty) {
      // handle special keys
      if (ev.logicalKey == LogicalKeyboardKey.backspace) {
        _addLog('Backspace');
        _undo();
      }
      return;
    }
    final k = key.toLowerCase();
    if (k == 'x') {
      _addLog('X');
      if (_controller.canAdd(10)) _onPin(10);
      return;
    }
    // treat '-' or '_' as 0 (miss)
    if (k == '-' || k == '−' || k == '_') {
      _addLog('-');
      if (_controller.canAdd(0)) _onPin(0);
      return;
    }
    // digits
    final d = int.tryParse(k);
    if (d != null) {
      _addLog('$d');
      if (_controller.canAdd(d)) _onPin(d);
      return;
    }
    // backspace
    if (ev.logicalKey == LogicalKeyboardKey.backspace) {
      _addLog('Backspace');
      _undo();
    }

    // Enter -> save
    if (ev.logicalKey == LogicalKeyboardKey.enter || ev.logicalKey == LogicalKeyboardKey.numpadEnter) {
      _addLog('Enter (保存)');
      if (_round.hasScoreData) _save();
    }
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

  Future<void> _save() async {
    if (!_round.hasScoreData) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('1投以上入力してください')));
      return;
    }
    _round.ballId = _ballId;
    _round.alleyId = _alleyId;
    _round.note = _noteController.text.trim().isEmpty ? null : _noteController.text.trim();
    _round.source = 'manual';
    // persist to repository
    final messenger = ScaffoldMessenger.of(context);
    await BowlingRepository.instance.upsertRound(_round);
    if (!mounted) return;
    messenger.showSnackBar(const SnackBar(content: Text('スコアを保存しました')));
    Navigator.of(context).pop(_round);
  }

  @override
  Widget build(BuildContext context) {
    final repo = BowlingRepository.instance;
    final scheme = Theme.of(context).colorScheme;
    final maxPin = _controller.maxPinsForNextRoll;

    final content = ListView(
      padding: const EdgeInsets.all(16),
        children: [
        // key hints and recent input log
        Card(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('キー操作: 0-9=入力 · X=ストライク · -=ミス · Backspace=戻す · Enter=保存', style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  children: _inputLog.isEmpty
                      ? [const Text('操作ログなし', style: TextStyle(fontSize: 12, color: Colors.grey))]
                      : _inputLog.map((e) => Chip(label: Text(e))).toList(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String?>(
                initialValue: _ballId,
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
                initialValue: _alleyId,
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
              FilledButton(
                onPressed: _save,
                style: FilledButton.styleFrom(backgroundColor: scheme.primaryContainer),
                child: const Text('ゲーム完了'),
              ),
          ],
        ),
      ],
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('スコア入力'),
        actions: [TextButton(onPressed: _save, child: const Text('保存'))],
      ),
      body: RawKeyboardListener(
        focusNode: _keyboardFocus,
        onKey: _handleKey,
        child: content,
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
