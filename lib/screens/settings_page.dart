import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';

import '../data/bowling_repository.dart';
import '../services/share_service.dart';
import '../services/settings_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

enum _ExportDestination { downloads, documents, custom }

class _SettingsPageState extends State<SettingsPage> {
  final _fileNameController = TextEditingController(text: 'AI_Bowling_export_{ts}.json');
  _ExportDestination _destination = _ExportDestination.downloads;
  String? _customDir;
  bool _trackingEnabled = true;

  @override
  void dispose() {
    _fileNameController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    SettingsService.instance.init().then((_) {
      setState(() {
        _trackingEnabled = SettingsService.instance.trackingEnabled.value;
      });
      SettingsService.instance.trackingEnabled.addListener(() {
        if (mounted) setState(() => _trackingEnabled = SettingsService.instance.trackingEnabled.value);
      });
    });
  }

  Future<String> _resolveDestinationPath() async {
    if (_destination == _ExportDestination.documents) {
      final doc = await getApplicationDocumentsDirectory();
      return doc.path;
    }
    if (_destination == _ExportDestination.custom) {
      return _customDir ?? (await getApplicationDocumentsDirectory()).path;
    }
    // downloads
    if (Platform.isWindows) {
      final env = Platform.environment['USERPROFILE'];
      if (env != null) return '$env\\Downloads';
    }
    // fallback to documents
    final doc = await getApplicationDocumentsDirectory();
    return doc.path;
  }

  String _applyTemplate(String template) {
    final now = DateTime.now();
    final ts = '${now.year.toString().padLeft(4, '0')}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
    return template.replaceAll('{ts}', ts);
  }

  Future<void> _pickCustomDir() async {
    final dir = await FilePicker.platform.getDirectoryPath();
    if (dir != null) setState(() => _customDir = dir);
  }

  Future<void> _exportAndShare() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final json = BowlingRepository.instance.exportJson();
      final fileName = _applyTemplate(_fileNameController.text.trim());
      final destDir = await _resolveDestinationPath();
      final destFile = File('$destDir\\$fileName');
      await destFile.create(recursive: true);
      await destFile.writeAsString(json);

      // also write a temp copy in app documents for sharing
      final tmp = await getApplicationDocumentsDirectory();
      final tmpFile = File('${tmp.path}\\$fileName');
      await tmpFile.writeAsString(json);

      // Use ShareService to ensure file attachment across platforms
      await ShareService.instance.shareBackupFile();

      messenger.showSnackBar(SnackBar(content: Text('エクスポート完了: ${destFile.path}')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('エクスポートに失敗しました: $e')));
    }
  }

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
              subtitle: const Text('AI Bowling Master'),
            ),
            const Divider(),
            const SizedBox(height: 8),
            const Text('エクスポート設定', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _fileNameController,
              decoration: const InputDecoration(labelText: 'ファイル名テンプレート', hintText: '例: AI_Bowling_export_{ts}.json'),
            ),
            const SizedBox(height: 12),
            Column(
              children: [
                RadioListTile<_ExportDestination>(
                  title: const Text('Downloads フォルダ'),
                  value: _ExportDestination.downloads,
                  groupValue: _destination,
                  onChanged: (v) => setState(() => _destination = v ?? _destination),
                ),
                RadioListTile<_ExportDestination>(
                  title: const Text('アプリドキュメント'),
                  value: _ExportDestination.documents,
                  groupValue: _destination,
                  onChanged: (v) => setState(() => _destination = v ?? _destination),
                ),
                RadioListTile<_ExportDestination>(
                  title: const Text('カスタムフォルダ'),
                  subtitle: Text(_customDir ?? '未選択'),
                  value: _ExportDestination.custom,
                  groupValue: _destination,
                  onChanged: (v) => setState(() => _destination = v ?? _destination),
                  secondary: IconButton(
                    icon: const Icon(Icons.folder_open),
                    onPressed: _pickCustomDir,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('位置追跡を有効にする'),
              subtitle: const Text('地図で現在地を継続的に追跡します（バッテリー注意）'),
              value: _trackingEnabled,
              onChanged: (v) async {
                await SettingsService.instance.setTrackingEnabled(v);
              },
              secondary: const Icon(Icons.my_location),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _exportAndShare,
              icon: const Icon(Icons.download),
              label: const Text('エクスポートして共有'),
            ),
          ],
        ),
      ),
    );
  }
}
