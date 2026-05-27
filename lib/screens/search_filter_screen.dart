import 'package:flutter/material.dart';

import '../data/bowling_repository.dart';
import '../models/bowling_meta.dart';

class SearchFilterScreen extends StatefulWidget {
  const SearchFilterScreen({super.key, required this.initial});

  final GameSearchFilter initial;

  @override
  State<SearchFilterScreen> createState() => _SearchFilterScreenState();
}

class _SearchFilterScreenState extends State<SearchFilterScreen> {
  late StatsPeriod _period;
  String? _ballId;
  String? _alleyId;
  final _minController = TextEditingController();
  final _maxController = TextEditingController();
  bool _strikesHeavy = false;

  @override
  void initState() {
    super.initState();
    _period = widget.initial.period;
    _ballId = widget.initial.ballId;
    _alleyId = widget.initial.alleyId;
    _strikesHeavy = widget.initial.onlyStrikesHeavy;
    if (widget.initial.minScore != null) _minController.text = '${widget.initial.minScore}';
    if (widget.initial.maxScore != null) _maxController.text = '${widget.initial.maxScore}';
  }

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  void _apply() {
    Navigator.pop(
      context,
      GameSearchFilter(
        period: _period,
        ballId: _ballId,
        alleyId: _alleyId,
        minScore: int.tryParse(_minController.text),
        maxScore: int.tryParse(_maxController.text),
        onlyStrikesHeavy: _strikesHeavy,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = BowlingRepository.instance;
    return Scaffold(
      appBar: AppBar(
        title: const Text('条件で検索・分析'),
        actions: [TextButton(onPressed: _apply, child: const Text('適用'))],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('期間', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: StatsPeriod.values
                .map(
                  (p) => ChoiceChip(
                    label: Text(p.label),
                    selected: _period == p,
                    onSelected: (_) => setState(() => _period = p),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<String?>(
            initialValue: _ballId,
            decoration: const InputDecoration(labelText: 'ボール', border: OutlineInputBorder()),
            items: [
              const DropdownMenuItem(value: null, child: Text('すべて')),
              ...repo.balls.map((b) => DropdownMenuItem(value: b.id, child: Text(b.name))),
            ],
            onChanged: (v) => setState(() => _ballId = v),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String?>(
            initialValue: _alleyId,
            decoration: const InputDecoration(labelText: 'ボウリング場', border: OutlineInputBorder()),
            items: [
              const DropdownMenuItem(value: null, child: Text('すべて')),
              ...repo.alleys.map((a) => DropdownMenuItem(value: a.id, child: Text(a.name))),
            ],
            onChanged: (v) => setState(() => _alleyId = v),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _minController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: '最低スコア', border: OutlineInputBorder()),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _maxController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: '最高スコア', border: OutlineInputBorder()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            title: const Text('ストライク率30%以上のゲームのみ'),
            value: _strikesHeavy,
            onChanged: (v) => setState(() => _strikesHeavy = v),
          ),
        ],
      ),
    );
  }
}
