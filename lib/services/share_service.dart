import 'package:share_plus/share_plus.dart';

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
}
