import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../data/store.dart';
import '../models/note.dart';
import '../services/ai_service.dart';

class ComposePage extends StatefulWidget {
  const ComposePage({Key? key}) : super(key: key);

  @override
  State<ComposePage> createState() => _ComposePageState();
}

class _ComposePageState extends State<ComposePage> {
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  bool _hasImage = false;
  bool _hasAudio = false;

  void _save() {
    final id = const Uuid().v4();
    // generateTags は非同期になったため同期の既存呼び出しに合わせ、ここでは同期的に簡易生成
    // 実際の保存時にはすでに UI 側でタグを取得しているためここでは _suggestedTags を使う
    final tags = _suggestedTags.isNotEmpty ? _suggestedTags : ['メモ'];
    final note = Note(
      id: id,
      title: _titleCtrl.text,
      body: _bodyCtrl.text,
      hasImage: _hasImage,
      hasAudio: _hasAudio,
      tags: tags,
    );
    Store.instance.addNote(note);
    Navigator.of(context).pop(true);
  }

  List<String> _suggestedTags = [];
  bool _isAiRunning = false;

  Future<void> _runAiSummarize() async {
    final input = '${_titleCtrl.text}\n${_bodyCtrl.text}';
    setState(() => _isAiRunning = true);
    final summary = await AiService.instance.summarize(input);
    final tags = await Store.instance.generateTags(input);
    setState(() {
      if (summary.isNotEmpty) _bodyCtrl.text = summary + '\n\n' + _bodyCtrl.text;
      _suggestedTags = tags;
      _isAiRunning = false;
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('メモを追加')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(labelText: 'タイトル（任意）'),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: TextField(
                controller: _bodyCtrl,
                decoration: const InputDecoration(labelText: '内容を入力／音声の要約や写真説明でもOK'),
                maxLines: null,
                expands: true,
              ),
            ),
            Row(
              children: [
                Checkbox(
                  value: _hasImage,
                  onChanged: (v) => setState(() => _hasImage = v ?? false),
                ),
                const Text('写真を添付（デモ）'),
                const SizedBox(width: 12),
                Checkbox(
                  value: _hasAudio,
                  onChanged: (v) => setState(() => _hasAudio = v ?? false),
                ),
                const Text('音声メモ（デモ）'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _isAiRunning ? null : _runAiSummarize,
                  icon: const Icon(Icons.auto_awesome),
                  label: _isAiRunning ? const Text('AIで解析中…') : const Text('AIで要約・タグ生成'),
                ),
                const SizedBox(width: 12),
                if (_suggestedTags.isNotEmpty)
                  Expanded(
                    child: Wrap(
                      spacing: 6,
                      children: _suggestedTags.map((t) => Chip(label: Text('#$t'))).toList(),
                    ),
                  ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('キャンセル')),
                ElevatedButton(onPressed: _save, child: const Text('保存')),
              ],
            )
          ],
        ),
      ),
    );
  }
}
