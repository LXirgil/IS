import '../models/bowling.dart';
import '../models/bowling_meta.dart';

class GameFilterService {
  GameFilterService._();
  static final instance = GameFilterService._();

  List<RoundData> apply(List<RoundData> source, GameSearchFilter filter) {
    final now = DateTime.now();
    return source.where((r) {
      if (!r.hasScoreData) return false;

      switch (filter.period) {
        case StatsPeriod.all:
          break;
        case StatsPeriod.last30Days:
          if (r.date.isBefore(now.subtract(const Duration(days: 30)))) return false;
        case StatsPeriod.thisMonth:
          if (r.date.year != now.year || r.date.month != now.month) return false;
        case StatsPeriod.thisYear:
          if (r.date.year != now.year) return false;
      }

      if (filter.ballId != null && r.ballId != filter.ballId) return false;
      if (filter.alleyId != null && r.alleyId != filter.alleyId) return false;

      final score = BowlingScoring.totalScore(r);
      if (score != null) {
        if (filter.minScore != null && score < filter.minScore!) return false;
        if (filter.maxScore != null && score > filter.maxScore!) return false;
      }

      if (filter.onlyStrikesHeavy) {
        final rate = r.frames.where((f) => f.hasScore).isEmpty
            ? 0.0
            : r.frames.where((f) => f.isStrike).length / r.frames.where((f) => f.hasScore).length;
        if (rate < 0.3) return false;
      }

      return true;
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }
}
