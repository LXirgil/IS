import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'FirstPage.dart';

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int total = 0;
  int textCount = 0;
  int imageCount = 0;
  int audioCount = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<File> _ideasFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/ideas.json');
  }

  Future<void> _loadStats() async {
    try {
      final f = await _ideasFile();
      if (!await f.exists()) {
        setState(() {
          total = 0;
          textCount = 0;
          imageCount = 0;
          audioCount = 0;
        });
        return;
      }
      final s = await f.readAsString();
      final List<dynamic> arr = json.decode(s);
      int t = 0, a = 0, i = 0, tot = 0;
      for (final e in arr) {
        tot++;
        final m = Map<String, dynamic>.from(e);
        final type = (m['type'] ?? '').toString();
        if (type == 'テキスト') t++;
        if (type == '画像') i++;
        if (type == '音声') a++;
      }
      setState(() {
        total = tot;
        textCount = t;
        imageCount = i;
        audioCount = a;
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ホーム')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _statColumn('合計', total.toString()),
                    _statColumn('テキスト', textCount.toString()),
                    _statColumn('画像', imageCount.toString()),
                    _statColumn('音声', audioCount.toString()),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (c) => FirstPage()));
                // 戻ったら再読み込み
                _loadStats();
              },
              icon: const Icon(Icons.list),
              label: const Text('FirstPage（新規作成）へ'),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _loadStats,
              icon: const Icon(Icons.refresh),
              label: const Text('統計を更新'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statColumn(String label, String value) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), const SizedBox(height: 4), Text(label)],
      );
}