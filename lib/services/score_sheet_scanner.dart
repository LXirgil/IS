import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path_provider/path_provider.dart';

import '../models/bowling.dart';
import 'bowling_mark_parser.dart';

class ScoreSheetScanResult {
  ScoreSheetScanResult({
    required this.round,
    required this.rawText,
    required this.confidence,
    required this.warnings,
    required this.detectedMarks,
    required this.usedOcr,
  });

  final RoundData round;
  final String rawText;
  final double confidence;
  final List<String> warnings;
  final String detectedMarks;
  final bool usedOcr;
}

class ScoreSheetScanner {
  ScoreSheetScanner._();
  static final instance = ScoreSheetScanner._();

  TextRecognizer? _recognizer;

  Future<String> persistImage(String sourcePath, String roundId) async {
    final dir = await getApplicationDocumentsDirectory();
    final ext = sourcePath.contains('.') ? sourcePath.split('.').last : 'jpg';
    final dest = '${dir.path}/score_$roundId.$ext';
    await File(sourcePath).copy(dest);
    return dest;
  }

  /// 写真からOCR → マーク解析 → RoundData へ反映
  Future<ScoreSheetScanResult> scanFromImage({
    required String imagePath,
    required RoundData round,
  }) async {
    var rawText = '';
    var usedOcr = false;
    final ocrWarnings = <String>[];

    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      try {
        _recognizer ??= TextRecognizer(script: TextRecognitionScript.latin);
        final input = InputImage.fromFilePath(imagePath);
        final recognized = await _recognizer!.processImage(input);
        rawText = recognized.text;
        usedOcr = rawText.trim().isNotEmpty;
        if (!usedOcr) {
          ocrWarnings.add('画像から文字を読み取れませんでした。マークを手入力してください。');
        }
      } catch (e) {
        ocrWarnings.add('OCRを利用できません: $e');
      }
    } else {
      ocrWarnings.add('この端末では自動OCRに未対応です。読み取ったマークを手入力してください。');
    }

    return _buildResult(
      round: round,
      imagePath: imagePath,
      rawText: rawText,
      usedOcr: usedOcr,
      extraWarnings: ocrWarnings,
    );
  }

  /// 手入力マーク文字列から解析
  Future<ScoreSheetScanResult> scanFromMarks({
    required String marksText,
    required RoundData round,
    String? imagePath,
  }) {
    return Future.value(_buildResult(
      round: round,
      imagePath: imagePath,
      rawText: marksText,
      usedOcr: false,
      extraWarnings: const [],
    ));
  }

  ScoreSheetScanResult _buildResult({
    required RoundData round,
    String? imagePath,
    required String rawText,
    required bool usedOcr,
    required List<String> extraWarnings,
  }) {
    final parsed = BowlingMarkParser.parse(rawText);
    round.clearThrows();
    if (parsed.rolls.isNotEmpty) {
      applyPinRollsToRound(round, parsed.rolls);
    }

    round.ocrRawText = rawText;
    round.scoreSheetImagePath = imagePath;
    final confidence = usedOcr ? parsed.confidence : (parsed.rolls.isEmpty ? 0.0 : parsed.confidence * 0.85);
    round.scanConfidence = confidence;

    final warnings = [...extraWarnings, ...parsed.warnings];
    if (parsed.rolls.isEmpty && rawText.trim().isNotEmpty) {
      warnings.add('マーク列を認識できません。例: X 7/ 9- 8/ X X 7/ 8/ X X X 8/');
    }

    return ScoreSheetScanResult(
      round: round,
      rawText: rawText,
      confidence: confidence,
      warnings: warnings,
      detectedMarks: parsed.marksPreview,
      usedOcr: usedOcr,
    );
  }

  void dispose() {
    _recognizer?.close();
    _recognizer = null;
  }
}
