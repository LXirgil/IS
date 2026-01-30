import 'package:flutter/material.dart';

class ComposeIdeaPage extends StatefulWidget {
  final String? initialTitle;
  final String? initialBody;

  const ComposeIdeaPage({Key? key, this.initialTitle, this.initialBody}) : super(key: key);

  @override
  State<ComposeIdeaPage> createState() => _ComposeIdeaPageState();
}

class _ComposeIdeaPageState extends State<ComposeIdeaPage> {
  late final TextEditingController titleCtrl;
  late final TextEditingController bodyCtrl;

  @override
  @override
  void initState() {
    super.initState();
    titleCtrl = TextEditingController(text: widget.initialTitle ?? '');
    bodyCtrl = TextEditingController(text: widget.initialBody ?? '');
  }

  @override
  void dispose() {
    titleCtrl.dispose();
    bodyCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final title = titleCtrl.text.trim();
    final body = bodyCtrl.text.trim();
    if (title.isEmpty && body.isEmpty) return;
    final res = {
      'title': title.isEmpty ? (body.length > 20 ? '${body.substring(0,20)}…' : body) : title,
      'body': body,
      'type': 'テキスト',
      'tags': <String>[],
      'imagePath': null,
      'audioPath': null,
    };
    Navigator.of(context).pop(res);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('アイデア作成')),
      // 中央に小さめのカードで表示することで「大きすぎる」印象を緩和
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700, maxHeight: 700),
          child: Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'タイトル（任意）')),
                  const SizedBox(height: 8),
                  // 本文は固定高さのテキストエリアにして全画面占有を防ぐ
                  SizedBox(
                    height: 300,
                    child: TextField(controller: bodyCtrl, maxLines: null, expands: true, decoration: const InputDecoration(labelText: '詳細')),
                  ),
                  const SizedBox(height: 12),
                  Row(mainAxisAlignment: MainAxisAlignment.end, children: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('キャンセル')), const SizedBox(width: 8), ElevatedButton(onPressed: _save, child: const Text('保存'))]),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
