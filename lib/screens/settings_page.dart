import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('表示設定', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.palette),
              title: const Text('テーマ（ダミー）'),
              subtitle: const Text('ダーク／ライト切替はここに実装できます'),
              onTap: () {},
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('アプリ情報'),
              subtitle: const Text('IdeaStream サンプル'),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text('データをエクスポート'),
              subtitle: const Text('ideas.json をダウンロードフォルダへコピーします'),
              onTap: () async {
                final messenger = ScaffoldMessenger.of(context);
                try {
                  final doc = await getApplicationDocumentsDirectory();
                  final src = File('${doc.path}/ideas.json');
                  if (!await src.exists()) {
                    messenger.showSnackBar(const SnackBar(content: Text('エクスポート用のデータが見つかりません')));
                    return;
                  }
                  final downloads = Directory('${Platform.environment['USERPROFILE']}\\Downloads');
                  final now = DateTime.now();
                  final ts = '${now.year.toString().padLeft(4,'0')}${now.month.toString().padLeft(2,'0')}${now.day.toString().padLeft(2,'0')}_${now.hour.toString().padLeft(2,'0')}${now.minute.toString().padLeft(2,'0')}${now.second.toString().padLeft(2,'0')}';
                  final dest = File('${downloads.path}\\IdeaStream_export_$ts.json');
                  await src.copy(dest.path);
                  messenger.showSnackBar(SnackBar(content: Text('エクスポート完了: ${dest.path}')));
                } catch (e) {
                  messenger.showSnackBar(SnackBar(content: Text('エクスポートに失敗しました: $e')));
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
