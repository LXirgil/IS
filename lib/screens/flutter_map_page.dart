// ignore_for_file: use_build_context_synchronously

import 'dart:convert';

import 'package:flutter/material.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'dart:io';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/bowling_repository.dart';
import '../services/settings_service.dart';

class FlutterMapPage extends StatefulWidget {
  const FlutterMapPage({super.key});

  @override
  State<FlutterMapPage> createState() => _FlutterMapPageState();
}

class _FlutterMapPageState extends State<FlutterMapPage> {
  final MapController _mapController = MapController();
  LatLng _center = LatLng(35.681236, 139.767125); // 東京駅
  double _zoom = 13.0;
  List<Map<String, dynamic>> _savedMarkers = [];
  LatLng? _currentLocation;
  StreamSubscription<Position>? _positionStreamSub;

  static const _prefsKey = 'map_markers';

  @override
  void initState() {
    super.initState();
    _loadSavedMarkers();
    // initialize settings service and start/stop tracking based on user preference
    SettingsService.instance.init().then((_) {
      final enabled = SettingsService.instance.trackingEnabled.value;
      if (enabled) {
        _determinePosition();
        _startPositionStream();
      }
      // listen for changes and start/stop accordingly
      SettingsService.instance.trackingEnabled.addListener(() {
        final e = SettingsService.instance.trackingEnabled.value;
        if (e) {
          _determinePosition();
          _startPositionStream();
        } else {
          _positionStreamSub?.cancel();
          _positionStreamSub = null;
        }
      });
    });
  }

  Future<void> _determinePosition() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever || permission == LocationPermission.denied) {
        return;
      }
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best);
      if (!mounted) return;
      setState(() {
        _currentLocation = LatLng(pos.latitude, pos.longitude);
        _center = _currentLocation!;
        _mapController.move(_center, _zoom);
      });
    } catch (_) {
      // ignore location failures silently
    }
  }

  void _startPositionStream() {
    try {
      final settings = const LocationSettings(accuracy: LocationAccuracy.best, distanceFilter: 10);
      _positionStreamSub = Geolocator.getPositionStream(locationSettings: settings).listen((pos) {
        if (!mounted) return;
        setState(() {
          _currentLocation = LatLng(pos.latitude, pos.longitude);
        });
      });
    } catch (_) {
      // ignore
    }
  }

  Future<void> _loadSavedMarkers() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw != null) {
      try {
        final list = jsonDecode(raw) as List<dynamic>;
        _savedMarkers = list.map((e) => {
              'lat': (e['lat'] as num).toDouble(),
              'lng': (e['lng'] as num).toDouble(),
              'name': (e['name'] ?? '').toString(),
            }).toList();
      } catch (_) {
        _savedMarkers = [];
      }
    }
    setState(() {});
  }

  Future<void> _saveMarkers() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(_savedMarkers));
  }

  void _openControls() {
    final latController = TextEditingController(text: _center.latitude.toString());
    final lngController = TextEditingController(text: _center.longitude.toString());
    final zoomController = TextEditingController(text: _zoom.toString());

    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(children: [Expanded(child: TextField(controller: latController, decoration: const InputDecoration(labelText: '緯度'))), SizedBox(width: 12), Expanded(child: TextField(controller: lngController, decoration: const InputDecoration(labelText: '経度')))]),
            const SizedBox(height: 8),
            TextField(controller: zoomController, decoration: const InputDecoration(labelText: 'ズーム（例: 13.0）')),
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton(
                  child: const Text('中心移動'),
                  onPressed: () {
                    final lat = double.tryParse(latController.text);
                    final lng = double.tryParse(lngController.text);
                    final z = double.tryParse(zoomController.text);
                    if (lat == null || lng == null || z == null) return;
                    setState(() {
                      _center = LatLng(lat, lng);
                      _zoom = z;
                      _mapController.move(_center, _zoom);
                    });
                    Navigator.of(ctx).pop();
                  },
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  child: const Text('マーカー追加'),
                  onPressed: () async {
                    final lat = double.tryParse(latController.text);
                    final lng = double.tryParse(lngController.text);
                    if (lat == null || lng == null) return;
                    final name = await _askMarkerName();
                    if (!mounted) return;
                    setState(() {
                      _savedMarkers.add({'lat': lat, 'lng': lng, 'name': name ?? ''});
                    });
                    await _saveMarkers();
                    Navigator.of(ctx).pop();
                  },
                ),
                const SizedBox(width: 12),
                TextButton(
                  child: const Text('閉じる'),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _mapController.dispose();
    _positionStreamSub?.cancel();
    super.dispose();
  }

  Future<String?> _askMarkerName() async {
    final ctrl = TextEditingController();
    return showDialog<String?>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('マーカー名'),
        content: TextField(controller: ctrl, decoration: const InputDecoration(hintText: '名前（例: 自宅）')),
        actions: [
          TextButton(onPressed: () => Navigator.of(c).pop(null), child: const Text('キャンセル')),
          ElevatedButton(onPressed: () => Navigator.of(c).pop(ctrl.text.trim()), child: const Text('追加')),
        ],
      ),
    );
  }

  void _onMarkerTap(int index) {
    final data = _savedMarkers[index];
    showModalBottomSheet<void>(
      context: context,
      builder: (c) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(data['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('緯度: ${data['lat']}  経度: ${data['lng']}'),
            const SizedBox(height: 12),
            Row(children: [
              ElevatedButton(
                child: const Text('中心へ移動'),
                onPressed: () {
                  final lat = (data['lat'] as num).toDouble();
                  final lng = (data['lng'] as num).toDouble();
                  setState(() {
                    _center = LatLng(lat, lng);
                    _mapController.move(_center, _zoom);
                  });
                  Navigator.of(c).pop();
                },
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('削除'),
                onPressed: () async {
                  setState(() {
                    _savedMarkers.removeAt(index);
                  });
                  final nav = Navigator.of(c);
                  await _saveMarkers();
                  nav.pop();
                },
              ),
              const SizedBox(width: 12),
              TextButton(onPressed: () => Navigator.of(c).pop(), child: const Text('閉じる')),
            ])
          ],
        ),
      ),
    );
  }

  void _onAlleyTap(dynamic alley) {
    showModalBottomSheet<void>(
      context: context,
      builder: (c) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(alley.name ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (alley.address != null) Text(alley.address!),
            const SizedBox(height: 12),
            Row(children: [
              ElevatedButton(
                child: const Text('中心へ移動'),
                onPressed: () {
                  final lat = (alley.latitude as double);
                  final lng = (alley.longitude as double);
                  setState(() {
                    _center = LatLng(lat, lng);
                    _mapController.move(_center, _zoom);
                  });
                  Navigator.of(c).pop();
                },
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('削除'),
                onPressed: () async {
                  // remove from repo and refresh
                  BowlingRepository.instance.deleteAlley(alley.id);
                  await _loadSavedMarkers();
                  final nav = Navigator.of(c);
                  nav.pop();
                },
              ),
              const SizedBox(width: 12),
              TextButton(onPressed: () => Navigator.of(c).pop(), child: const Text('閉じる')),
            ])
          ],
        ),
      ),
    );
  }

  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('地図（OpenStreetMap）')),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: _center,
          initialZoom: _zoom,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
            subdomains: const ['a', 'b', 'c'],
            userAgentPackageName: 'com.example.ai_bowling_master',
          ),
          MarkerLayer(
            markers: [
              for (final e in _savedMarkers.asMap().entries)
                Marker(
                  point: LatLng((e.value['lat'] as num).toDouble(), (e.value['lng'] as num).toDouble()),
                  width: 48,
                  height: 48,
                  child: GestureDetector(
                    onTap: () => _onMarkerTap(e.key),
                    child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                  ),
                ),
              for (final a in BowlingRepository.instance.alleys.where((a) => a.hasLocation))
                Marker(
                  point: LatLng(a.latitude!, a.longitude!),
                  width: 64,
                  height: 64,
                  child: GestureDetector(
                    onTap: () => _onAlleyTap(a),
                    child: Column(
                      children: [
                        SizedBox(
                          width: 40,
                          height: 40,
                          child: () {
                            final path = SettingsService.instance.pinImagePath;
                            if (path != null && File(path).existsSync()) {
                              return Image.file(File(path), fit: BoxFit.contain);
                            }
                            return Image.asset(
                              'assets/images/pin.png',
                              fit: BoxFit.contain,
                              errorBuilder: (c, e, s) => const Icon(Icons.location_pin, color: Colors.deepOrange, size: 36),
                            );
                          }(),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6)),
                          child: Text(a.name, style: const TextStyle(fontSize: 11)),
                        )
                      ],
                    ),
                  ),
                ),
              if (_currentLocation != null)
                Marker(
                  point: _currentLocation!,
                  width: 42,
                  height: 42,
                    child: SizedBox(
                    width: 36,
                    height: 36,
                    child: () {
                      final path = SettingsService.instance.myLocationImagePath;
                      if (path != null && File(path).existsSync()) {
                        return Image.file(File(path), fit: BoxFit.contain);
                      }
                      return Image.asset(
                        'assets/images/my_location.png',
                        fit: BoxFit.contain,
                        errorBuilder: (c, e, s) => const Icon(Icons.my_location, color: Colors.blue, size: 32),
                      );
                    }(),
                  ),
                ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: '地図操作',
        child: const Icon(Icons.settings),
        onPressed: _openControls,
      ),
    );
  }
}

