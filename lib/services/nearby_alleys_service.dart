import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../models/bowling_meta.dart';

/// OpenStreetMap Overpass API で近くのボウリング場を検索（APIキー不要）
class NearbyAlleysService {
  NearbyAlleysService._();
  static final instance = NearbyAlleysService._();

  static const _overpassUrl = 'https://overpass-api.de/api/interpreter';
  final _distance = const Distance();

  Future<List<NearbyBowlingPlace>> searchNearby({
    required LatLng center,
    int radiusMeters = 8000,
  }) async {
    final query = '''
[out:json][timeout:25];
(
  node["leisure"="bowling_alley"](around:$radiusMeters,${center.latitude},${center.longitude});
  way["leisure"="bowling_alley"](around:$radiusMeters,${center.latitude},${center.longitude});
);
out center tags;
''';

    final res = await http.post(
      Uri.parse(_overpassUrl),
      body: {'data': query},
    ).timeout(const Duration(seconds: 30));

    if (res.statusCode != 200) {
      throw Exception('地図データの取得に失敗しました (${res.statusCode})');
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final elements = data['elements'] as List<dynamic>? ?? [];
    final places = <NearbyBowlingPlace>[];
    final seen = <String>{};

    for (final raw in elements) {
      final e = Map<String, dynamic>.from(raw as Map);
      final tags = Map<String, dynamic>.from(e['tags'] as Map? ?? {});
      final name = (tags['name:ja'] ?? tags['name'] ?? tags['brand'] ?? 'ボウリング場').toString();
      if (name.isEmpty) continue;

      double? lat;
      double? lon;
      if (e['type'] == 'node') {
        lat = (e['lat'] as num?)?.toDouble();
        lon = (e['lon'] as num?)?.toDouble();
      } else {
        final c = e['center'] as Map?;
        lat = (c?['lat'] as num?)?.toDouble();
        lon = (c?['lon'] as num?)?.toDouble();
      }
      if (lat == null || lon == null) continue;

      final osmId = '${e['type']}/${e['id']}';
      if (seen.contains(osmId)) continue;
      seen.add(osmId);

      final addr = _formatAddress(tags);
      final dist = _distance(center, LatLng(lat, lon));

      places.add(NearbyBowlingPlace(
        osmId: osmId,
        name: name,
        latitude: lat,
        longitude: lon,
        address: addr,
        distanceMeters: dist,
      ));
    }

    places.sort((a, b) => (a.distanceMeters ?? 0).compareTo(b.distanceMeters ?? 0));
    return places;
  }

  String? _formatAddress(Map<String, dynamic> tags) {
    final parts = <String>[
      if (tags['addr:city'] != null) '${tags['addr:city']}',
      if (tags['addr:street'] != null) '${tags['addr:street']}',
      if (tags['addr:housenumber'] != null) '${tags['addr:housenumber']}',
    ];
    if (parts.isEmpty) return tags['addr:full'] as String?;
    return parts.join('');
  }
}
