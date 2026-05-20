/// ボール・ボウリング場・リーグなどアプリ拡張モデル
class BowlingBall {
  BowlingBall({
    required this.id,
    required this.name,
    this.brand,
    this.weight,
    this.colorValue = 0xFF5C6BC0,
    DateTime? lastMaintenance,
    this.note,
  }) : lastMaintenance = lastMaintenance;

  final String id;
  String name;
  String? brand;
  int? weight;
  int colorValue;
  DateTime? lastMaintenance;
  String? note;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'brand': brand,
        'weight': weight,
        'colorValue': colorValue,
        'lastMaintenance': lastMaintenance?.toIso8601String(),
        'note': note,
      };

  factory BowlingBall.fromJson(Map<String, dynamic> j) => BowlingBall(
        id: j['id'] as String,
        name: j['name'] as String,
        brand: j['brand'] as String?,
        weight: j['weight'] as int?,
        colorValue: j['colorValue'] as int? ?? 0xFF5C6BC0,
        lastMaintenance: j['lastMaintenance'] != null ? DateTime.parse(j['lastMaintenance'] as String) : null,
        note: j['note'] as String?,
      );
}

class BowlingAlley {
  BowlingAlley({
    required this.id,
    required this.name,
    this.address,
    this.note,
    this.isFavorite = false,
    this.latitude,
    this.longitude,
  });

  final String id;
  String name;
  String? address;
  String? note;
  bool isFavorite;
  double? latitude;
  double? longitude;

  bool get hasLocation => latitude != null && longitude != null;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'address': address,
        'note': note,
        'isFavorite': isFavorite,
        'latitude': latitude,
        'longitude': longitude,
      };

  factory BowlingAlley.fromJson(Map<String, dynamic> j) => BowlingAlley(
        id: j['id'] as String,
        name: j['name'] as String,
        address: j['address'] as String?,
        note: j['note'] as String?,
        isFavorite: j['isFavorite'] as bool? ?? false,
        latitude: (j['latitude'] as num?)?.toDouble(),
        longitude: (j['longitude'] as num?)?.toDouble(),
      );
}

/// OpenStreetMap から取得した近くのボウリング場
class NearbyBowlingPlace {
  NearbyBowlingPlace({
    required this.osmId,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.address,
    this.distanceMeters,
  });

  final String osmId;
  final String name;
  final double latitude;
  final double longitude;
  final String? address;
  final double? distanceMeters;

  String get distanceLabel {
    if (distanceMeters == null) return '';
    if (distanceMeters! < 1000) return '${distanceMeters!.round()}m';
    return '${(distanceMeters! / 1000).toStringAsFixed(1)}km';
  }
}

class BowlingLeague {
  BowlingLeague({
    required this.id,
    required this.name,
    List<String>? roundIds,
    DateTime? createdAt,
    this.description,
  })  : roundIds = roundIds ?? [],
        createdAt = createdAt ?? DateTime.now();

  final String id;
  String name;
  String? description;
  final List<String> roundIds;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'roundIds': roundIds,
        'createdAt': createdAt.toIso8601String(),
      };

  factory BowlingLeague.fromJson(Map<String, dynamic> j) => BowlingLeague(
        id: j['id'] as String,
        name: j['name'] as String,
        description: j['description'] as String?,
        roundIds: List<String>.from(j['roundIds'] ?? []),
        createdAt: DateTime.parse(j['createdAt'] as String),
      );
}

/// ゲーム検索・分析フィルター
class GameSearchFilter {
  GameSearchFilter({
    this.period = StatsPeriod.all,
    this.ballId,
    this.alleyId,
    this.minScore,
    this.maxScore,
    this.onlyStrikesHeavy = false,
  });

  StatsPeriod period;
  String? ballId;
  String? alleyId;
  int? minScore;
  int? maxScore;
  bool onlyStrikesHeavy;

  GameSearchFilter copy() => GameSearchFilter(
        period: period,
        ballId: ballId,
        alleyId: alleyId,
        minScore: minScore,
        maxScore: maxScore,
        onlyStrikesHeavy: onlyStrikesHeavy,
      );

  bool get isActive =>
      period != StatsPeriod.all ||
      ballId != null ||
      alleyId != null ||
      minScore != null ||
      maxScore != null ||
      onlyStrikesHeavy;
}

enum StatsPeriod { all, last30Days, thisMonth, thisYear }

extension StatsPeriodLabel on StatsPeriod {
  String get label {
    switch (this) {
      case StatsPeriod.all:
        return '全期間';
      case StatsPeriod.last30Days:
        return '直近30日';
      case StatsPeriod.thisMonth:
        return '今月';
      case StatsPeriod.thisYear:
        return '今年';
    }
  }
}
