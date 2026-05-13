import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'ThirdPage.dart';

class SecondPage extends StatefulWidget {
  const SecondPage({super.key});
  @override
  State<SecondPage> createState() => _SecondPageState();
}

class _SecondPageState extends State<SecondPage> {
  List<String> tags = [];

  @override
  void initState() {
    super.initState();
    _loadTags();
  }

  Future<File> _ideasFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/ideas.json');
  }

  Future<void> _loadTags() async {
    try {
      final f = await _ideasFile();
      if (!await f.exists()) {
        setState(() => tags = []);
        return;
      }
      final s = await f.readAsString();
      final List<dynamic> arr = json.decode(s);
      final Set<String> st = {};
      for (final e in arr) {
        final m = Map<String, dynamic>.from(e);
        final tlist = List<String>.from(m['tags'] ?? []);
        for (final t in tlist) {
          st.add(t);
        }
      }
      setState(() => tags = st.toList()..sort());
    } catch (_) {}
  }

  Future<void> _exportTags() async {
    try {
      final messenger = ScaffoldMessenger.of(context);
      final dir = await getApplicationDocumentsDirectory();
      final out = File('${dir.path}/tags_${DateTime.now().millisecondsSinceEpoch}.txt');
      await out.writeAsString(tags.join('\n'));
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('タグを ${out.path} にエクスポートしました')));
    } catch (_) {
      final messenger = ScaffoldMessenger.of(context);
      if (!mounted) return;
      messenger.showSnackBar(const SnackBar(content: Text('エクスポートに失敗しました')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('タグ一覧 (SecondPage)')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            ElevatedButton.icon(onPressed: _loadTags, icon: const Icon(Icons.refresh), label: const Text('タグを更新')),
            const SizedBox(height: 8),
            Expanded(
              child: tags.isEmpty
                  ? const Center(child: Text('タグが見つかりません'))
                  : ListView.separated(
                      itemCount: tags.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, index) => ListTile(
                        title: Text(tags[index]),
                        leading: const Icon(Icons.label_outline),
                      ),
                    ),
            ),
            ElevatedButton.icon(onPressed: _exportTags, icon: const Icon(Icons.upload_file), label: const Text('タグをテキストでエクスポート')),
            const SizedBox(height: 8),
            ElevatedButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => ThirdPage())), icon: const Icon(Icons.navigate_next), label: const Text('ThirdPageへ')),
          ],
        ),
      ),
    );
  }
}