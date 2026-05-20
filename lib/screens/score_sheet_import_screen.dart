import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/bowling.dart';
import '../services/bowling_mark_parser.dart';
import '../services/score_sheet_scanner.dart';
import '../widgets/bowling_score_sheet.dart';

/// スコア表写真の提出 → OCR/手入力 → 解析 → 確定
class ScoreSheetImportScreen extends StatefulWidget {
  const ScoreSheetImportScreen({super.key, this.existingRound});

  final RoundData? existingRound;

  @override
  State<ScoreSheetImportScreen> createState() => _ScoreSheetImportScreenState();
}

class _ScoreSheetImportScreenState extends State<ScoreSheetImportScreen> {
  late RoundData _round;
  String? _imagePath;
  final _marksController = TextEditingController();
  ScoreSheetScanResult? _result;
  bool _analyzing = false;

  @override
  void initState() {
    super.initState();
    _round = widget.existingRound ??
        RoundData(id: 'round-${DateTime.now().millisecondsSinceEpoch}');
    if (_round.ocrRawText != null) {
      _marksController.text = _round.ocrRawText!;
    }
    _imagePath = _round.scoreSheetImagePath;
  }

  @override
  void dispose() {
    _marksController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    String? path;
    if (source == ImageSource.gallery) {
      final picked = await FilePicker.platform.pickFiles(type: FileType.image);
      if (picked != null && picked.files.single.path != null) {
        path = picked.files.single.path;
      }
    } else {
      final picker = ImagePicker();
      final x = await picker.pickImage(source: source, imageQuality: 85);
      path = x?.path;
    }
    if (path == null || !mounted) return;
    setState(() {
      _imagePath = path;
      _result = null;
    });
  }

  Future<void> _analyze() async {
    if (_imagePath == null && _marksController.text.trim().isEmpty) {
      _snack('写真を選ぶか、マークを入力してください');
      return;
    }

    setState(() => _analyzing = true);
    try {
      String? savedPath;
      if (_imagePath != null) {
        savedPath = await ScoreSheetScanner.instance.persistImage(_imagePath!, _round.id);
      }

      ScoreSheetScanResult scan;
      if (_imagePath != null && _marksController.text.trim().isEmpty) {
        scan = await ScoreSheetScanner.instance.scanFromImage(
          imagePath: _imagePath!,
          round: _round,
        );
        if (scan.rawText.trim().isNotEmpty) {
          _marksController.text = scan.rawText;
        } else {
          final hint = BowlingMarkParser.tokenize(scan.rawText).join(' ');
          if (hint.isNotEmpty) _marksController.text = hint;
        }
      } else {
        scan = await ScoreSheetScanner.instance.scanFromMarks(
          marksText: _marksController.text.trim(),
          round: _round,
          imagePath: savedPath ?? _round.scoreSheetImagePath,
        );
      }

      if (savedPath != null) {
        _round.scoreSheetImagePath = savedPath;
        _imagePath = savedPath;
      }

      if (!mounted) return;
      setState(() => _result = scan);
    } catch (e) {
      if (mounted) _snack('解析エラー: $e');
    } finally {
      if (mounted) setState(() => _analyzing = false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _confirm() {
    if (_round.frames.every((f) => f.throws.isEmpty)) {
      _snack('スコアが読み取れていません。マークを修正して再解析してください');
      return;
    }
    _round.source = 'scan';
    Navigator.of(context).pop(_round);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('スコア表を登録'),
        actions: [
          TextButton(
            onPressed: _round.hasScoreData ? _confirm : null,
            child: const Text('確定'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            '1. スコア表の写真を提出',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            '紙のスコア表・レーン端末の画面を撮影してください。文字がはっきり写るほど精度が上がります。',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: const Text('撮影'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('アルバム'),
                ),
              ),
            ],
          ),
          if (_imagePath != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: Image.file(File(_imagePath!), fit: BoxFit.contain),
              ),
            ),
          ],
          const SizedBox(height: 24),
          Text(
            '2. マークの確認・修正',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'OCR結果を編集できます。スペース区切りで X / 7 9- などを入力。',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _marksController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: '例: X 7/ 9- 8/ X X 7/ 8/ X X X 8/',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () => _marksController.clear(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _analyzing ? null : _analyze,
            icon: _analyzing
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.analytics_outlined),
            label: Text(_analyzing ? '解析中…' : '写真を解析'),
          ),
          if (_result != null) ...[
            const SizedBox(height: 16),
            _AnalysisResultCard(result: _result!),
          ],
          if (_round.hasScoreData) ...[
            const SizedBox(height: 24),
            Text(
              '3. プレビュー',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            BowlingScoreSheet(round: _round, showImage: false),
          ],
          const SizedBox(height: 80),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: _round.hasScoreData ? _confirm : null,
            child: const Text('このスコア表を保存'),
          ),
        ),
      ),
    );
  }
}

class _AnalysisResultCard extends StatelessWidget {
  const _AnalysisResultCard({required this.result});

  final ScoreSheetScanResult result;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final pct = (result.confidence * 100).round();

    return Card(
      color: scheme.secondaryContainer.withValues(alpha: 0.35),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle_outline, color: scheme.primary),
                const SizedBox(width: 8),
                Text('解析結果（信頼度 $pct%）', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            if (result.detectedMarks.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('検出マーク: ${result.detectedMarks}', style: const TextStyle(fontFamily: 'monospace')),
            ],
            if (result.warnings.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...result.warnings.map(
                (w) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.warning_amber_rounded, size: 16, color: scheme.error),
                      const SizedBox(width: 6),
                      Expanded(child: Text(w, style: TextStyle(fontSize: 12, color: scheme.error))),
                    ],
                  ),
                ),
              ),
            ],
            if (result.usedOcr) ...[
              const SizedBox(height: 4),
              Text('端末内OCRで文字を読み取りました', style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
            ],
          ],
        ),
      ),
    );
  }
}
