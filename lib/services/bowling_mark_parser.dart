/// スコア表のマーク（X, /, -, 数字）を投球ピン数列へ変換
class BowlingMarkParser {
  BowlingMarkParser._();

  static List<String> tokenize(String text) {
    final upper = text.toUpperCase().replaceAll(RegExp(r'[|｜]'), ' ');
    final tokens = <String>[];
    var i = 0;
    while (i < upper.length) {
      final c = upper[i];
      if (c == ' ' || c == '\n' || c == '\r' || c == '\t') {
        i++;
        continue;
      }
      if (c == 'X') {
        tokens.add('X');
        i++;
        continue;
      }
      if (c == '/') {
        tokens.add('/');
        i++;
        continue;
      }
      if (c == '-' || c == '—') {
        tokens.add('-');
        i++;
        continue;
      }
      if (RegExp(r'[0-9]').hasMatch(c)) {
        final start = i;
        while (i < upper.length && RegExp(r'[0-9]').hasMatch(upper[i])) {
          i++;
        }
        final numStr = upper.substring(start, i);
        final n = int.tryParse(numStr);
        if (n == 10) {
          tokens.add('X');
        } else if (n != null && n >= 0 && n <= 9) {
          tokens.add('$n');
        }
        continue;
      }
      i++;
    }
    return tokens;
  }

  static ParseResult parse(String text) {
    final tokens = tokenize(text);
    if (tokens.isEmpty) {
      return ParseResult(rolls: [], marks: [], confidence: 0, warnings: ['マークが検出できませんでした']);
    }

    final rolls = <int>[];
    final marks = <String>[];
    final warnings = <String>[];
    var ti = 0;

    for (var frame = 1; frame <= 10; frame++) {
      if (ti >= tokens.length) break;

      if (frame < 10) {
        final t1 = tokens[ti++];
        marks.add(t1);
        if (t1 == 'X') {
          rolls.add(10);
          continue;
        }
        final p1 = _pinValue(t1);
        if (p1 == null) {
          warnings.add('フレーム$frame: 解釈できないマーク「$t1」');
          continue;
        }
        rolls.add(p1);
        if (ti >= tokens.length) {
          warnings.add('フレーム$frame: 2投目がありません');
          break;
        }
        final t2 = tokens[ti++];
        marks.add(t2);
        if (t2 == '/') {
          rolls.add(10 - p1);
        } else {
          final p2 = _pinValue(t2);
          if (p2 == null) {
            warnings.add('フレーム$frame: 2投目「$t2」を解釈できません');
          } else if (p1 + p2 > 10) {
            warnings.add('フレーム$frame: 合計が10を超えています（$p1+$p2）');
            rolls.add((10 - p1).clamp(0, 10));
          } else {
            rolls.add(p2);
          }
        }
      } else {
        // 10フレーム目: 最大3投
        for (var ball = 0; ball < 3 && ti < tokens.length; ball++) {
          final t = tokens[ti++];
          marks.add(t);
          if (t == 'X') {
            rolls.add(10);
            if (ball == 0) continue;
            if (ball == 1 && rolls.length >= 2 && rolls[rolls.length - 2] == 10) continue;
            if (ball == 1) break;
            continue;
          }
          if (t == '/' && ball > 0) {
            final prev = rolls.last;
            rolls.add(10 - prev);
            break;
          }
          final p = _pinValue(t);
          if (p == null) {
            warnings.add('10フレーム目: 「$t」を解釈できません');
            break;
          }
          if (ball == 1 && rolls.isNotEmpty) {
            final first = rolls[rolls.length - 1];
            if (first < 10 && first + p > 10) {
              warnings.add('10フレーム目: 2投目が不正（$first+$p）');
              rolls.add((10 - first).clamp(0, 10));
              break;
            }
          }
          rolls.add(p);
          if (ball == 0 && p < 10) continue;
          if (ball == 0 && p == 10) continue;
          if (ball == 1 && rolls.length >= 2) {
            final a = rolls[rolls.length - 2];
            final b = rolls[rolls.length - 1];
            if (a + b < 10) break;
          }
        }
      }
    }

    var confidence = 0.35;
    if (rolls.isNotEmpty) confidence += 0.25;
    if (rolls.length >= 12) confidence += 0.2;
    if (warnings.isEmpty) confidence += 0.15;
    if (marks.length >= 10) confidence += 0.05;
    confidence = confidence.clamp(0.0, 1.0);

    return ParseResult(
      rolls: rolls,
      marks: marks,
      confidence: confidence,
      warnings: warnings,
    );
  }

  static int? _pinValue(String token) {
    if (token == '-') return 0;
    return int.tryParse(token);
  }
}

class ParseResult {
  ParseResult({
    required this.rolls,
    required this.marks,
    required this.confidence,
    required this.warnings,
  });

  final List<int> rolls;
  final List<String> marks;
  final double confidence;
  final List<String> warnings;

  String get marksPreview => marks.join(' ');
}
