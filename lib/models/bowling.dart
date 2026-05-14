import 'dart:convert';

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

  RoundData({required this.id, DateTime? date, List<FrameData>? frames})
      : date = date ?? DateTime.now(),
        frames = frames ?? List.generate(10, (i) => FrameData(frameNumber: i + 1));

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'frames': frames.map((f) => f.toJson()).toList(),
      };

  factory RoundData.fromJson(Map<String, dynamic> j) => RoundData(
        id: j['id'] as String,
        date: DateTime.parse(j['date'] as String),
        frames: (j['frames'] as List<dynamic>?)
                ?.map((e) => FrameData.fromJson(Map<String, dynamic>.from(e)))
                .toList() ??
            List.generate(10, (i) => FrameData(frameNumber: i + 1)),
      );
}

class BowlingStats {
  // 平均スコア（簡易計算: 各ラウンドの合計を平均化）
  static double averageScore(List<RoundData> rounds) {
    if (rounds.isEmpty) return 0.0;
    final totals = rounds.map((r) => roundTotal(r)).toList();
    return totals.reduce((a, b) => a + b) / totals.length;
  }

  static int roundTotal(RoundData r) {
    // 簡易版: フレーム毎のピン合計（ボーナス未計算）。詳細スコアロジックは後で拡張。
    return r.frames.fold(0, (acc, f) => acc + f.totalPinsKnocked);
  }

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

  static Map<String, int> _countStrikesAndFrames(List<RoundData> rounds) {
    int strikes = 0, spares = 0, frames = 0;
    for (final r in rounds) {
      for (final f in r.frames) {
        frames++;
        if (f.isStrike) strikes++;
        if (f.isSpare) spares++;
      }
    }
    return {'strikes': strikes, 'spares': spares, 'frames': frames};
  }

  // ピン別残り回数を集計（どのピンが残りやすいか）
  static Map<int, int> pinLeaveCounts(List<RoundData> rounds) {
    final counts = <int, int>{};
    for (var p = 1; p <= 10; p++) counts[p] = 0;
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

  // JSONヘルパー
  static String roundsToJson(List<RoundData> rounds) => jsonEncode(rounds.map((r) => r.toJson()).toList());
  static List<RoundData> roundsFromJson(String jsonStr) {
    final list = jsonDecode(jsonStr) as List<dynamic>;
    return list.map((e) => RoundData.fromJson(Map<String, dynamic>.from(e))).toList();
  }
}
