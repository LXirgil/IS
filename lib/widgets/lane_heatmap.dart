import 'package:flutter/material.dart';

/// 簡易レーン別ヒートマップウィジェット
/// data: { laneNumber: { pinNumber: count } }
class LaneHeatmap extends StatelessWidget {
  final Map<int, Map<int, int>> data;
  final int maxCount;
  final double cellSize;

  LaneHeatmap({Key? key, required this.data, int? maxCount, this.cellSize = 28.0})
      : maxCount = maxCount ?? _computeMax(data),
        super(key: key);

  static int _computeMax(Map<int, Map<int, int>> data) {
    var m = 0;
    for (final lane in data.values) {
      for (final v in lane.values) {
        if (v > m) m = v;
      }
    }
    return m == 0 ? 1 : m;
  }

  Color _colorForCount(int count) {
    final ratio = (count / maxCount).clamp(0.0, 1.0);
    // gradient from lightGray -> yellow -> red
    if (ratio <= 0.0) return Colors.grey.shade200;
    if (ratio < 0.5) {
      final t = (ratio / 0.5);
      return Color.lerp(Colors.yellow.shade200, Colors.orange.shade400, t)!;
    }
    final t = ((ratio - 0.5) / 0.5);
    return Color.lerp(Colors.orange.shade400, Colors.red.shade700, t)!;
  }

  @override
  Widget build(BuildContext context) {
    final lanes = data.keys.toList()..sort();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // header: pin numbers
              Row(
                children: [
                  SizedBox(width: 48, child: Text('Lane')),
                  for (var pin = 1; pin <= 10; pin++)
                    Container(
                      width: cellSize,
                      height: 24,
                      alignment: Alignment.center,
                      child: Text('$pin', style: TextStyle(fontSize: 12)),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              // rows per lane
              for (final lane in lanes)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                        width: 48,
                        child: Text('L$lane', style: TextStyle(fontWeight: FontWeight.w600))),
                    for (var pin = 1; pin <= 10; pin++)
                      Container(
                        width: cellSize,
                        height: cellSize,
                        margin: EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: _colorForCount(data[lane]?[pin] ?? 0),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.grey.shade300, width: 0.5),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${data[lane]?[pin] ?? 0}',
                          style: TextStyle(fontSize: 11),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // legend
        Row(
          children: [
            _legendBox(0, '0'),
            _legendBox((maxCount * 0.25).round(), 'low'),
            _legendBox((maxCount * 0.5).round(), 'mid'),
            _legendBox((maxCount * 0.9).round(), 'high'),
          ],
        ),
      ],
    );
  }

  Widget _legendBox(int count, String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Row(
        children: [
          Container(width: 20, height: 14, color: _colorForCount(count)),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
