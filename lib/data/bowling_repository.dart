import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/bowling.dart';
import '../models/bowling_meta.dart';

/// ローカル永続化（自動バックアップ相当）
class BowlingRepository {
  BowlingRepository._();
  static final instance = BowlingRepository._();

  static const _storageKey = 'bowling_app_data_v1';

  List<RoundData> rounds = [];
  List<BowlingBall> balls = [];
  List<BowlingAlley> alleys = [];
  List<BowlingLeague> leagues = [];
  bool _loaded = false;

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw != null) {
      try {
        final j = jsonDecode(raw) as Map<String, dynamic>;
        rounds = (j['rounds'] as List<dynamic>?)
                ?.map((e) => RoundData.fromJson(Map<String, dynamic>.from(e)))
                .toList() ??
            [];
        balls = (j['balls'] as List<dynamic>?)
                ?.map((e) => BowlingBall.fromJson(Map<String, dynamic>.from(e)))
                .toList() ??
            [];
        alleys = (j['alleys'] as List<dynamic>?)
                ?.map((e) => BowlingAlley.fromJson(Map<String, dynamic>.from(e)))
                .toList() ??
            [];
        leagues = (j['leagues'] as List<dynamic>?)
                ?.map((e) => BowlingLeague.fromJson(Map<String, dynamic>.from(e)))
                .toList() ??
            [];
      } catch (_) {
        rounds = [];
        balls = [];
        alleys = [];
        leagues = [];
      }
    }
    // ignore: avoid_print
    print('BowlingRepository: loaded ${rounds.length} rounds, ${balls.length} balls, ${alleys.length} alleys, ${leagues.length} leagues');
    _loaded = true;
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    final payload = jsonEncode({
      'rounds': rounds.map((r) => r.toJson()).toList(),
      'balls': balls.map((b) => b.toJson()).toList(),
      'alleys': alleys.map((a) => a.toJson()).toList(),
      'leagues': leagues.map((l) => l.toJson()).toList(),
      'savedAt': DateTime.now().toIso8601String(),
    });
    try {
      final ok = await prefs.setString(_storageKey, payload);
      // ignore: avoid_print
      print('BowlingRepository: setString returned $ok');
      final verify = prefs.getString(_storageKey);
      if (verify == null) {
        // ignore: avoid_print
        print('BowlingRepository: verify read returned null');
      } else {
        // ignore: avoid_print
        print('BowlingRepository: saved payload ${verify.length} bytes, rounds=${rounds.length}');
      }
    } catch (e, st) {
      // ignore: avoid_print
      print('BowlingRepository: save failed: $e\n$st');
    }
  }

  String exportJson() => jsonEncode({
        'rounds': rounds.map((r) => r.toJson()).toList(),
        'balls': balls.map((b) => b.toJson()).toList(),
        'alleys': alleys.map((a) => a.toJson()).toList(),
        'leagues': leagues.map((l) => l.toJson()).toList(),
        'exportedAt': DateTime.now().toIso8601String(),
      });

  Future<void> importJson(String raw, {bool merge = false}) async {
    final j = jsonDecode(raw) as Map<String, dynamic>;
    final importedRounds = (j['rounds'] as List<dynamic>?)
            ?.map((e) => RoundData.fromJson(Map<String, dynamic>.from(e)))
            .toList() ??
        [];
    final importedBalls = (j['balls'] as List<dynamic>?)
            ?.map((e) => BowlingBall.fromJson(Map<String, dynamic>.from(e)))
            .toList() ??
        [];
    final importedAlleys = (j['alleys'] as List<dynamic>?)
            ?.map((e) => BowlingAlley.fromJson(Map<String, dynamic>.from(e)))
            .toList() ??
        [];
    final importedLeagues = (j['leagues'] as List<dynamic>?)
            ?.map((e) => BowlingLeague.fromJson(Map<String, dynamic>.from(e)))
            .toList() ??
        [];

    if (merge) {
      final roundIds = rounds.map((r) => r.id).toSet();
      for (final r in importedRounds) {
        if (!roundIds.contains(r.id)) rounds.add(r);
      }
      final ballIds = balls.map((b) => b.id).toSet();
      for (final b in importedBalls) {
        if (!ballIds.contains(b.id)) balls.add(b);
      }
      final alleyIds = alleys.map((a) => a.id).toSet();
      for (final a in importedAlleys) {
        if (!alleyIds.contains(a.id)) alleys.add(a);
      }
      final leagueIds = leagues.map((l) => l.id).toSet();
      for (final l in importedLeagues) {
        if (!leagueIds.contains(l.id)) leagues.add(l);
      }
    } else {
      rounds = importedRounds;
      balls = importedBalls;
      alleys = importedAlleys;
      leagues = importedLeagues;
    }
    await save();
  }

  Future<void> upsertRound(RoundData round) async {
    final i = rounds.indexWhere((r) => r.id == round.id);
    if (i >= 0) {
      rounds[i] = round;
    } else {
      rounds.insert(0, round);
    }
    await save();
  }

  void deleteRound(String id) {
    rounds.removeWhere((r) => r.id == id);
    for (final l in leagues) {
      l.roundIds.remove(id);
    }
    save();
  }

  void upsertBall(BowlingBall ball) {
    final i = balls.indexWhere((b) => b.id == ball.id);
    if (i >= 0) {
      balls[i] = ball;
    } else {
      balls.add(ball);
    }
    save();
  }

  void deleteBall(String id) {
    balls.removeWhere((b) => b.id == id);
    for (final r in rounds) {
      if (r.ballId == id) r.ballId = null;
    }
    save();
  }

  void upsertAlley(BowlingAlley alley) {
    final i = alleys.indexWhere((a) => a.id == alley.id);
    if (i >= 0) {
      alleys[i] = alley;
    } else {
      alleys.add(alley);
    }
    save();
  }

  void deleteAlley(String id) {
    alleys.removeWhere((a) => a.id == id);
    for (final r in rounds) {
      if (r.alleyId == id) r.alleyId = null;
    }
    save();
  }

  void upsertLeague(BowlingLeague league) {
    final i = leagues.indexWhere((l) => l.id == league.id);
    if (i >= 0) {
      leagues[i] = league;
    } else {
      leagues.add(league);
    }
    save();
  }

  void deleteLeague(String id) {
    leagues.removeWhere((l) => l.id == id);
    for (final r in rounds) {
      if (r.leagueId == id) r.leagueId = null;
    }
    save();
  }

  BowlingBall? ballById(String? id) {
    if (id == null) return null;
    try {
      return balls.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }

  BowlingAlley? alleyById(String? id) {
    if (id == null) return null;
    try {
      return alleys.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  List<RoundData> roundsForBall(String ballId) => rounds.where((r) => r.ballId == ballId && r.hasScoreData).toList();

  List<RoundData> roundsForLeague(BowlingLeague league) =>
      rounds.where((r) => league.roundIds.contains(r.id)).toList();
}
