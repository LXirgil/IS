import 'dart:convert';
import 'dart:math';

class ThrowData {
  final int pinsKnocked; // 0..10
  final List<int> pinsLeft; // remaining pin numbers after the throw (1..10)
  final DateTime timestamp;
  final String? videoPath;

  ThrowData({
    required this.pinsKnocked,
    required this.pinsLeft,
    DateTime? timestamp,
    this.videoPath,
  }) : timestamp = timestamp ?? DateTime.now();

  bool get isGutter => pinsKnocked == 0;

  Map<String, dynamic> toJson() => {
        'pinsKnocked': pinsKnocked,
        'pinsLeft': pinsLeft,
        'timestamp': timestamp.toIso8601String(),
        'videoPath': videoPath,
      };

  factory ThrowData.fromJson(Map<String, dynamic> j) => ThrowData(
        pinsKnocked: j['pinsKnocked'] as int,
        pinsLeft: List<int>.from(j['pinsLeft'] ?? []),
        timestamp: DateTime.parse(j['timestamp'] as String),
        videoPath: j['videoPath'] as String?,
      );
}

class FrameData {
  final int frameNumber; // 1..10
  final List<ThrowData> throws;

  FrameData({required this.frameNumber, List<ThrowData>? throws})
      : throws = throws ?? [];

  bool get isStrike => throws.isNotEmpty && throws.first.pinsKnocked == 10;
  bool get isSpare => !isStrike && totalPinsKnocked == 10 && throws.length >= 2;
  bool get isOpen => hasScore && !isStrike && !isSpare;
  bool get hasScore => throws.isNotEmpty;
  int get totalPinsKnocked => throws.fold(0, (s, t) => s + t.pinsKnocked);

  Map<String, dynamic> toJson() => {
        'frameNumber': frameNumber,
        'throws': throws.map((t) => t.toJson()).toList(),
      };

  factory FrameData.fromJson(Map<String, dynamic> j) => FrameData(
        frameNumber: j['frameNumber'] as int,
        throws: (j['throws'] as List<dynamic>?)
                ?.map((e) => ThrowData.fromJson(Map<String, dynamic>.from(e)))
                .toList() ??
            [],
      );
}

class RoundData {
  final String id;
  final DateTime date;
  final List<FrameData> frames;
  String? scoreSheetImagePath;
  String? ocrRawText;
  double? scanConfidence;
  String? ballId;
  String? alleyId;
  String? leagueId;
  String? note;
  /// manual | scan
  String source;

  RoundData({
    required this.id,
    DateTime? date,
    List<FrameData>? frames,
    this.scoreSheetImagePath,
    this.ocrRawText,
    this.scanConfidence,
    this.ballId,
    this.alleyId,
    this.leagueId,
    this.note,
    this.source = 'manual',
  })  : date = date ?? DateTime.now(),
        frames = frames ?? List.generate(10, (i) => FrameData(frameNumber: i + 1));

  String get displayLabel {
    final d = '${date.month}/${date.day} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    return hasScoreData ? '$d · ${_shortTotal()}' : d;
  }

  bool get hasScoreData => frames.any((f) => f.throws.isNotEmpty);

  String _shortTotal() {
    final t = BowlingScoring.totalScore(this);
    if (t != null) return '$t点';
    return '${BowlingScoring.rawPinTotal(this)}本';
  }

  void clearThrows() {
    for (final f in frames) {
      f.throws.clear();
    }
  }

  int? get totalScore => BowlingScoring.totalScore(this);

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'frames': frames.map((f) => f.toJson()).toList(),
        'scoreSheetImagePath': scoreSheetImagePath,
        'ocrRawText': ocrRawText,
        'scanConfidence': scanConfidence,
        'ballId': ballId,
        'alleyId': alleyId,
        'leagueId': leagueId,
        'note': note,
        'source': source,
      };

  factory RoundData.fromJson(Map<String, dynamic> j) => RoundData(
        id: j['id'] as String,
        date: DateTime.parse(j['date'] as String),
        frames: (j['frames'] as List<dynamic>?)
                ?.map((e) => FrameData.fromJson(Map<String, dynamic>.from(e)))
                .toList() ??
            List.generate(10, (i) => FrameData(frameNumber: i + 1)),
        scoreSheetImagePath: j['scoreSheetImagePath'] as String?,
        ocrRawText: j['ocrRawText'] as String?,
        scanConfidence: (j['scanConfidence'] as num?)?.toDouble(),
        ballId: j['ballId'] as String?,
        alleyId: j['alleyId'] as String?,
        leagueId: j['leagueId'] as String?,
        note: j['note'] as String?,
        source: j['source'] as String? ?? 'manual',
      );
}

/// OCRテキストや手入力マーク列をフレームデータへ反映
void applyPinRollsToRound(RoundData round, List<int> rolls) {
  round.clearThrows();
  var rollIdx = 0;

  for (var frameNum = 1; frameNum <= 10; frameNum++) {
    final frame = round.frames[frameNum - 1];
    if (rollIdx >= rolls.length) break;

    if (frameNum < 10) {
      final first = rolls[rollIdx++];
      frame.throws.add(_throwFromPins(first));
      if (first < 10) {
        if (rollIdx >= rolls.length) break;
        final second = rolls[rollIdx++];
        final framePins = first + second;
        frame.throws.add(_throwFromPins(second, priorKnocked: first, framePins: framePins));
      }
    } else {
      final a = rolls[rollIdx++];
      frame.throws.add(_throwFromPins(a));
      if (rollIdx >= rolls.length) break;
      final b = rolls[rollIdx++];
      var framePins = a + b;
      frame.throws.add(_throwFromPins(b, priorKnocked: a, framePins: framePins));
      if (a == 10 || a + b == 10) {
        if (rollIdx >= rolls.length) break;
        final c = rolls[rollIdx++];
        framePins += c;
        frame.throws.add(_throwFromPins(c, priorKnocked: framePins - c, framePins: framePins));
      }
    }
  }
}

ThrowData _throwFromPins(int pins, {int priorKnocked = 0, int? framePins}) {
  final knockedInFrame = framePins ?? (priorKnocked + pins);
  final left = pins >= 10 || knockedInFrame >= 10
      ? <int>[]
      : pinsLeftAfterKnockCount(knockedInFrame);
  return ThrowData(pinsKnocked: pins.clamp(0, 10), pinsLeft: left);
}

/// ピン番号（1–10）から残りピン配列を生成（同一フレーム内の簡易モデル用）
List<int> pinsLeftAfterKnockCount(int knockedTotalThisThrow) {
  if (knockedTotalThisThrow >= 10) return <int>[];
  return List<int>.generate(10 - knockedTotalThisThrow, (i) => i + 1);
}

/// ランダムに完成ゲームを埋める（10フレーム目のルール準拠）
void fillRoundRandom(RoundData round, Random rnd) {
  for (var i = 0; i < 9; i++) {
    final f = round.frames[i];
    f.throws.clear();
    final first = rnd.nextInt(11);
    f.throws.add(ThrowData(pinsKnocked: first, pinsLeft: pinsLeftAfterKnockCount(first)));
    if (first < 10) {
      final second = rnd.nextInt(11 - first);
      f.throws.add(ThrowData(pinsKnocked: second, pinsLeft: pinsLeftAfterKnockCount(first + second)));
    }
  }
  final f10 = round.frames[9];
  f10.throws.clear();
  final b1 = rnd.nextInt(11);
  f10.throws.add(ThrowData(pinsKnocked: b1, pinsLeft: pinsLeftAfterKnockCount(b1)));
  if (b1 == 10) {
    final b2 = rnd.nextInt(11);
    f10.throws.add(ThrowData(pinsKnocked: b2, pinsLeft: pinsLeftAfterKnockCount(b2)));
    if (b2 == 10) {
      final b3 = rnd.nextInt(11);
      f10.throws.add(ThrowData(pinsKnocked: b3, pinsLeft: pinsLeftAfterKnockCount(b3)));
    } else {
      final b3 = rnd.nextInt(11 - b2);
      f10.throws.add(ThrowData(pinsKnocked: b3, pinsLeft: pinsLeftAfterKnockCount(b2 + b3)));
    }
  } else {
    final b2 = rnd.nextInt(11 - b1);
    f10.throws.add(ThrowData(pinsKnocked: b2, pinsLeft: pinsLeftAfterKnockCount(b1 + b2)));
    if (b1 + b2 == 10) {
      final b3 = rnd.nextInt(11);
      f10.throws.add(ThrowData(pinsKnocked: b3, pinsLeft: pinsLeftAfterKnockCount(b3)));
    }
  }
}

class BowlingScoring {
  BowlingScoring._();

  /// 投球順に並べたピン数リスト
  static List<int> expandRolls(RoundData r) {
    final out = <int>[];
    for (final f in r.frames) {
      for (final t in f.throws) {
        out.add(t.pinsKnocked);
      }
    }
    return out;
  }

  /// 確定できる分の合計スコア（未終了ゲームは先読み不足分を無視して部分計算しない — null）
  static int? totalScore(RoundData r) {
    final per = runningTotals(r);
    if (per.last == null) return null;
    return per.last;
  }

  /// 各フレーム終了時点の累計（1..10）。未確定は null
  static List<int?> runningTotals(RoundData r) {
    final pins = expandRolls(r);
    final result = List<int?>.filled(10, null);
    var roll = 0;
    var cumulative = 0;

    for (var frame = 0; frame < 9; frame++) {
      if (roll >= pins.length) return result;

      if (pins[roll] == 10) {
        if (roll + 2 >= pins.length) return result;
        cumulative += 10 + pins[roll + 1] + pins[roll + 2];
        result[frame] = cumulative;
        roll += 1;
      } else {
        if (roll + 1 >= pins.length) return result;
        final first = pins[roll];
        final second = pins[roll + 1];
        if (first + second == 10) {
          if (roll + 2 >= pins.length) return result;
          cumulative += 10 + pins[roll + 2];
        } else {
          cumulative += first + second;
        }
        result[frame] = cumulative;
        roll += 2;
      }
    }

    // 10フレーム目: そのフレーム内の倒したピン合計のみ加算
    final f10 = r.frames[9];
    if (f10.throws.isEmpty) return result;
    final need = _tenthFrameRollCount(f10);
    if (pins.length < roll + need) return result;
    var tenthSum = 0;
    for (var k = 0; k < need; k++) {
      tenthSum += pins[roll + k];
    }
    cumulative += tenthSum;
    result[9] = cumulative;
    return result;
  }

  /// 10フレーム目に記録されている投球数がルール上妥当か
  static int _tenthFrameRollCount(FrameData f10) {
    if (f10.throws.isEmpty) return 0;
    final a = f10.throws[0].pinsKnocked;
    if (a == 10) {
      if (f10.throws.length < 2) return 0;
      final b = f10.throws[1].pinsKnocked;
      if (b == 10) return f10.throws.length >= 3 ? 3 : 0;
      if (f10.throws.length < 3) return 0;
      return 3;
    }
    if (f10.throws.length < 2) return 0;
    final b = f10.throws[1].pinsKnocked;
    if (a + b == 10) {
      return f10.throws.length >= 3 ? 3 : 0;
    }
    return 2;
  }

  /// 簡易ピン合計（ボーナスなし）— 入力途中の目安
  static int rawPinTotal(RoundData r) =>
      r.frames.fold(0, (a, f) => a + f.totalPinsKnocked);
}

class BowlingStats {
  static double averageScore(List<RoundData> rounds) {
    if (rounds.isEmpty) return 0.0;
    var sum = 0.0;
    var n = 0;
    for (final r in rounds) {
      final t = BowlingScoring.totalScore(r) ?? BowlingScoring.rawPinTotal(r);
      sum += t;
      n++;
    }
    return sum / n;
  }

  static int? roundTotal(RoundData r) => BowlingScoring.totalScore(r);

  static double strikeRate(List<RoundData> rounds) {
    final stats = _countStrikesAndFrames(rounds);
    if (stats['frames'] == 0) return 0.0;
    return stats['strikes']! / stats['frames']!;
  }

  static double spareRate(List<RoundData> rounds) {
    final stats = _countStrikesAndFrames(rounds);
    if (stats['frames'] == 0) return 0.0;
    return stats['spares']! / stats['frames']!;
  }

  /// スペアチャンス（1投目がストライクでないフレーム）に対するスペア成功率
  static double spareConversionRate(List<RoundData> rounds) {
    var chances = 0;
    var spares = 0;
    for (final r in rounds) {
      for (final f in r.frames) {
        if (f.isStrike) continue;
        chances++;
        if (f.isSpare) spares++;
      }
    }
    if (chances == 0) return 0.0;
    return spares / chances;
  }

  /// 全投球に対するガター（0本）の割合
  static double openFrameRate(List<RoundData> rounds) {
    var open = 0, frames = 0;
    for (final r in rounds) {
      for (final f in r.frames) {
        if (!f.hasScore) continue;
        frames++;
        if (!f.isStrike && !f.isSpare) open++;
      }
    }
    if (frames == 0) return 0.0;
    return open / frames;
  }

  static int? highGame(List<RoundData> rounds) {
    int? hi;
    for (final r in rounds) {
      final t = roundTotal(r);
      if (t == null) continue;
      if (hi == null || t > hi) hi = t;
    }
    return hi;
  }

  static int? lowGame(List<RoundData> rounds) {
    int? lo;
    for (final r in rounds) {
      final t = roundTotal(r);
      if (t == null) continue;
      if (lo == null || t < lo) lo = t;
    }
    return lo;
  }

  static double gutterRate(List<RoundData> rounds) {
    var gutters = 0;
    var balls = 0;
    for (final r in rounds) {
      for (final f in r.frames) {
        for (final t in f.throws) {
          balls++;
          if (t.isGutter) gutters++;
        }
      }
    }
    if (balls == 0) return 0.0;
    return gutters / balls;
  }

  static Map<String, int> _countStrikesAndFrames(List<RoundData> rounds) {
    var strikes = 0, spares = 0, frames = 0;
    for (final r in rounds) {
      for (final f in r.frames) {
        frames++;
        if (f.isStrike) strikes++;
        if (f.isSpare) spares++;
      }
    }
    return {'strikes': strikes, 'spares': spares, 'frames': frames};
  }

  static Map<int, int> pinLeaveCounts(List<RoundData> rounds) {
    final counts = <int, int>{for (var p = 1; p <= 10; p++) p: 0};
    for (final r in rounds) {
      for (final f in r.frames) {
        for (final t in f.throws) {
          for (final pin in t.pinsLeft) {
            counts[pin] = (counts[pin] ?? 0) + 1;
          }
        }
      }
    }
    return counts;
  }

  /// 1投目終了後の残りピン集合（スプリット分析用）
  static Map<String, int> leavePatternCounts(List<RoundData> rounds) {
    final map = <String, int>{};
    for (final r in rounds) {
      for (final f in r.frames) {
        if (f.throws.isEmpty) continue;
        final first = f.throws.first;
        if (first.pinsKnocked >= 10) continue;
        final key = (first.pinsLeft.toList()..sort()).join('-');
        if (key.isEmpty) continue;
        map[key] = (map[key] ?? 0) + 1;
      }
    }
    return map;
  }

  static String roundsToJson(List<RoundData> rounds) =>
      jsonEncode(rounds.map((r) => r.toJson()).toList());

  static List<RoundData> roundsFromJson(String jsonStr) {
    final list = jsonDecode(jsonStr) as List<dynamic>;
    return list.map((e) => RoundData.fromJson(Map<String, dynamic>.from(e))).toList();
  }
}

/// 残りピン番号から代表的なスプリット／リーヴ名称（表示用）
class LeavePatternNames {
  LeavePatternNames._();

  static const Map<String, String> _known = {
    '7': '7番ピン',
    '10': '10番ピン',
    '4': '4番ピン',
    '6': '6番ピン',
    '7-10': '7-10スプリット（大スプリット）',
    '4-6': '4-6スプリット',
    '4-7': '4-7スプリット',
    '6-7': '6-7スプリット',
    '6-10': '6-10スプリット',
    '7-9': '7-9スプリット',
    '8-10': '8-10スプリット',
    '2-7': '2-7スプリット',
    '3-10': '3-10スプリット',
    '2-10': '2-10スプリット',
    '5-7': '5-7スプリット',
    '5-10': '5-10スプリット',
    '1-2-4': 'バケツ（軽め）',
    '1-2-10': 'バケツ（重め）',
    '1-3-6': '1-3-6',
    '2-4-5': '2-4-5',
    '4-5': '4-5',
    '7-8': '7-8',
    '9-10': '9-10',
    '1-2-3': '1-2-3',
    '1-2-3-5': 'ギリシャ教会',
  };

  static String describe(String sortedDashKey) {
    return _known[sortedDashKey] ?? 'リーヴ $sortedDashKey';
  }
}
