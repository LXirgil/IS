import 'dart:convert';
import 'dart:io';

import 'package:share_plus/share_plus.dart';
import 'package:cross_file/cross_file.dart';
import 'package:path_provider/path_provider.dart';

import '../data/bowling_repository.dart';
import '../models/bowling.dart';

class ShareService {
  ShareService._();
  static final instance = ShareService._();

  Future<void> shareGameSummary(RoundData round) async {
    final repo = BowlingRepository.instance;
    final ball = repo.ballById(round.ballId);
    final alley = repo.alleyById(round.alleyId);
    final total = BowlingScoring.totalScore(round);
    final strikes = round.frames.where((f) => f.isStrike).length;
    final spares = round.frames.where((f) => f.isSpare).length;

    final buf = StringBuffer();
    buf.writeln('🎳 ボウリングスコア');
    buf.writeln('日時: ${round.date.toLocal()}');
    if (total != null) buf.writeln('スコア: $total');
    buf.writeln('ストライク: $strikes / スペア: $spares');
    if (ball != null) buf.writeln('ボール: ${ball.name}');
    if (alley != null) buf.writeln('場所: ${alley.name}');
    if (round.note != null && round.note!.isNotEmpty) buf.writeln('メモ: ${round.note}');
    buf.writeln('\n— AI ボウリングマスター');

    await Share.share(buf.toString());
  }

  Future<void> shareBackupJson() async {
    final json = BowlingRepository.instance.exportJson();
    await Share.share(json, subject: 'ボウリングデータバックアップ');
  }

  Future<void> shareBackupFile() async {
    final json = BowlingRepository.instance.exportJson();
    final dir = await getApplicationDocumentsDirectory();
    final now = DateTime.now();
    final ts = '${now.year}${now.month.toString().padLeft(2,'0')}${now.day.toString().padLeft(2,'0')}_${now.hour.toString().padLeft(2,'0')}${now.minute.toString().padLeft(2,'0')}';
    final file = File('${dir.path}/ai_bowling_backup_$ts.json');
    await file.writeAsString(json);
    final xfile = XFile(file.path);
    await Share.shareXFiles([xfile], text: 'AI Bowling Master データバックアップ');
  }

  Future<void> shareRoundAsFile(RoundData round) async {
    final json = jsonEncode(round.toJson());
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/round_${round.id}.json');
    await file.writeAsString(json);
    final xfile = XFile(file.path);
    await Share.shareXFiles([xfile], text: 'ゲームデータ共有');
  }
}
