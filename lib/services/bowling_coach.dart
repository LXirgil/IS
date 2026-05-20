import '../models/bowling.dart';

/// 集計データに基づくルールベースのコーチング（外部APIなしで即時フィードバック）
class BowlingCoachReport {
  BowlingCoachReport({
    required this.summary,
    required this.focusAreas,
    required this.drills,
    required this.metricsSnapshot,
  });

  final String summary;
  final List<String> focusAreas;
  final List<String> drills;
  final Map<String, String> metricsSnapshot;
}

class BowlingCoach {
  BowlingCoach._();
  static final instance = BowlingCoach._();

  BowlingCoachReport analyze(List<RoundData> rounds) {
    if (rounds.isEmpty) {
      return BowlingCoachReport(
        summary: 'まだゲームデータがありません。ラウンドを追加して投球を記録すると、ここにパーソナライズされた分析が表示されます。',
        focusAreas: const ['データ収集'],
        drills: const ['まずは安定した4ステップアプローチでレーン中央を狙う練習から'],
        metricsSnapshot: const {},
      );
    }

    final avg = BowlingStats.averageScore(rounds);
    final strike = BowlingStats.strikeRate(rounds);
    final spare = BowlingStats.spareRate(rounds);
    final spareConv = BowlingStats.spareConversionRate(rounds);
    final gutter = BowlingStats.gutterRate(rounds);
    final pinLeaves = BowlingStats.pinLeaveCounts(rounds);
    final topPin = _topPinLeaves(pinLeaves);

    final focus = <String>[];
    final drills = <String>[];

    if (gutter > 0.08) {
      focus.add('ガターが目立ちます — リリースの安定とターゲットの固定');
      drills.add('フットワークを短くし、同じターゲット矢印に3回連続で投げるリズム練習');
    }
    if (strike < 0.15 && gutter <= 0.08) {
      focus.add('ストライク率が低め — ポケット精度とスピードのバランス');
      drills.add('同じレーンでボールを1ターゲットに寄せ、曲がり始め（ブレークポイント）を観察する');
    }
    if (spareConv < 0.45) {
      focus.add('スペア変換率に伸びしろ — スペアボールの直進性');
      drills.add('7番・10番ピンだけを10本ずつ、ストライク球ではなく直進寄りの球で狙い分ける');
    }
    if (topPin.contains(10)) {
      focus.add('10番ピン残りが多い — 軽い当たり／エネルギー不足の可能性');
      drills.add('スライドを抑え、少し低めのリリースで回転を落とさずに送る');
    }
    if (topPin.contains(7) && !topPin.contains(10)) {
      focus.add('7番ピン残り — 早すぎるフック／高めリリースの傾向');
      drills.add('リリースポイントをレーン側に1cmずつ調整し、曲がり量の変化を確認する');
    }
    if (strike > 0.35 && spareConv < 0.5) {
      focus.add('攻めの球は良い一方、ピンアクション後の拾いが課題');
      drills.add('スペア用ボールの軸を決め、レーン上でスペア練習のみのセットを組む');
    }
    if (focus.isEmpty) {
      focus.add('全体バランス良好 — 微調整で上限を上げるフェーズ');
      drills.add('スコア帳をつけ、フレーム別に「狙い」「結果」「体感」を一行メモする');
    }

    final summary = _buildSummary(avg, strike, spare, gutter, spareConv, topPin);

    return BowlingCoachReport(
      summary: summary,
      focusAreas: focus.toSet().toList(),
      drills: drills.toSet().toList(),
      metricsSnapshot: {
        '平均スコア': avg.toStringAsFixed(1),
        'ストライク率': '${(strike * 100).toStringAsFixed(1)}%',
        'スペア率（フレーム比）': '${(spare * 100).toStringAsFixed(1)}%',
        'スペア成功率': '${(spareConv * 100).toStringAsFixed(1)}%',
        'ガター率': '${(gutter * 100).toStringAsFixed(1)}%',
        '残りやすいピン': topPin.isEmpty ? '—' : topPin.join(', '),
      },
    );
  }

  List<int> _topPinLeaves(Map<int, int> counts) {
    final entries = counts.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.take(3).map((e) => e.key).toList();
  }

  String _buildSummary(
    double avg,
    double strike,
    double spare,
    double gutter,
    double spareConv,
    List<int> topPin,
  ) {
    final buf = StringBuffer();
    buf.write('直近のデータから、あなたのプレーは平均 ${avg.toStringAsFixed(1)} 点帯です。');
    buf.write(' ストライク率は ${(strike * 100).toStringAsFixed(0)}%、');
    buf.write('スペア成功率は ${(spareConv * 100).toStringAsFixed(0)}%、');
    buf.write('ガター率は ${(gutter * 100).toStringAsFixed(1)}% です。');
    if (topPin.isNotEmpty) {
      buf.write(' 特に ${topPin.join('・')} 番ピンが残りやすい傾向があります。');
    } else {
      buf.write(' ピン残りの偏りはまだ小さめです。');
    }
    if (spare > strike && spareConv > 0.55) {
      buf.write(' スペア処理が安定しており、連続マークを意識するとスコアが伸びやすいタイプです。');
    }
    return buf.toString();
  }
}
