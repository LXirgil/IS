import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// Nominatim（OpenStreetMap）で住所→座標を取得
class GeocodingService {
  GeocodingService._();
  static final instance = GeocodingService._();

  static const _url = 'https://nominatim.openstreetmap.org/search';

  Future<LatLng?> geocode(String query) async {
    if (query.trim().isEmpty) return null;
    final uri = Uri.parse(_url).replace(queryParameters: {
      'q': query,
      'format': 'json',
      'limit': '1',
    });

    final res = await http.get(
      uri,
      headers: {'User-Agent': 'AIBowlingMaster/1.0'},
    ).timeout(const Duration(seconds: 15));

    if (res.statusCode != 200) return null;
    final list = jsonDecode(res.body) as List<dynamic>;
    if (list.isEmpty) return null;
    final first = list.first as Map<String, dynamic>;
    final lat = double.tryParse(first['lat'] as String? ?? '');
    final lon = double.tryParse(first['lon'] as String? ?? '');
    if (lat == null || lon == null) return null;
    return LatLng(lat, lon);
  }
}
