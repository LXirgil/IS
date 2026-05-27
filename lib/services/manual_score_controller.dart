/// 手入力用の投球シーケンス管理（10フレームルール準拠）
class ManualScoreController {
  final List<int> rolls = [];

  bool get isComplete => _rollsNeededForComplete() <= 0;

  int get currentFrame {
    var frame = 1;
    var roll = 0;
    var i = 0;
    while (i < rolls.length && frame <= 10) {
      if (frame < 10) {
        if (rolls[i] == 10) {
          frame++;
          i++;
        } else {
          if (roll == 0) {
            roll = 1;
            i++;
          } else {
            frame++;
            roll = 0;
            i++;
          }
        }
      } else {
        i++;
        if (i >= rolls.length) break;
        if (rolls.length >= 2) {
          final a = rolls[rolls.length - 2];
          final b = rolls[rolls.length - 1];
          if (frame == 10 && rolls.length >= 2) {
            if (a < 10 && a + b < 10 && rolls.length == 2) return 10;
            if (rolls.length >= 3) return 10;
          }
        }
      }
    }
    return frame.clamp(1, 10);
  }

  int _rollsNeededForComplete() {
    // max rolls: 21 (theoretical), but calculation below doesn't need these variables
    var frame = 1;
    var i = 0;
    while (frame <= 10 && i < rolls.length) {
      if (frame < 10) {
        if (rolls[i] == 10) {
          frame++;
          i++;
        } else {
          if (i + 1 >= rolls.length) return 2 - (i > 0 && rolls[i - 1] != 10 ? 1 : 0);
          frame++;
          i += 2;
        }
      } else {
        final start = i;
        if (i >= rolls.length) return 3;
        final a = rolls[i++];
        if (a == 10) {
          if (i >= rolls.length) return 3 - (i - start);
          final b = rolls[i++];
          if (b == 10) {
            if (i >= rolls.length) return 3 - (i - start);
            i++;
          }
        } else {
          if (i >= rolls.length) return 3 - (i - start);
          final b = rolls[i++];
          if (a + b == 10) {
            if (i >= rolls.length) return 3 - (i - start);
            i++;
          }
        }
        frame++;
      }
    }
    if (frame > 10) return 0;
    return 1;
  }

  int get maxPinsForNextRoll {
    if (isComplete) return 0;
    var i = 0;
    var frame = 1;
    while (frame <= 10) {
      if (frame < 10) {
        if (i >= rolls.length) return 10;
        if (rolls[i] == 10) {
          frame++;
          i++;
          continue;
        }
        if (i + 1 >= rolls.length) return 10 - rolls[i];
        frame++;
        i += 2;
      } else {
        if (i >= rolls.length) return 10;
        if (i == rolls.length - 1) {
          if (rolls.length == 1) return 10;
          final a = rolls[i - 1];
          if (rolls.length == 2) {
            if (a == 10) return 10;
            return 10 - a;
          }
        }
        return 10;
      }
    }
    return 0;
  }

  bool canAdd(int pins) => pins >= 0 && pins <= maxPinsForNextRoll;

  void add(int pins) {
    if (!canAdd(pins)) return;
    rolls.add(pins);
  }

  void undo() {
    if (rolls.isNotEmpty) rolls.removeLast();
  }
}
