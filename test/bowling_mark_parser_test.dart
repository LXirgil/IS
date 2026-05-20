import 'package:ai_bowling_master/models/bowling.dart';
import 'package:ai_bowling_master/services/bowling_mark_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses strikes and spares', () {
    final r = BowlingMarkParser.parse('X 7/ 9- 8/');
    expect(r.rolls, [10, 7, 3, 9, 0, 8, 2]);
    expect(r.marks, contains('X'));
  });

  test('applyPinRolls fills round', () {
    final round = RoundData(id: 't1');
    final parsed = BowlingMarkParser.parse('X X X X X X X X X X');
    applyPinRollsToRound(round, parsed.rolls);
    expect(round.frames.where((f) => f.isStrike).length, 10);
  });
}
