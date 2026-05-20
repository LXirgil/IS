import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/bowling_repository.dart';
import '../../services/bowling_coach.dart';
import '../../services/share_service.dart';
import '../alleys_map_screen.dart';
import '../alleys_screen.dart';
import '../league_screen.dart';

class MoreTab extends StatelessWidget {
  const MoreTab({super.key, required this.onRefresh});

  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final repo = BowlingRepository.instance;
    final report = BowlingCoach.instance.analyze(repo.rounds.where((r) => r.hasScoreData).toList());

    return Scaffold(
      appBar: AppBar(title: const Text('その他')),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          _SectionHeader(title: 'プレー環境'),
          ListTile(
            leading: const Icon(Icons.map_outlined),
            title: const Text('近くのボウリング場（地図）'),
            subtitle: const Text('現在地から周辺を検索'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              await Navigator.of(context).push(MaterialPageRoute(builder: (_) => AlleysMapScreen(onChanged: onRefresh)));
              onRefresh();
            },
          ),
          ListTile(
            leading: const Icon(Icons.place_outlined),
            title: const Text('ボウリング場リスト'),
            subtitle: Text('${repo.alleys.length} 件登録'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              await Navigator.of(context).push(MaterialPageRoute(builder: (_) => AlleysScreen(onChanged: onRefresh)));
              onRefresh();
            },
          ),
          ListTile(
            leading: const Icon(Icons.groups_outlined),
            title: const Text('リーグ'),
            subtitle: Text('${repo.leagues.length} 件'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              await Navigator.of(context).push(MaterialPageRoute(builder: (_) => LeagueScreen(onChanged: onRefresh)));
              onRefresh();
            },
          ),
          const Divider(),
          _SectionHeader(title: 'データ'),
          ListTile(
            leading: const Icon(Icons.cloud_upload_outlined),
            title: const Text('バックアップを共有'),
            subtitle: const Text('JSON形式でエクスポート'),
            onTap: () => ShareService.instance.shareBackupJson(),
          ),
          ListTile(
            leading: const Icon(Icons.file_download_outlined),
            title: const Text('バックアップを復元'),
            subtitle: const Text('JSONファイルを読み込み'),
            onTap: () async {
              final picked = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['json', 'txt']);
              if (picked?.files.single.path == null) return;
              final raw = await File(picked!.files.single.path!).readAsString();
              if (raw == null) return;
              final merge = await showDialog<bool>(
                context: context,
                builder: (c) => AlertDialog(
                  title: const Text('復元方法'),
                  content: const Text('既存データに追加しますか？上書きしますか？'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('追加')),
                    FilledButton(onPressed: () => Navigator.pop(c, false), child: const Text('上書き')),
                  ],
                ),
              );
              if (merge == null) return;
              await repo.importJson(raw, merge: merge);
              onRefresh();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('復元しました')));
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.copy_outlined),
            title: const Text('クリップボードにコピー'),
            onTap: () async {
              await Clipboard.setData(ClipboardData(text: repo.exportJson()));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('コピーしました')));
              }
            },
          ),
          const Divider(),
          _SectionHeader(title: 'AIコーチ'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Text(report.summary),
              ),
            ),
          ),
          ...report.focusAreas.take(3).map(
                (t) => ListTile(dense: true, leading: const Icon(Icons.flag_outlined, size: 20), title: Text(t)),
              ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Text(title, style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
    );
  }
}
