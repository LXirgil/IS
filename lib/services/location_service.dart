import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// 現在地取得（権限処理込み）
class LocationService {
  LocationService._();
  static final instance = LocationService._();

  /// 東京駅付近（位置情報が取れない場合のフォールバック）
  static const LatLng fallbackCenter = LatLng(35.6812, 139.7671);

  Future<bool> ensurePermission() async {
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    return perm == LocationPermission.always || perm == LocationPermission.whileInUse;
  }

  Future<LatLng?> getCurrentLatLng() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) return null;

    if (!await ensurePermission()) return null;

    try {
      final pos = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium));
      return LatLng(pos.latitude, pos.longitude);
    } catch (_) {
      return null;
    }
  }
}
