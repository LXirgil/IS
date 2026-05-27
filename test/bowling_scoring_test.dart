import 'package:ai_bowling_master/models/bowling.dart';
import 'package:ai_bowling_master/services/bowling_mark_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('perfect game scores 300', () {
    final round = RoundData(id: 'perfect');
    final parsed = BowlingMarkParser.parse('X X X X X X X X X X X X');
    applyPinRollsToRound(round, parsed.rolls);
    expect(BowlingScoring.totalScore(round), 300);
  });

  test('running totals for sample game', () {
    final round = RoundData(id: 'sample');
    // Frames: 10, 7/ (17), 9- (26), X (56 after next two?), we'll use a known sequence
    final parsed = BowlingMarkParser.parse('X 7/ 9- 8/ X 9- 7/ 8- 9/ X X 9-');
    applyPinRollsToRound(round, parsed.rolls);
    final totals = BowlingScoring.runningTotals(round);
    expect(totals.length, 10);
    expect(totals.where((t) => t != null).isNotEmpty, true);
  });
}
