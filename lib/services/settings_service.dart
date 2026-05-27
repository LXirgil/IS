import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  SettingsService._private();
  static final SettingsService instance = SettingsService._private();

  static const _trackingKey = 'map_tracking_enabled';
  final ValueNotifier<bool> trackingEnabled = ValueNotifier<bool>(true);

  String? _pinPath;
  String? _myLocPath;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    trackingEnabled.value = prefs.getBool(_trackingKey) ?? true;
    await _ensureSampleImages();
  }

  Future<void> setTrackingEnabled(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_trackingKey, v);
    trackingEnabled.value = v;
  }

  Future<void> _ensureSampleImages() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${dir.path}/ai_bowling_images');
      if (!await imagesDir.exists()) await imagesDir.create(recursive: true);
      final pinFile = File('${imagesDir.path}/pin.png');
      final myFile = File('${imagesDir.path}/my_location.png');

      // tiny transparent 1x1 PNG base64
      const tinyPngBase64 = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR4nGNgYAAAAAMAASsJTYQAAAAASUVORK5CYII=';
      final bytes = base64Decode(tinyPngBase64);

      if (!await pinFile.exists()) await pinFile.writeAsBytes(bytes);
      if (!await myFile.exists()) await myFile.writeAsBytes(bytes);

      _pinPath = pinFile.path;
      _myLocPath = myFile.path;
    } catch (_) {
      // ignore
    }
  }

  String? get pinImagePath => _pinPath;
  String? get myLocationImagePath => _myLocPath;
}
