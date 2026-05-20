import 'dart:io';

import 'package:flutter/material.dart';

import '../models/bowling.dart';

/// 縦型フレームカード＋大きなタイポグラフィで読みやすいスコア表
class BowlingScoreSheet extends StatelessWidget {
  const BowlingScoreSheet({
    super.key,
    required this.round,
    this.showImage = true,
  });

  final RoundData round;
  final bool showImage;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final running = BowlingScoring.runningTotals(round);
    final total = BowlingScoring.totalScore(round);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TotalHeader(total: total, round: round, scheme: scheme),
        if (showImage && round.scoreSheetImagePath != null) ...[
          const SizedBox(height: 12),
          _SubmittedImage(path: round.scoreSheetImagePath!),
        ],
        if (round.scanConfidence != null) ...[
          const SizedBox(height: 8),
          _ScanBadge(confidence: round.scanConfidence!, scheme: scheme),
        ],
        const SizedBox(height: 16),
        _CompactStrip(frames: round.frames, running: running, scheme: scheme),
        const SizedBox(height: 16),
        Text(
          'フレーム詳細',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...List.generate(10, (i) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _FrameDetailCard(
              frame: round.frames[i],
              cumulative: running[i],
              scheme: scheme,
            ),
          );
        }),
      ],
    );
  }
}

class _TotalHeader extends StatelessWidget {
  const _TotalHeader({required this.total, required this.round, required this.scheme});

  final int? total;
  final RoundData round;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [scheme.primary, scheme.primary.withValues(alpha: 0.75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  round.displayLabel.split('·').first.trim(),
                  style: TextStyle(color: scheme.onPrimary.withValues(alpha: 0.85), fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  total != null ? '$total' : '—',
                  style: TextStyle(
                    color: scheme.onPrimary,
                    fontSize: 48,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
                Text(
                  total != null ? 'TOTAL' : 'スコア未確定',
                  style: TextStyle(color: scheme.onPrimary.withValues(alpha: 0.8), fontSize: 12, letterSpacing: 1.2),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _miniStat('ストライク', '${round.frames.where((f) => f.isStrike).length}'),
              const SizedBox(height: 6),
              _miniStat('スペア', '${round.frames.where((f) => f.isSpare).length}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: TextStyle(color: scheme.onPrimary.withValues(alpha: 0.75), fontSize: 11)),
        const SizedBox(width: 6),
        Text(value, style: TextStyle(color: scheme.onPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }
}

class _ScanBadge extends StatelessWidget {
  const _ScanBadge({required this.confidence, required this.scheme});

  final double confidence;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final pct = (confidence * 100).round();
    final color = confidence >= 0.7 ? Colors.green : confidence >= 0.45 ? Colors.orange : scheme.error;
    return Row(
      children: [
        Icon(Icons.document_scanner_outlined, size: 18, color: color),
        const SizedBox(width: 6),
        Text('読み取り信頼度 $pct%', style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13)),
      ],
    );
  }
}

class _SubmittedImage extends StatelessWidget {
  const _SubmittedImage({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    final file = File(path);
    if (!file.existsSync()) return const SizedBox.shrink();
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Image.file(file, fit: BoxFit.cover),
      ),
    );
  }
}

/// 横スクロールのミニストリップ（一覧性）
class _CompactStrip extends StatelessWidget {
  const _CompactStrip({required this.frames, required this.running, required this.scheme});

  final List<FrameData> frames;
  final List<int?> running;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < 10; i++)
            _StripCell(
              frame: frames[i],
              cumulative: running[i],
              isTenth: i == 9,
              scheme: scheme,
            ),
        ],
      ),
    );
  }
}

class _StripCell extends StatelessWidget {
  const _StripCell({
    required this.frame,
    required this.cumulative,
    required this.isTenth,
    required this.scheme,
  });

  final FrameData frame;
  final int? cumulative;
  final bool isTenth;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final marks = _marksForFrame(frame);
    final accent = frame.isStrike
        ? Colors.deepOrange
        : frame.isSpare
            ? Colors.teal
            : scheme.surfaceContainerHighest;

    return Container(
      width: isTenth ? 76 : 58,
      margin: const EdgeInsets.only(right: 6),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: frame.isStrike || frame.isSpare ? accent : scheme.outlineVariant, width: 1.5),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 3),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: frame.isStrike || frame.isSpare ? 0.25 : 0.5),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Text(
              '${frame.frameNumber}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Text(
              marks,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 0.5),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 5),
            decoration: BoxDecoration(
              color: scheme.primaryContainer.withValues(alpha: 0.4),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
            ),
            child: Text(
              cumulative?.toString() ?? '·',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: scheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  String _marksForFrame(FrameData f) {
    if (f.throws.isEmpty) return '—';
    final parts = <String>[];
    for (var i = 0; i < f.throws.length; i++) {
      parts.add(_mark(f, i));
    }
    return parts.join(' ');
  }

  String _mark(FrameData f, int i) {
    if (i >= f.throws.length) return '';
    final pins = f.throws[i].pinsKnocked;
    if (f.frameNumber < 10) {
      if (i == 0 && pins == 10) return 'X';
      if (i == 1) {
        final first = f.throws[0].pinsKnocked;
        if (first + pins == 10 && first < 10) return '/';
        return pins == 0 ? '−' : '$pins';
      }
      return pins == 0 ? '−' : '$pins';
    }
    if (pins == 10) return 'X';
    if (i >= 1) {
      final prev = f.throws[i - 1].pinsKnocked;
      if (prev < 10 && prev + pins == 10) return '/';
    }
    return pins == 0 ? '−' : '$pins';
  }
}

class _FrameDetailCard extends StatelessWidget {
  const _FrameDetailCard({
    required this.frame,
    required this.cumulative,
    required this.scheme,
  });

  final FrameData frame;
  final int? cumulative;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final throws = frame.throws;
    final typeLabel = frame.isStrike
        ? 'ストライク'
        : frame.isSpare
            ? 'スペア'
            : throws.any((t) => t.isGutter)
                ? 'ガターあり'
                : throws.isEmpty
                    ? '未投球'
                    : 'オープン';

    final typeColor = frame.isStrike
        ? Colors.deepOrange
        : frame.isSpare
            ? Colors.teal
            : throws.any((t) => t.isGutter)
                ? scheme.error
                : scheme.outline;

    return Material(
      color: scheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: typeColor.withValues(alpha: 0.15),
              child: Text(
                '${frame.frameNumber}',
                style: TextStyle(fontWeight: FontWeight.bold, color: typeColor),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(typeLabel, style: TextStyle(fontSize: 12, color: typeColor, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (var i = 0; i < throws.length; i++)
                        _ThrowChip(index: i + 1, throwData: throws[i], frame: frame),
                      if (throws.isEmpty)
                        Text('—', style: TextStyle(fontSize: 20, color: scheme.onSurfaceVariant)),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  cumulative?.toString() ?? '—',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: scheme.primary),
                ),
                Text('累計', style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ThrowChip extends StatelessWidget {
  const _ThrowChip({required this.index, required this.throwData, required this.frame});

  final int index;
  final ThrowData throwData;
  final FrameData frame;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final mark = _formatMark();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Text(
        '${index}投 $mark',
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
      ),
    );
  }

  String _formatMark() {
    final pins = throwData.pinsKnocked;
    final idx = frame.throws.indexOf(throwData);
    if (frame.frameNumber < 10) {
      if (idx == 0 && pins == 10) return 'X';
      if (idx == 1) {
        final first = frame.throws[0].pinsKnocked;
        if (first + pins == 10 && first < 10) return '/';
      }
    } else {
      if (pins == 10) return 'X';
      if (idx >= 1) {
        final prev = frame.throws[idx - 1].pinsKnocked;
        if (prev < 10 && prev + pins == 10) return '/';
      }
    }
    return pins == 0 ? '−' : '$pins';
  }
}
